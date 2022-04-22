defmodule Flowscan.OptionActivityTest do
  @moduledoc false
  use Flowscan.DataCase

  describe "option_activity" do
    alias Flowscan.OptionActivity

    test "notification_display_string/1 and notification_display_details_string/1 correctly format data" do
      activity =
        Factory.insert(:option_activity,
          strike: 120.5,
          is_put: false,
          expiration_date: ~D[2021-02-10],
          ticker: "AAPL",
          volume: 12_345,
          open_interest: 207,
          cost_basis: 12_345_678,
          underlying_price: 891.12
        )

      assert OptionActivity.notification_display_string(activity) == "🟩 AAPL 02/10/21 120.5C"

      assert OptionActivity.notification_display_details_string(activity) ==
               "$12M premium, Vol: 12k, OI: 207, = 891.12"

      activity =
        Factory.insert(:option_activity,
          strike: 1000,
          is_put: true,
          expiration_date: ~D[2021-11-01],
          ticker: "PLTR",
          volume: 1_234_567,
          open_interest: 10_000,
          cost_basis: 345_678
        )

      assert OptionActivity.notification_display_string(activity) == "🟥 PLTR 11/01/21 1000P"

      assert OptionActivity.notification_display_details_string(activity) ==
               "$346k premium, Vol: 1.2M, OI: 10k"

      activity =
        Factory.insert(:option_activity,
          strike: 1000,
          is_put: true,
          expiration_date: ~D[2021-11-01],
          ticker: "PLTR",
          is_plus: true
        )

      assert OptionActivity.notification_display_string(activity) == "🟥 PLTR 11/01/21 1000P"
    end

    test "format_large_number/1 formats premiums nicely" do
      assert OptionActivity.format_large_number(Decimal.new(591)) == "591"
      assert OptionActivity.format_large_number(Decimal.new(10_000)) == "10k"
      assert OptionActivity.format_large_number(Decimal.new(12_345)) == "12k"
      assert OptionActivity.format_large_number(Decimal.new(12_800)) == "13k"
      assert OptionActivity.format_large_number(Decimal.new(100_000)) == "100k"
      assert OptionActivity.format_large_number(Decimal.from_float(234_567.11)) == "235k"
      assert OptionActivity.format_large_number(Decimal.new(1_234_567)) == "1.2M"
      assert OptionActivity.format_large_number(Decimal.new(9_000_000)) == "9M"
      assert OptionActivity.format_large_number(Decimal.new(10_000_000)) == "10M"
      assert OptionActivity.format_large_number(Decimal.new(10_490_000)) == "10M"
      assert OptionActivity.format_large_number(Decimal.new(23_569_100)) == "24M"
    end

    test "format_contract_human/1 produces human-readable contract description" do
      next_week = DateTime.utc_now() |> Timex.shift(weeks: 1)

      activity = %OptionActivity{
        strike: Decimal.from_float(210.50),
        expiration_date: next_week,
        is_put: false
      }

      assert activity |> OptionActivity.format_contract_human() ==
               Timex.format!(activity.expiration_date, "{Mshort} {D}") <> " $210.5 calls"

      assert %OptionActivity{
               strike: Decimal.from_float(100.0),
               expiration_date: ~D[2050-12-31],
               is_put: true
             }
             |> OptionActivity.format_contract_human() == "Dec 31 2050 $100 puts"
    end

    test "repeat_sweep_count/1 correctly counts repeat option sweeps" do
      now = DateTime.utc_now()

      activity =
        insert(:option_activity,
          is_sweep: true,
          datetime: now,
          option_symbol: "SPY210319C00397000"
        )

      # Prior sweep #1
      insert(:option_activity,
        option_symbol: "SPY210319C00397000",
        is_sweep: true,
        datetime: now |> Timex.shift(minutes: -3)
      )

      # Prior sweep #2
      insert(:option_activity,
        option_symbol: "SPY210319C00397000",
        is_sweep: true,
        datetime: now |> Timex.shift(minutes: -4)
      )

      # Outside of the 5min cutoff
      insert(:option_activity,
        option_symbol: "SPY210319C00397000",
        is_sweep: true,
        datetime: now |> Timex.shift(minutes: -6)
      )

      # After the current option activity
      insert(:option_activity,
        option_symbol: "SPY210319C00397000",
        is_sweep: true,
        datetime: now |> Timex.shift(minutes: 1)
      )

      # Different strike
      insert(:option_activity,
        option_symbol: "SPY210319C00398000",
        is_sweep: true,
        datetime: now |> Timex.shift(minutes: -4)
      )

      # Different symbol
      insert(:option_activity,
        option_symbol: "IWM210319C00397000",
        is_sweep: true,
        datetime: now |> Timex.shift(minutes: -4)
      )

      assert OptionActivity.repeat_sweep_count(activity) == 2
    end
  end
end
