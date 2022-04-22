defmodule Flowscan.Services.HighlightClassifier do
  @moduledoc false
  alias Flowscan.Data.HighlightActivity
  alias Flowscan.{Highlight, HighlightCategory, OptionActivity}
  alias Flowscan.Repo
  alias Flowscan.Services.Broadcasts
  alias Flowscan.Utils.MarketHours
  require Logger

  @interval_minutes -5
  @categories [:aggressive, :repeat_sweeps, :whales]

  def run do
    case MarketHours.in_or_near_market_hours?() do
      true ->
        cutoff = DateTime.utc_now() |> Timex.shift(minutes: @interval_minutes)

        @categories
        |> Enum.each(fn category ->
          candidates(cutoff, category) |> publish!()
        end)

      false ->
        nil
    end
  end

  def dry_run(cutoff) do
    highlights =
      @categories
      |> Enum.map(fn category ->
        candidates(cutoff, category)
      end)
      |> List.flatten()

    highlights
    |> Enum.each(fn cs ->
      highlight = cs.changes

      featured_str = if Map.get(highlight, :is_featured), do: "[🔔FEATURED]", else: ""
      plus_str = if Map.get(highlight, :is_plus), do: "[PLUS]", else: "[FREE]"

      str =
        Enum.join(
          [
            highlight.category.data.slug,
            highlight.ticker,
            highlight.title,
            Map.get(highlight, :subtitle) || "",
            Map.get(highlight, :info) || "",
            inspect(highlight.option_activity.data.signals),
            "size=#{highlight.option_activity.data.size}, oi=#{
              highlight.option_activity.data.open_interest
            }, vol=#{highlight.option_activity.data.volume}",
            featured_str,
            plus_str
          ],
          "; "
        )

      Logger.info("Highlight - #{str}")
    end)
  end

  def candidates(cutoff, :aggressive) do
    category = HighlightCategory.get_by_slug!("aggressive")
    recent = HighlightActivity.aggressive(cutoff)

    candidates =
      Enum.filter(recent, fn activity ->
        !Highlight.highlights_for_ticker_on_date?(activity.ticker, category.id, activity.datetime)
      end)

    candidates
    |> Enum.map(fn activity ->
      %{title: title, subtitle: subtitle, info: info, sentiment: sentiment} =
        format_option_activity(activity)

      is_featured = Enum.member?(activity.signals, "opening") || activity.size > activity.volume

      %Highlight{}
      |> Highlight.base_changeset(title, subtitle, info, sentiment, is_featured)
      |> Highlight.changeset_for_option_activity(activity, category)
    end)
  end

  def candidates(cutoff, :repeat_sweeps) do
    category = HighlightCategory.get_by_slug!("repeat_sweeps")
    recent = HighlightActivity.repeat_sweeps(cutoff)

    recent
    |> Enum.map(fn activity ->
      activity = OptionActivity.get_by_id(activity[:id], true)

      title =
        OptionActivity.format_expiration_date(activity.expiration_date) <>
          " " <> OptionActivity.format_strike(activity.strike, activity.is_put)

      # TODO: At open, just before market close, etc
      is_featured = Enum.member?(activity.signals, "vol_oi_high")
      subtitle = nil
      info = "Repeat sweeps"

      sentiment =
        cond do
          activity.is_bullish -> :positive
          activity.is_bearish -> :negative
          true -> :neutral
        end

      %Highlight{}
      |> Highlight.base_changeset(title, subtitle, info, sentiment, is_featured)
      |> Highlight.changeset_for_symbol(activity, category, ["sweep"])
    end)
  end

  def candidates(cutoff, :whales) do
    category = HighlightCategory.get_by_slug!("whales")
    recent = HighlightActivity.whales(cutoff)

    recent
    |> Enum.map(fn activity ->
      %{title: title, subtitle: subtitle, info: info, sentiment: sentiment} =
        format_option_activity(activity)

      is_featured = Enum.member?(activity.signals, "opening") || activity.size > activity.volume

      %Highlight{}
      |> Highlight.base_changeset(title, subtitle, info, sentiment, is_featured)
      |> Highlight.changeset_for_option_activity(activity, category)
    end)
  end

  def publish!(highlights) do
    highlights
    |> Enum.map(fn highlight ->
      {:ok, highlight} = highlight |> Repo.insert()

      Logger.info(
        "Highlight - #{highlight.category.slug}: #{highlight.ticker} #{highlight.title} #{
          highlight.subtitle
        } #{highlight.info}"
      )

      # If no free highlights in the last hour, mark the activity free
      recent_free = Highlight.recent_free_highlights?()

      highlight =
        if recent_free || !highlight.is_plus do
          highlight
        else
          Logger.info("Highlight - Marking option activity as free")

          if highlight.type == :option_activity do
            OptionActivity.mark_free!(highlight.option_activity)
          end

          Highlight.mark_free!(highlight)
        end

      if highlight.is_featured do
        highlight |> Broadcasts.featured_highlight()
      end

      highlight
    end)
  end

  def format_option_activity(option_activity) do
    size = OptionActivity.format_large_number(option_activity.size)
    volume = OptionActivity.format_large_number(option_activity.volume)
    open_interest = OptionActivity.format_large_number(option_activity.open_interest)

    title =
      OptionActivity.format_expiration_date(option_activity.expiration_date) <>
        " " <> OptionActivity.format_strike(option_activity.strike, option_activity.is_put)

    subtitle = "$" <> OptionActivity.format_large_number(option_activity.cost_basis)

    info =
      cond do
        Enum.member?(option_activity.signals, "opening") ->
          "Opening order"

        option_activity.size > option_activity.volume ->
          "Size #{size}, Vol #{volume}"

        true ->
          "Vol #{volume} / OI #{open_interest}"
      end

    sentiment =
      cond do
        option_activity.is_bullish -> :positive
        option_activity.is_bearish -> :negative
        true -> :neutral
      end

    %{title: title, subtitle: subtitle, info: info, sentiment: sentiment}
  end
end
