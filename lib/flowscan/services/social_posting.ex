defmodule Flowscan.Services.SocialPosting do
  @moduledoc false
  alias Flowscan.{Highlight, HighlightCategory}
  alias Flowscan.Integrations.StocktwitsClient
  alias Flowscan.Integrations.TwitterClient
  alias Flowscan.OptionActivity
  alias Flowscan.Repo
  alias Flowscan.SocialPost
  alias Flowscan.Utils.MarketHours
  require Logger

  @interval_minutes -5

  def run do
    # TODO: When nothing has been posted for, say, 1h+ - find_something()
    # TODO: ETF action at close - aggregate the big ETF options

    # TODO: Throttle all but featured alerts based on number of posts made in last hour or so across categories?
    # Might want to not have these limits around open and close

    case MarketHours.in_or_near_market_hours?() do
      true ->
        cutoff = DateTime.utc_now() |> Timex.shift(minutes: @interval_minutes)

        highlighted("featured", cutoff) |> create_from_highlights()
        highlighted("aggressive", cutoff) |> create_from_highlights()
        highlighted("repeat_sweeps", cutoff) |> create_from_highlights()
        highlighted("whales", cutoff) |> create_from_highlights()

        publish()

      _ ->
        nil
    end
  end

  def highlighted("featured", cutoff) do
    Highlight.recent_for_social("featured", cutoff)
  end

  def highlighted(slug, cutoff) do
    highlight_category = HighlightCategory.get_by_slug!(slug)
    Highlight.recent_for_social(highlight_category.id, cutoff)
  end

  def create_from_highlights(highlights) do
    highlights
    |> Enum.map(fn h ->
      body = compose(h.category.slug, h) |> upcase_first()
      create(h.category.slug, h.ticker, body, Atom.to_string(h.sentiment))
    end)
  end

  def create(type, ticker, body, sentiment) do
    # Avoid contantly spamming the same ticker
    if !SocialPost.ticker_posted_recently?(ticker) do
      %SocialPost{}
      |> SocialPost.changeset(%{type: type, ticker: ticker, body: body, sentiment: sentiment})
      |> Repo.insert()
    end
  end

  def publish do
    unpublished = SocialPost.unpublished()

    unpublished
    |> Enum.each(fn post ->
      SocialPost.mark_published!(post)

      tasks = [
        Task.async(fn -> publish_to_stocktwits(post) end),
        Task.async(fn -> publish_to_twitter(post) end)
      ]

      Task.await_many(tasks, 5_000)
    end)
  end

  defp publish_to_stocktwits(post) do
    sentiment =
      case post.sentiment do
        "positive" -> "bullish"
        "negative" -> "bearish"
        _ -> nil
      end

    enabled = Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:stocktwits_posting_enabled]

    if enabled do
      StocktwitsClient.create_message(post.body, sentiment)
    else
      Logger.info("#{__MODULE__}: Would publish to Stocktwits: #{post.body} ##{sentiment}")
    end
  end

  defp publish_to_twitter(post) do
    enabled = Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:twitter_posting_enabled]

    if enabled do
      TwitterClient.update(post.body)
    else
      Logger.info("#{__MODULE__}: Would publish to Twitter: #{post.body}")
    end
  end

  defp compose("repeat_sweeps", highlight) do
    contract = OptionActivity.format_contract_human(highlight.option_activity)

    pre =
      if highlight.option_activity.signals &&
           Enum.member?(highlight.option_activity.signals, "aggressive"),
         do: "aggressive",
         else: nil

    vol_oi_interesting =
      highlight.option_activity.volume > highlight.option_activity.open_interest

    animal = compose_animal(highlight.option_activity.is_put)

    description =
      Enum.random([
        "repeat sweeps in #{contract}",
        "repeat #{animal} sweepers in #{contract}",
        "repeat sweep action in #{contract}",
        "repeat #{animal}ish action in #{contract}"
      ])

    time = compose_market_time(highlight.option_activity.datetime)

    segments = [
      "$#{highlight.ticker}",
      pre,
      description,
      time,
      if(vol_oi_interesting, do: compose_vol_oi(highlight.option_activity), else: nil)
    ]

    segments |> Enum.filter(fn s -> !is_nil(s) end) |> Enum.join(" ")
  end

  defp compose("whales", highlight) do
    cost_basis = OptionActivity.format_large_number(highlight.option_activity.cost_basis)
    contract = OptionActivity.format_contract_human(highlight.option_activity)
    animal = compose_animal(highlight.option_activity.is_put)

    description =
      Enum.random([
        "$#{cost_basis} #{animal} whale in $#{highlight.ticker} #{contract}",
        "#{animal}ish $#{highlight.ticker} play - #{contract} for $#{cost_basis} in premium",
        "#{animal}ish $#{highlight.ticker} whale - #{contract} for $#{cost_basis} in premium",
        "$#{cost_basis} in $#{highlight.ticker} #{contract}"
      ])

    description
  end

  defp compose("aggressive", highlight) do
    cost_basis = OptionActivity.format_large_number(highlight.option_activity.cost_basis)
    contract = OptionActivity.format_contract_human(highlight.option_activity)
    animal = compose_animal(highlight.option_activity.is_put)

    description =
      Enum.random([
        "Aggressive $#{highlight.ticker} #{animal}s - $#{cost_basis} in #{contract}",
        "$#{highlight.ticker} aggressive #{contract} for $#{cost_basis} in premiums"
      ])

    description
  end

  defp compose(category, _highlight) do
    Logger.error("Social posting for category #{category} not implemented")
  end

  defp compose_vol_oi(option_activity) do
    volume = OptionActivity.format_large_number(option_activity.volume)
    open_interest = OptionActivity.format_large_number(option_activity.open_interest)
    "(Vol: #{volume} / OI: #{open_interest})"
  end

  defp compose_market_time(datetime) do
    cond do
      MarketHours.is_at_open?(datetime) ->
        Enum.random(["at the open"])

      MarketHours.is_at_close?(datetime) ->
        Enum.random(["just before close"])

      true ->
        nil
    end
  end

  defp compose_animal(is_put) do
    if is_put, do: "bear", else: "bull"
  end

  defp upcase_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest
end
