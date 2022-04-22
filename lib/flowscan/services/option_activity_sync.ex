defmodule Flowscan.Services.OptionActivitySync do
  @moduledoc false

  require Logger
  alias Ecto.Changeset
  alias Flowscan.Integrations.BenzingaClient
  alias Flowscan.{OptionActivity, Repo, Symbol}
  alias Flowscan.Services.ActivityClassifier
  alias Flowscan.Services.Broadcasts
  alias Flowscan.Utils.MarketHours

  @page_size 1000
  @updated_padding 5

  def run(ignore_market_hours \\ false) do
    case MarketHours.in_or_near_market_hours?() do
      true ->
        run_updates()

      _ ->
        case ignore_market_hours do
          true -> run_updates()
          _ -> nil
        end
    end
  end

  defp run_updates do
    # TODO: Optimize. In-mem? Index?
    latest_updated = OptionActivity.latest_benzinga_updated()
    since = if latest_updated, do: latest_updated - @updated_padding, else: nil
    Logger.info("Updating option activity (since: #{since})")
    {:ok, activity_data} = fetch_option_activity(since)
    Logger.info("Retrieved #{Enum.count(activity_data)} entries")

    # TODO: Aggregate all tickers, check cache and reach out to IEx for missing price data

    activity_data |> Enum.reverse() |> Enum.map(&create_or_update/1)
  end

  defp create_or_update(data) do
    existing_record = OptionActivity.get_by_benzinga_signal_id(data["id"])
    # TODO: Handle updates

    unless existing_record do
      symbol = Symbol.find_by_symbol(data["ticker"])

      option_activity =
        %OptionActivity{}
        |> OptionActivity.changeset(%{
          ticker: data["ticker"],
          datetime: parse_datetime(data["date"], data["time"]),
          strike: data["strike_price"],
          expiration_date: data["date_expiration"],
          is_put: parse_is_put(data["put_call"]),
          is_sweep: parse_is_sweep(data["option_activity_type"]),
          is_etf: parse_is_etf(data["underlying_type"]),
          is_bullish: parse_is_bullish(data["sentiment"]),
          is_bearish: parse_is_bearish(data["sentiment"]),
          aggressor_ind: data["aggressor_ind"],
          cost_basis: String.to_float(data["cost_basis"]) |> round(),
          price: if(Map.has_key?(data, "price"), do: data["price"], else: nil),
          underlying_price: parse_underlying_price(data["description_extended"]),
          size: data["size"],
          bid: if(Map.has_key?(data, "bid"), do: data["bid"], else: nil),
          ask: if(Map.has_key?(data, "ask"), do: data["ask"], else: nil),
          midpoint: if(Map.has_key?(data, "midpoint"), do: data["midpoint"], else: nil),
          trade_count: data["trade_count"],
          open_interest: data["open_interest"],
          volume: data["volume"],
          description: data["description_extended"],
          option_symbol: data["option_symbol"],
          benzinga_signal_id: data["id"],
          benzinga_updated: data["updated"],
          is_published: false,
          is_plus: false
        })
        |> Changeset.put_assoc(:symbol, symbol)
        |> Repo.insert!()

      unless symbol do
        ticker = data["ticker"]
        Logger.error("Incoming option activity for a non-existent symbol: #{ticker}")
      end

      classifier = option_activity |> ActivityClassifier.classify()
      indicators = OptionActivity.indicators_for_activity(option_activity, classifier.signals)

      option_activity =
        option_activity
        |> OptionActivity.classify_changeset(%{
          signals: Enum.map(classifier.signals, fn f -> Atom.to_string(f) end),
          indicators: Enum.map(indicators, fn f -> Atom.to_string(f) end),
          is_plus: classifier.is_plus,
          is_published: classifier.is_published,
          is_buy: classifier.is_buy,
          is_sell: classifier.is_sell
        })
        |> Repo.update!()

      if option_activity.is_published do
        option_activity |> Broadcasts.option_activity()
      end
    end
  end

  defp fetch_option_activity(since) do
    BenzingaClient.option_activity(@page_size, since, Timex.local())
  end

  defp parse_datetime(date, time) do
    {:ok, dt} = NaiveDateTime.from_iso8601("#{date} #{time}")
    dt |> Timex.to_datetime("America/New_York")
  end

  defp parse_is_put(put_call) do
    unless Enum.member?(["CALL", "PUT"], put_call) do
      Logger.error("Unrecognized put_call value: #{put_call}")
    end

    put_call == "PUT"
  end

  defp parse_is_sweep(option_activity_type) do
    unless Enum.member?(["SWEEP", "TRADE"], option_activity_type) do
      Logger.error("Unrecognized option_activity_type value: #{option_activity_type}")
    end

    option_activity_type == "SWEEP"
  end

  defp parse_is_etf(underlying_type) do
    unless Enum.member?(["ETF", "STOCK"], underlying_type) do
      Logger.error("Unrecognized underlying_type value: #{underlying_type}")
    end

    underlying_type == "ETF"
  end

  defp parse_is_bearish(sentiment) do
    unless Enum.member?(["BULLISH", "BEARISH", "NEUTRAL"], sentiment) do
      Logger.error("Unrecognized sentiment value: #{sentiment}")
    end

    sentiment == "BEARISH"
  end

  defp parse_is_bullish(sentiment) do
    unless Enum.member?(["BULLISH", "BEARISH", "NEUTRAL"], sentiment) do
      Logger.error("Unrecognized sentiment value: #{sentiment}")
    end

    sentiment == "BULLISH"
  end

  def parse_underlying_price(description) do
    case Regex.run(~r/.*Ref=\$(\d+.?\d?\d?).*/, description) do
      nil -> nil
      match -> Enum.at(match, 1)
    end
  end
end
