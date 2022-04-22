defmodule Flowscan.Data.OptionContract do
  @moduledoc false
  alias Flowscan.EodOptionContract
  alias Flowscan.Integrations.{IexcloudClient, SyncretismClient}
  alias Flowscan.OptionOhlcv
  alias Flowscan.Repo
  alias Flowscan.Symbol
  alias Flowscan.Utils.MarketHours

  def ohlcv_3mo(%Symbol{} = symbol, option_symbol) do
    previous_trading_day = MarketHours.previous_trading_day()
    three_months_ago = previous_trading_day |> Timex.shift(days: -90)

    records =
      OptionOhlcv.for_date_range(symbol.id, option_symbol, three_months_ago, previous_trading_day)

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

      # IEXCloud is broken
      # fetch_ohlcv(symbol, option_symbol, range)

      fetch_ohlcv_syncretism(symbol, option_symbol)

      OptionOhlcv.for_date_range(symbol.id, option_symbol, three_months_ago, previous_trading_day)
    else
      records
    end
  end

  def fetch_ohlcv(%Symbol{} = symbol, option_symbol, range) do
    iex_option_symbol = IexcloudClient.benzinga_option_symbol_to_iex(symbol.symbol, option_symbol)

    tasks = [
      Task.async(fn -> IexcloudClient.options_chart(iex_option_symbol, range) end),
      Task.async(fn -> SyncretismClient.historical(option_symbol) end)
    ]

    [iex_data, syncretism_data] = Task.await_many(tasks)
    {:ok, data} = iex_data

    # TODO: This is hopefully temporary
    # Populate records we've got from IEX with volume data from Syncretism
    alternative_volume_by_day =
      case syncretism_data do
        {:ok, syncretism_data} ->
          syncretism_data
          |> Enum.filter(fn data ->
            DateTime.from_unix!(data["timestamp"]).hour == 20
          end)
          |> Enum.reduce(%{}, fn data, acc ->
            date = DateTime.from_unix!(data["timestamp"]) |> DateTime.to_date()
            volume = if is_nil(data["volume"]), do: nil, else: round(data["volume"])
            Map.put(acc, date, volume)
          end)

        _ ->
          %{}
      end

    data
    |> Enum.each(fn d ->
      date =
        DateTime.from_unix!(d["date"], :millisecond)
        |> DateTime.truncate(:second)
        |> DateTime.to_date()

      OptionOhlcv.insert_changeset(
        symbol,
        option_symbol,
        date,
        %{
          volume: d["volume"],
          open: d["open"],
          close: d["close"],
          low: d["low"],
          high: d["high"],
          open_interest: d["openInterest"],
          iex_option_symbol: d["symbol"],
          alternative_volume: Map.get(alternative_volume_by_day, date)
        }
      )
      |> Repo.insert!(on_conflict: :nothing)
    end)
  end

  def fetch_ohlcv_syncretism(%Symbol{} = symbol, option_symbol) do
    {:ok, data} = SyncretismClient.historical(option_symbol)

    data
    |> Enum.filter(fn data ->
      DateTime.from_unix!(data["timestamp"]).hour == 20 ||
        DateTime.from_unix!(data["timestamp"]).hour == 21
    end)
    |> Enum.each(fn d ->
      date = DateTime.from_unix!(d["timestamp"]) |> DateTime.to_date()

      OptionOhlcv.insert_changeset(
        symbol,
        option_symbol,
        date,
        %{
          volume: if(is_nil(d["volume"]), do: 0, else: round(d["volume"])),
          open: nil,
          close: if(is_nil(d["premium"]), do: 0, else: d["premium"]),
          low: nil,
          high: nil,
          open_interest: if(is_nil(d["openInterest"]), do: 0, else: round(d["openInterest"])),
          iex_option_symbol: nil,
          alternative_volume: nil
        }
      )
      |> Repo.insert!(on_conflict: :nothing)
    end)
  end

  def eod_volume_for_contract(ticker, option_symbol, date) do
    data = EodOptionContract.find(option_symbol, date)

    if !data || !data.is_complete do
      fetch_and_update_eod_options(ticker, date)
    end
  end

  # TODO: This endpoint is now being deprecated
  # https://www.iexcloud.io/docs/api/#end-of-day-options-v2-alpha
  defp fetch_and_update_eod_options(ticker, expiration) do
    {:ok, data} = IexcloudClient.eod_options(ticker, expiration)
    data |> Enum.map(&EodOptionContract.update_with_complete_data/1)
  end
end
