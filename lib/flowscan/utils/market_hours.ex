defmodule Flowscan.Utils.MarketHours do
  @moduledoc false
  alias Flowscan.OptionActivity

  def in_or_near_market_hours? do
    now = Timex.now("America/New_York")
    day_of_week = now |> DateTime.to_date() |> Date.day_of_week()

    case day_of_week do
      d when d >= 1 and d <= 5 ->
        case now.hour do
          h when h >= 9 and h <= 16 -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  def is_at_open?(time) do
    et = time |> Timex.Timezone.convert("America/New_York")
    et.hour == 9 && et.minute > 30 && et.minute < 50
  end

  def is_at_close?(time) do
    et = time |> Timex.Timezone.convert("America/New_York")
    et.hour == 3 && et.minute > 40
  end

  def beginning_of_day(date) do
    date
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.Timezone.beginning_of_day()
    |> Timex.Timezone.convert("Etc/UTC")
  end

  def end_of_day(date) do
    date
    |> Timex.Timezone.convert("America/New_York")
    |> Timex.Timezone.end_of_day()
    |> Timex.Timezone.convert("Etc/UTC")
  end

  def previous_trading_day(datetime \\ nil) do
    if(datetime, do: datetime, else: Timex.now())
    |> beginning_of_day()
    |> OptionActivity.latest_prior_to()
    |> DateTime.to_date()
  end
end
