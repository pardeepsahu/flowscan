defmodule Flowscan.Highlight do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo
  alias Flowscan.Utils.MarketHours

  schema "highlights" do
    belongs_to(:category, Flowscan.HighlightCategory, foreign_key: :category_id)
    belongs_to(:option_activity, Flowscan.OptionActivity, foreign_key: :option_activity_id)

    field :datetime, :utc_datetime
    field :info, :string
    field :is_featured, :boolean, default: false
    field :is_plus, :boolean, default: false
    field :is_published, :boolean, default: false
    field :ref_id, :integer
    field :sentiment, Ecto.Enum, values: [:positive, :negative, :neutral, :unusual]
    field :indicators, {:array, :string}
    field :subtitle, :string
    field :ticker, :string
    field :title, :string
    field :type, Ecto.Enum, values: [:option_activity, :symbol]

    timestamps()
  end

  def feed do
    ten_days_ago = Timex.now() |> Timex.shift(days: -10) |> MarketHours.beginning_of_day()

    __MODULE__
    |> select([
      :id,
      :indicators,
      :info,
      :is_featured,
      :is_plus,
      :ref_id,
      :sentiment,
      :subtitle,
      :ticker,
      :title,
      :type,
      :inserted_at
    ])
    |> where(is_published: true)
    |> where([q], q.inserted_at >= ^ten_days_ago)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def recent_feed do
    __MODULE__
    |> select([
      :id,
      :indicators,
      :info,
      :is_featured,
      :is_plus,
      :ref_id,
      :sentiment,
      :subtitle,
      :ticker,
      :title,
      :type,
      :inserted_at
    ])
    |> where(is_published: true)
    |> order_by(desc: :inserted_at)
    |> limit(10)
    |> Repo.all()
  end

  def recent(_category_id, "featured") do
    recent_query()
    |> where(is_featured: true)
    |> Repo.all()
  end

  def recent(category_id, _slug) do
    # TODO: slug to be used for special categories (featured, closing bell for a specific day w/ cutoff)

    recent_query()
    |> where(category_id: ^category_id)
    |> Repo.all()
  end

  def recent_for_social("featured", cutoff) do
    __MODULE__
    |> where(is_published: true, is_featured: true, is_plus: false)
    |> where([q], q.inserted_at >= ^cutoff)
    |> order_by(asc: :inserted_at)
    |> preload([:option_activity, :category])
    |> Repo.all()
  end

  def recent_for_social(category_id, cutoff) do
    __MODULE__
    |> where(is_published: true, category_id: ^category_id)
    |> where([q], q.inserted_at >= ^cutoff)
    |> order_by(asc: :inserted_at)
    |> preload([:option_activity, :category])
    |> Repo.all()
  end

  def highlights_for_ticker_on_date?(ticker, category_id, date) do
    day_start = date |> MarketHours.beginning_of_day()
    day_end = date |> MarketHours.end_of_day()

    __MODULE__
    |> where(is_published: true, ticker: ^ticker, category_id: ^category_id)
    |> where([h], h.inserted_at >= ^day_start and h.inserted_at <= ^day_end)
    |> Repo.exists?()
  end

  def recent_free_highlights? do
    cutoff = Timex.now() |> Timex.shift(hours: -1)

    __MODULE__
    |> where(is_published: true, is_plus: false)
    |> where([h], h.inserted_at >= ^cutoff)
    |> Repo.exists?()
  end

  def mark_free!(highlight) do
    highlight
    |> changeset(%{is_plus: false})
    |> Repo.update!()
  end

  @doc false
  def changeset(highlight, attrs) do
    highlight
    |> cast(attrs, [
      :datetime,
      :ref_id,
      :type,
      :ticker,
      :title,
      :subtitle,
      :info,
      :sentiment,
      :indicators,
      :is_featured,
      :is_plus,
      :is_published
    ])
    |> validate_required([
      :datetime,
      :ref_id,
      :type,
      :ticker,
      :title,
      :sentiment,
      :is_featured,
      :is_plus,
      :is_published
    ])
  end

  def base_changeset(highlight, title, subtitle, info, sentiment, is_featured) do
    highlight
    |> cast(
      %{
        title: title,
        subtitle: subtitle,
        info: info,
        sentiment: sentiment,
        is_featured: is_featured
      },
      [:title, :subtitle, :info, :sentiment, :is_featured]
    )
  end

  def changeset_for_option_activity(
        highlight,
        option_activity,
        category
      ) do
    indicators =
      (option_activity.indicators || [])
      |> Enum.reject(fn i -> Enum.member?(["bullish", "bearish"], i) end)

    highlight
    |> changeset(%{
      datetime: option_activity.datetime,
      ref_id: option_activity.id,
      type: :option_activity,
      ticker: option_activity.ticker,
      is_plus: option_activity.is_plus,
      is_published: true,
      indicators: indicators
    })
    |> put_assoc(:category, category)
    |> put_assoc(:option_activity, option_activity)
  end

  def changeset_for_symbol(
        highlight,
        option_activity,
        category,
        indicators
      ) do
    highlight
    |> changeset(%{
      datetime: option_activity.datetime,
      ref_id: option_activity.symbol_id,
      type: :symbol,
      ticker: option_activity.ticker,
      is_plus: false,
      is_published: true,
      indicators: indicators
    })
    |> put_assoc(:category, category)
    |> put_assoc(:option_activity, option_activity)
  end

  def notification_display_string(highlight) do
    emoji =
      case highlight.sentiment do
        :negative -> "🟥 "
        :positive -> "🟩 "
        _ -> ""
      end

    "#{emoji}Highlight: #{highlight.ticker} #{highlight.title}"
  end

  def notification_display_details_string(highlight) do
    Enum.filter([highlight.subtitle, highlight.info], fn s -> !is_nil(s) end)
    |> Enum.join(", ")
  end

  defp recent_query do
    __MODULE__
    |> select([
      :id,
      :indicators,
      :info,
      :is_featured,
      :is_plus,
      :ref_id,
      :sentiment,
      :subtitle,
      :ticker,
      :title,
      :type
    ])
    |> where(is_published: true)
    |> order_by(desc: :inserted_at)
    |> limit(10)
  end
end
