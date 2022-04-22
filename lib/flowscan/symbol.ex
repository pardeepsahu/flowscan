defmodule Flowscan.Symbol do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Flowscan.Repo

  schema "symbols" do
    field :iex_id, :string
    field :figi, :string
    field :is_active, :boolean, default: true
    field :name, :string
    field :symbol, :string
    field :type, :string
    field :is_optionable, :boolean, default: false

    timestamps()
  end

  def changeset(symbol, attrs) do
    symbol
    |> cast(attrs, [:symbol, :name, :is_active, :type, :iex_id, :figi, :is_optionable])
    |> validate_required([:symbol, :name, :is_active])
  end

  def find_by_id(symbol_id) do
    Repo.get(__MODULE__, symbol_id)
  end

  def find_by_symbol(symbol) do
    Repo.get_by(__MODULE__, symbol: symbol)
  end

  def search(query) do
    sanitized_query = String.replace(query, ~r/[^a-zA-Z0-9\s]/, "") |> String.trim()
    symbol_pattern = "#{String.upcase(sanitized_query)}%"
    name_pattern = "\\y#{sanitized_query}"

    __MODULE__
    |> select([:id, :symbol, :name])
    |> where(is_active: true)
    |> where([q], like(q.symbol, ^symbol_pattern) or fragment("? ~* ?", q.name, ^name_pattern))
    |> order_by([q], desc: fragment("(? LIKE ?)::int", q.symbol, ^symbol_pattern), asc: :symbol)
    |> limit(50)
    |> Repo.all()
  end
end
