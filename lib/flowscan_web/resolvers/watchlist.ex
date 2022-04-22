defmodule FlowscanWeb.Resolvers.Watchlist do
  @moduledoc false
  alias Flowscan.{Symbol, Watchlist}
  import FlowscanWeb.GraphqlHelpers

  def add(_parent, %{symbol_id: symbol_id}, %{context: %{current_user: current_user}}) do
    free_user_limit = Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:watchlist_free_limit]

    case Symbol.find_by_id(symbol_id) do
      %Symbol{} = symbol ->
        if false && !current_user.is_plus &&
             Watchlist.size_for_user(current_user) >= free_user_limit do
          {:error, "WATCHLIST_FREE_LIMIT"}
        else
          case Watchlist.add_to_watchlist(current_user, symbol) do
            {:ok, %Watchlist{}} ->
              {:ok, %{ok: true}}

            {:error, changeset} ->
              {:error, extract_error_msg(changeset)}
          end
        end

      _ ->
        {:error, "Symbol not found"}
    end
  end

  def add(_, _, _), do: {:error, "NOT_AUTHENTICATED"}

  def remove(_parent, %{symbol_id: symbol_id}, %{context: %{current_user: current_user}}) do
    case Symbol.find_by_id(symbol_id) do
      %Symbol{} = symbol ->
        Watchlist.remove_from_watchlist(current_user, symbol)
        {:ok, %{ok: true}}

      _ ->
        {:error, "Symbol not found"}
    end
  end

  def remove(_, _, _), do: {:error, "NOT_AUTHENTICATED"}
end
