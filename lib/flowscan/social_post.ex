defmodule Flowscan.SocialPost do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo

  schema "social_posts" do
    field :body, :string
    field :sentiment, :string
    field :ticker, :string
    field :type, :string
    field :is_published, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(social_post, attrs) do
    social_post
    |> cast(attrs, [:ticker, :type, :body, :sentiment, :is_published])
    |> validate_required([:ticker, :type, :body, :sentiment])
  end

  def ticker_posted_recently?(ticker) do
    cutoff_minutes = -120
    cutoff = DateTime.utc_now() |> Timex.shift(minutes: cutoff_minutes)

    __MODULE__
    |> where(ticker: ^ticker)
    |> where([q], q.inserted_at >= ^cutoff)
    |> Repo.exists?()
  end

  def unpublished do
    cutoff_minutes = -20
    cutoff = DateTime.utc_now() |> Timex.shift(minutes: cutoff_minutes)

    __MODULE__
    |> where(is_published: false)
    |> where([q], q.inserted_at >= ^cutoff)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def mark_published!(post) do
    post
    |> changeset(%{is_published: true})
    |> Repo.update!()
  end
end
