defmodule Flowscan.Data.StockQuote do
  @moduledoc false
  require Logger
  alias Flowscan.Integrations.IexcloudClient
  alias Flowscan.Repo
  alias Flowscan.Symbol
  alias Flowscan.SymbolOhlcv
  alias Flowscan.Utils.MarketHours

  def ohlcv_3mo(%Symbol{} = symbol) do
    previous_trading_day = MarketHours.previous_trading_day()
    three_months_ago = previous_trading_day |> Timex.shift(days: -90)
    records = SymbolOhlcv.for_date_range(symbol.id, three_months_ago, previous_trading_day)
    latest_record = List.last(records)

    diff_days =
      if latest_record,
        do: Timex.diff(previous_trading_day, latest_record.date, :days),
        else: 1000

    if diff_days > 0 do
      range =
        cond do
          diff_days < 5 -> "5d"
          diff_days < 30 -> "1m"
          true -> "3m"
        end

      fetch_ohlcv(symbol, range)
      SymbolOhlcv.for_date_range(symbol.id, three_months_ago, previous_trading_day)
    else
      records
    end
  end

  def fresh_quotes_for_tickers(tickers) do
    tickers = Enum.uniq(tickers)

    cached =
      tickers
      |> Enum.map(fn ticker -> {String.upcase(ticker), cached_fresh_quote(ticker)} end)
      |> Map.new()

    missing_tickers =
      cached
      |> Enum.filter(fn {_ticker, price} -> is_nil(price) end)
      |> Enum.map(fn {ticker, _price} -> ticker end)

    cached
    |> (fn cached ->
          if Enum.count(missing_tickers) > 0 do
            Map.merge(cached, missing_tickers |> refresh_quotes_for_tickers())
          else
            cached
          end
        end).()
  end

  def cached_fresh_quote(ticker) do
    ticker = String.upcase(ticker)
    Cachex.get!(:data, "fresh_quote:#{ticker}")
  end

  def set_cached_fresh_quote(ticker, quote) do
    ttl = Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:stock_data_fresh_ttl]
    ticker = String.upcase(ticker)
    Cachex.put!(:data, "fresh_quote:#{ticker}", quote, ttl: :timer.seconds(ttl))
  end

  defp refresh_quotes_for_tickers(tickers) do
    ticker_str = tickers |> Enum.join(",")
    Logger.info("Fetching quotes for #{ticker_str}")
    {:ok, results} = IexcloudClient.batch_quotes(tickers)

    # TODO: for now only concerned with the latest quote, but in the future
    # many of the fields could be useful and stored

    results
    |> Enum.map(fn {ticker, data} ->
      use_iex_price =
        !is_nil(data["quote"]["iexRealtimePrice"]) && data["quote"]["iexRealtimePrice"] > 0

      price =
        if use_iex_price,
          do: data["quote"]["iexRealtimePrice"],
          else: data["quote"]["latestPrice"]

      debug_str = if use_iex_price, do: "IEx real-time price", else: data["quote"]["latestSource"]
      Logger.info("#{ticker} = #{price} (#{debug_str})")
      set_cached_fresh_quote(ticker, price)
      {ticker, price}
    end)
    |> Map.new()
  end

  def fetch_ohlcv(%Symbol{} = symbol, range) do
    {:ok, price_data} = IexcloudClient.historical_prices(symbol.symbol, range)

    price_data
    |> Enum.each(fn d ->
      SymbolOhlcv.insert_changeset(
        symbol,
        Date.from_iso8601!(d["date"]),
        d["volume"],
        d["open"],
        d["close"],
        d["low"],
        d["high"]
      )
      |> Repo.insert(on_conflict: :nothing)
    end)
  end
end
