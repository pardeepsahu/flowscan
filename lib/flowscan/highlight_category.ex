defmodule Flowscan.HighlightCategory do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo

  schema "highlight_categories" do
    field :description, :string
    field :is_active, :boolean, default: false
    field :slug, :string
    field :title, :string
    field :weight, :integer

    timestamps()
  end

  def list do
    __MODULE__
    |> select([:id, :title, :description, :slug])
    |> where(is_active: true)
    |> order_by(desc: :weight)
    |> Repo.all()
  end

  def get_by_slug!(slug) do
    __MODULE__
    |> where(slug: ^slug)
    |> Repo.one!()
  end

  @doc false
  def changeset(highlight_category, attrs) do
    highlight_category
    |> cast(attrs, [:title, :description, :slug, :weight, :is_active])
    |> validate_required([:title, :description, :slug, :weight, :is_active])
  end
end
