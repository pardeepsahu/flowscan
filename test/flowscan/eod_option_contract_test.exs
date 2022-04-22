defmodule Flowscan.EodOptionContractTest do
  @moduledoc false
  use Flowscan.DataCase
  alias Flowscan.Repo

  setup [:setup_activity]

  describe "eod_option_contract" do
    alias Flowscan.EodOptionContract

    test "update_incomplete_from_option_activity/1 creates new records", %{activity: activity} do
      EodOptionContract.update_incomplete_from_option_activity(activity)

      data =
        Repo.get_by(EodOptionContract,
          date: activity.datetime |> DateTime.to_date(),
          option_symbol: activity.option_symbol
        )

      assert data.volume == activity.volume
      assert data.open_interest == activity.open_interest
      assert data.data_updated_at == activity.datetime
      refute data.is_complete
    end

    test "update_incomplete_from_option_activity/1 updates incomplete records with newer data" do
      record =
        insert(:eod_option_contract,
          date: Timex.now() |> Timex.to_date(),
          data_updated_at: Timex.now() |> Timex.shift(minutes: -10)
        )

      activity =
        insert(:option_activity,
          symbol: record.symbol,
          option_symbol: record.option_symbol,
          volume: 90_000_000,
          datetime: Timex.now()
        )

      EodOptionContract.update_incomplete_from_option_activity(activity)

      data = Repo.get(EodOptionContract, record.id)
      assert data.volume == 90_000_000
      assert data.data_updated_at == activity.datetime
    end

    test "update_incomplete_from_option_activity/1 doesn't update complete records" do
      record =
        insert(:eod_option_contract, is_complete: true, date: Timex.now() |> Timex.to_date())

      activity =
        insert(:option_activity,
          symbol: record.symbol,
          option_symbol: record.option_symbol,
          volume: 90_000_000,
          datetime: Timex.now()
        )

      EodOptionContract.update_incomplete_from_option_activity(activity)

      data = Repo.get(EodOptionContract, record.id)
      assert data.volume == record.volume
      assert data.data_updated_at == record.data_updated_at
    end
  end

  defp setup_activity(_) do
    %{
      activity: insert(:option_activity)
    }
  end
end
