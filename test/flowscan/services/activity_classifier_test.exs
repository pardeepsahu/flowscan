defmodule Flowscan.Services.ActivityClassifierTest do
  @moduledoc false
  use Flowscan.DataCase
  alias Flowscan.Services.ActivityClassifier
  setup [:fake_activity]

  describe "ActivityClassifier" do
    test "cost_basis/1 marks high worth common stock plays", %{activity: activity} do
      result =
        %{activity | is_etf: false, cost_basis: Decimal.new(80_000)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.cost_basis()

      assert result.signals == []

      result =
        %{activity | is_etf: false, cost_basis: Decimal.new(101_000)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.cost_basis()

      assert result.signals == [:cost_basis_cs]
    end

    test "cost_basis/1 marks high worth ETF stock plays", %{activity: activity} do
      result =
        %{activity | is_etf: true, cost_basis: Decimal.new(1_200_000)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.cost_basis()

      assert result.signals == []

      result =
        %{activity | is_etf: true, cost_basis: Decimal.new(2_100_000)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.cost_basis()

      assert result.signals == [:cost_basis_etf]
    end

    test "vol_oi/1 marks activities with high Volume/OI", %{activity: activity} do
      result =
        %{activity | volume: 1_000, open_interest: 800}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.vol_oi()

      assert result.signals == []

      result =
        %{activity | volume: 1_000, open_interest: 500}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.vol_oi()

      assert result.signals == [:vol_oi_medium]

      result =
        %{activity | volume: 1_000, open_interest: 200}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.vol_oi()

      assert result.signals == [:vol_oi_high]
    end

    test "opening/1 marks activities where size > OI", %{activity: activity} do
      result =
        %{activity | size: 100, open_interest: 800}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.opening()

      assert result.signals == []

      result =
        %{activity | size: 1_000, open_interest: 990}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.opening()

      assert result.signals == [:opening]
    end

    test "aggressor/1 marks activities that are 90%+ at the ask", %{activity: activity} do
      result =
        %{activity | aggressor_ind: Decimal.from_float(0.7)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()

      assert result.signals == []

      result =
        %{activity | aggressor_ind: Decimal.from_float(1.01)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()

      assert result.signals == [:above_ask]
    end

    test "aggressor/1 marks activities that are 90%+ at the bid", %{activity: activity} do
      result =
        %{activity | aggressor_ind: Decimal.from_float(0.2)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()

      assert result.signals == []

      result =
        %{activity | aggressor_ind: Decimal.from_float(-0.01)}
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()

      assert result.signals == [:below_bid]
    end

    test "repeat_sweep/1 marks activities that are repeat sweeps" do
      now = DateTime.utc_now()

      activity =
        insert(:option_activity,
          is_sweep: true,
          datetime: now,
          option_symbol: "SPY210319C00397000"
        )

      result =
        activity
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.repeat_sweep()

      assert result.signals == []

      insert(:option_activity,
        option_symbol: "SPY210319C00397000",
        is_sweep: true,
        datetime: now |> Timex.shift(minutes: -4)
      )

      result =
        activity
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.repeat_sweep()

      assert result.signals == [:repeat_sweep]
    end

    test "aggressive/1 marks aggressive imminent OTM bets", %{activity: activity} do
      # 5 days - 15% OTM call - mark
      now = DateTime.utc_now()
      week_from_now = now |> Timex.shift(days: 4)

      base_activity = %{
        activity
        | strike: Decimal.from_float(115.0),
          underlying_price: Decimal.from_float(99.0),
          is_put: false,
          datetime: now,
          expiration_date: week_from_now,
          aggressor_ind: Decimal.from_float(1.01)
      }

      result =
        base_activity
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()
        |> ActivityClassifier.aggressive()

      assert result.signals == [:above_ask, :aggressive]

      # 5 days - 15% OTM put - mark
      act = %{
        base_activity
        | strike: Decimal.from_float(73.5),
          underlying_price: Decimal.from_float(99.0),
          is_put: true
      }

      result =
        act
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()
        |> ActivityClassifier.aggressive()

      assert result.signals == [:above_ask, :aggressive]

      # 5 days - 10% OTM put - don't mark
      act = %{
        base_activity
        | strike: Decimal.from_float(90.1),
          underlying_price: Decimal.from_float(99.0),
          is_put: true
      }

      result =
        act
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()
        |> ActivityClassifier.aggressive()

      assert result.signals == [:above_ask]

      # 7 days - 15% OTM call - don't mark
      act = %{
        base_activity
        | expiration_date: now |> Timex.shift(days: 7)
      }

      result =
        act
        |> ActivityClassifier.default_classifier_state()
        |> ActivityClassifier.aggressor()
        |> ActivityClassifier.aggressive()

      assert result.signals == [:above_ask]
    end
  end

  test "aggressive/1 marks aggressive short-term OTM bets", %{activity: activity} do
    # 30 days - 30% OTM call - mark
    now = DateTime.utc_now()
    month_from_now = now |> Timex.shift(days: 30)

    base_activity = %{
      activity
      | strike: Decimal.from_float(130.0),
        underlying_price: Decimal.from_float(99.0),
        is_put: false,
        datetime: now,
        expiration_date: month_from_now,
        aggressor_ind: Decimal.from_float(1.01)
    }

    result =
      base_activity
      |> ActivityClassifier.default_classifier_state()
      |> ActivityClassifier.aggressor()
      |> ActivityClassifier.aggressive()

    assert result.signals == [:above_ask, :aggressive]

    # 30 days - 15% OTM put - mark
    act = %{
      base_activity
      | strike: Decimal.from_float(68.5),
        underlying_price: Decimal.from_float(99.0),
        is_put: true
    }

    result =
      act
      |> ActivityClassifier.default_classifier_state()
      |> ActivityClassifier.aggressor()
      |> ActivityClassifier.aggressive()

    assert result.signals == [:above_ask, :aggressive]
  end

  test "classify_is_plus/1 marks 3+ signal activities as pro" do
    cls = %ActivityClassifier{
      signals: [:vol_oi_medium, :cost_basis_cs, :repeat_sweep],
      is_plus: false,
      is_published: false
    }

    assert ActivityClassifier.classify_is_plus(cls).is_plus
  end

  test "classify_is_plus/1 marks activities as pro based on certain signals" do
    cls = %ActivityClassifier{signals: [:vol_oi_high], is_plus: false, is_published: false}
    assert ActivityClassifier.classify_is_plus(cls).is_plus

    cls = %ActivityClassifier{signals: [:repeat_sweep], is_plus: false, is_published: false}
    assert ActivityClassifier.classify_is_plus(cls).is_plus
  end

  # test "classify_is_plus/1 marks about 60% of boring activities as pro" do
  #   cls = %ActivityClassifier{signals: [], is_plus: false, is_published: false}

  #   results =
  #     Enum.map(Enum.to_list(1..300), fn _ -> ActivityClassifier.classify_is_plus(cls).is_plus end)

  #   count = Enum.count(results, fn r -> r end)
  #   assert count > 45 * 3 && count < 75 * 3
  # end

  test "classify_is_plus/1 marks about 80% of certain interesting activities as pro" do
    cls = %ActivityClassifier{signals: [:above_ask], is_plus: false, is_published: false}

    results =
      Enum.map(Enum.to_list(1..300), fn _ -> ActivityClassifier.classify_is_plus(cls).is_plus end)

    count = Enum.count(results, fn r -> r end)
    assert count > 70 * 3 && count < 90 * 3

    cls = %ActivityClassifier{signals: [:below_bid], is_plus: false, is_published: false}

    results =
      Enum.map(Enum.to_list(1..300), fn _ -> ActivityClassifier.classify_is_plus(cls).is_plus end)

    count = Enum.count(results, fn r -> r end)
    assert count > 70 * 3 && count < 90 * 3
  end

  test "classify_is_published/1 marks pro activities as published", %{activity: activity} do
    cls = %ActivityClassifier{activity: activity, signals: [], is_plus: true, is_published: false}
    assert ActivityClassifier.classify_is_published(cls).is_published
  end

  test "classify_is_published/1 marks activities with certain signals as published", %{
    activity: activity
  } do
    cls = %ActivityClassifier{
      activity: activity,
      signals: [:vol_oi_medium],
      is_plus: false,
      is_published: false
    }

    assert ActivityClassifier.classify_is_published(cls).is_published

    cls = %ActivityClassifier{
      activity: activity,
      signals: [:above_ask],
      is_plus: false,
      is_published: false
    }

    assert ActivityClassifier.classify_is_published(cls).is_published

    cls = %ActivityClassifier{
      activity: activity,
      signals: [:below_bid],
      is_plus: false,
      is_published: false
    }

    assert ActivityClassifier.classify_is_published(cls).is_published
  end

  test "classify_is_published/1 marks all of boring activities as published", %{
    activity: activity
  } do
    cls = %ActivityClassifier{
      activity: activity,
      signals: [],
      is_plus: false,
      is_published: false
    }

    results =
      Enum.map(Enum.to_list(1..100), fn _ ->
        ActivityClassifier.classify_is_published(cls).is_published
      end)

    count = Enum.count(results, fn r -> r end)
    assert count == 100
  end

  # test "classify_is_published/1 is picky when it comes to ETFs", %{activity: activity} do
  #   cls = %ActivityClassifier{
  #     activity: %{activity | is_etf: true},
  #     signals: [:vol_oi_medium, :above_ask],
  #     is_plus: true,
  #     is_published: false
  #   }

  #   refute ActivityClassifier.classify_is_published(cls).is_published

  #   cls = %ActivityClassifier{
  #     activity: %{activity | is_etf: true},
  #     signals: [:cost_basis_etf],
  #     is_plus: true,
  #     is_published: false
  #   }

  #   assert ActivityClassifier.classify_is_published(cls).is_published

  #   cls = %ActivityClassifier{
  #     activity: %{activity | is_etf: true},
  #     signals: [:vol_oi_medium, :above_ask, :repeat_sweep],
  #     is_plus: true,
  #     is_published: false
  #   }

  #   assert ActivityClassifier.classify_is_published(cls).is_published
  # end

  defp fake_activity(_) do
    symbol = insert(:symbol)

    %{
      activity: Flowscan.OptionActivity.fake_one(symbol)
    }
  end
end
