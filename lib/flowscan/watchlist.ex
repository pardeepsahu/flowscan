defmodule Flowscan.Watchlist do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.{Repo, Symbol, User}

  schema "watchlists" do
    belongs_to(:user, Flowscan.User, foreign_key: :user_id, type: :binary_id)
    belongs_to(:symbol, Flowscan.Symbol, foreign_key: :symbol_id)

    timestamps()
  end

  @doc false
  def changeset(watchlist, attrs) do
    watchlist
    |> cast(attrs, [])
  end

  def symbol_ids_for_user(%User{} = user) do
    __MODULE__
    |> select([q], %{symbol_id: q.symbol_id})
    |> where(user_id: ^user.id)
    |> Repo.all()
    |> Enum.map(fn w -> w.symbol_id end)
  end

  def notification_user_ids_for_symbol_id(symbol_id, plus_only \\ false) do
    __MODULE__
    |> select([q], %{user_id: q.user_id})
    |> join(:left, [q, u], u in User, on: q.user_id == u.id)
    |> where([q, u], q.symbol_id == ^symbol_id and u.notifications_watchlist == true)
    # |> (fn query ->
    #       case plus_only do
    #         true ->
    #           query
    #           |> where([q, u], u.is_plus == true)

    #         _ ->
    #           query
    #       end
    #     end).()
    |> Repo.all()
    |> Enum.map(fn w -> w.user_id end)
  end

  def add_to_watchlist(%User{} = user, %Symbol{} = symbol) do
    case Repo.get_by(__MODULE__, user_id: user.id, symbol_id: symbol.id) do
      watchlist = %Flowscan.Watchlist{} ->
        {:ok, watchlist}

      _ ->
        __MODULE__.__struct__()
        |> changeset(%{})
        |> put_assoc(:user, user)
        |> put_assoc(:symbol, symbol)
        |> Repo.insert()
    end
  end

  def remove_from_watchlist(%User{} = user, %Symbol{} = symbol) do
    case Repo.get_by(__MODULE__, user_id: user.id, symbol_id: symbol.id) do
      watchlist = %Flowscan.Watchlist{} ->
        watchlist |> Repo.delete()
        {:ok}

      _ ->
        {:ok}
    end
  end

  def in_watchlist?(%User{} = user, %Symbol{} = symbol) do
    query =
      from w in __MODULE__,
        where: w.user_id == ^user.id and w.symbol_id == ^symbol.id

    Repo.exists?(query)
  end

  def size_for_user(%User{} = user) do
    Repo.one(from w in __MODULE__, where: w.user_id == ^user.id, select: fragment("COUNT(*)"))
  end
end
