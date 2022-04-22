defmodule Flowscan.Services.EarningsCalendarSync do
  @moduledoc false
  require Logger
  alias Ecto.Changeset
  alias Flowscan.EarningsCalendar
  alias Flowscan.Integrations.AlphaVantageClient
  alias Flowscan.Integrations.IexcloudClient
  alias Flowscan.Repo
  alias Flowscan.Symbol

  @confirmed_earnings_date_range 14

  def run do
    {:ok, data} = AlphaVantageClient.earnings_calendar()

    data
    |> Enum.each(fn record ->
      process_record(record)
    end)
  end

  defp process_record(record) do
    symbol = Symbol.find_by_symbol(record[:ticker])
    process_record(record, symbol)
  end

  defp process_record(record, %Symbol{} = symbol) do
    changeset = %{
      preliminary_earnings_date: record[:report_date],
      estimate: record[:estimate],
      fiscal_date_ending: record[:fiscal_date_ending]
    }

    earnings_record =
      case EarningsCalendar.find_for_fiscal_ending_date(
             symbol,
             record[:fiscal_date_ending]
           ) do
        %EarningsCalendar{} = earnings_record ->
          earnings_record
          |> EarningsCalendar.changeset(changeset)
          |> Repo.update!()

        _ ->
          %EarningsCalendar{}
          |> EarningsCalendar.changeset(changeset)
          |> Changeset.put_assoc(:symbol, symbol)
          |> Repo.insert!()
      end

    now = Timex.now()
    diff_days = Timex.diff(earnings_record.preliminary_earnings_date, now, :days)

    if diff_days >= 0 && diff_days <= @confirmed_earnings_date_range do
      update_confirmed_earnings_date(earnings_record)
    end
  end

  defp process_record(record, nil) do
    Logger.warn("EarningsCalendarSync: non-existent symbol #{record[:ticker]}")
  end

  defp update_confirmed_earnings_date(%EarningsCalendar{} = record) do
    symbol = Symbol.find_by_id(record.symbol_id)
    {:ok, data} = IexcloudClient.stats(symbol.symbol, "nextEarningsDate")
    date = if data == "", do: nil, else: data |> Date.from_iso8601!()

    record
    |> EarningsCalendar.changeset(%{confirmed_earnings_date: date})
    |> Repo.update!()
  end
end
