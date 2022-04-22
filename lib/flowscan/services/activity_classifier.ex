defmodule Flowscan.Services.ActivityClassifier do
  @moduledoc false

  alias Flowscan.EarningsCalendar
  alias Flowscan.OptionActivity
  require Logger

  defstruct [:activity, :signals, :is_published, :is_plus, :is_buy, :is_sell]

  @plus_activity_fallback_percentage 60
  @plus_activity_interesting_percentage 80

  def classify(%OptionActivity{} = activity) do
    if activity.symbol_id do
      activity
      |> default_classifier_state()
      |> classify_buy_sell()
      |> classify_signals()
      |> classify_is_plus()
      |> classify_is_published()
    else
      activity
      |> default_classifier_state()
    end
  end

  def classify_buy_sell(classifier) do
    cond do
      classifier.activity.is_put -> classify_put_buy_sell(classifier)
      !classifier.activity.is_put -> classify_call_buy_sell(classifier)
      true -> classifier
    end
  end

  defp classify_call_buy_sell(classifier) do
    cond do
      classifier.activity.is_bullish -> %{classifier | is_buy: true}
      classifier.activity.is_bearish -> %{classifier | is_sell: true}
      true -> classifier
    end
  end

  defp classify_put_buy_sell(classifier) do
    cond do
      classifier.activity.is_bearish -> %{classifier | is_buy: true}
      classifier.activity.is_bullish -> %{classifier | is_sell: true}
      true -> classifier
    end
  end

  def classify_signals(classifier) do
    classifier
    |> cost_basis()
    |> vol_oi()
    |> opening()
    |> aggressor()
    |> repeat_sweep()
    |> aggressive()
    |> earnings_soon()
  end

  def classify_is_published(classifier) do
    %{classifier | is_published: true}
  end

  def classify_is_plus(classifier) do
    is_plus =
      cond do
        !Enum.member?(classifier.signals, :earnings) && Enum.count(classifier.signals) >= 3 ->
          true

        Enum.member?(classifier.signals, :earnings) && Enum.count(classifier.signals) >= 4 ->
          true

        Enum.member?(classifier.signals, :vol_oi_high) ->
          true

        Enum.member?(classifier.signals, :repeat_sweep) ->
          true

        Enum.member?(classifier.signals, :above_ask) || Enum.member?(classifier.signals, :at_ask) ->
          Enum.random(1..100) < @plus_activity_interesting_percentage

        Enum.member?(classifier.signals, :below_bid) || Enum.member?(classifier.signals, :at_bid) ->
          Enum.random(1..100) < @plus_activity_interesting_percentage

        true ->
          Enum.random(1..100) < @plus_activity_fallback_percentage
      end

    %{classifier | is_plus: is_plus}
  end

  def cost_basis(classifier) do
    cond do
      Decimal.gt?(classifier.activity.cost_basis, "100000.0") && !classifier.activity.is_etf ->
        mark(classifier, :cost_basis_cs)

      Decimal.gt?(classifier.activity.cost_basis, "2000000.0") && classifier.activity.is_etf ->
        mark(classifier, :cost_basis_etf)

      true ->
        classifier
    end
  end

  def vol_oi(classifier) do
    vo =
      if classifier.activity.volume > 0 && classifier.activity.open_interest > 0,
        do: classifier.activity.volume / classifier.activity.open_interest,
        else: 0

    cond do
      vo >= 5 -> mark(classifier, :vol_oi_high)
      vo >= 2 -> mark(classifier, :vol_oi_medium)
      true -> classifier
    end
  end

  def opening(classifier) do
    if classifier.activity.size > classifier.activity.open_interest,
      do: mark(classifier, :opening),
      else: classifier
  end

  def aggressor(classifier) do
    cond do
      Decimal.gt?(classifier.activity.aggressor_ind, "1.0") -> mark(classifier, :above_ask)
      Decimal.eq?(classifier.activity.aggressor_ind, "1.0") -> mark(classifier, :at_ask)
      Decimal.eq?(classifier.activity.aggressor_ind, "0.0") -> mark(classifier, :at_bid)
      Decimal.lt?(classifier.activity.aggressor_ind, "0.0") -> mark(classifier, :below_bid)
      true -> classifier
    end
  end

  def repeat_sweep(classifier) do
    if classifier.activity.is_sweep && !classifier.activity.is_etf &&
         OptionActivity.repeat_sweep_count(classifier.activity) > 0 do
      mark(classifier, :repeat_sweep)
    else
      classifier
    end
  end

  def aggressive(classifier) do
    if is_at_or_above_ask_and_otm(classifier) do
      dte = OptionActivity.dte(classifier.activity)
      price_diff = OptionActivity.strike_price_diff_percentage(classifier.activity)

      cond do
        dte <= 5 && Decimal.gt?(price_diff, "0.15") ->
          mark(classifier, :aggressive)

        dte <= 30 && Decimal.gt?(price_diff, "0.3") ->
          mark(classifier, :aggressive)

        dte <= 365 && Decimal.gt?(price_diff, "0.6") ->
          mark(classifier, :aggressive)

        true ->
          classifier
      end
    else
      classifier
    end
  end

  def earnings_soon(classifier) do
    if EarningsCalendar.earnings_soon?(classifier.activity.symbol_id) do
      mark(classifier, :earnings)
    else
      classifier
    end
  end

  def default_classifier_state(%OptionActivity{} = activity) do
    __MODULE__.__struct__(%{
      activity: activity,
      is_buy: false,
      is_sell: false,
      is_plus: false,
      is_published: false,
      signals: []
    })
  end

  defp mark(classifier, signal) do
    %{classifier | signals: classifier.signals ++ [signal]}
  end

  defp is_at_or_above_ask_and_otm(classifier) do
    (Enum.member?(classifier.signals, :at_ask) || Enum.member?(classifier.signals, :above_ask)) &&
      OptionActivity.is_otm(classifier.activity)
  end
end
