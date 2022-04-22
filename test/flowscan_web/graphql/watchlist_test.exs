defmodule FlowscanWeb.Graphql.WatchlistTest do
  use FlowscanWeb.ConnCase
  import Flowscan.AbsintheHelpers
  import Ecto.Query
  alias Flowscan.{Repo, Watchlist}

  setup [:setup_factories]

  @add_to_watchlist_mutation """
  mutation addToWatchlist($symbolId: ID!) {
    addToWatchlist(symbolId: $symbolId) {
      ok
    }
  }
  """

  @remove_from_watchlist_mutation """
  mutation removeFromWatchlist($symbolId: ID!) {
    removeFromWatchlist(symbolId: $symbolId) {
      ok
    }
  }
  """

  test "add to watchlist", %{conn: conn, free_user: free_user, symbol: symbol} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@add_to_watchlist_mutation, %{symbolId: symbol.id}))

    data = json_response(res, 200)["data"]["addToWatchlist"]
    assert data["ok"] == true

    assert Watchlist
           |> where(user_id: ^free_user.id, symbol_id: ^symbol.id)
           |> Repo.all()
           |> length() == 1

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@add_to_watchlist_mutation, %{symbolId: symbol.id}))

    data = json_response(res, 200)["data"]["addToWatchlist"]
    assert data["ok"] == true

    assert Watchlist
           |> where(user_id: ^free_user.id, symbol_id: ^symbol.id)
           |> Repo.all()
           |> length() == 1
  end

  test "add to watchlist when symbol doesn't exist", %{conn: conn, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@add_to_watchlist_mutation, %{symbolId: 9_999_999_999}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "Symbol not found"
  end

  test "add to watchlist as a free user with 5 existing watchlist tickers", %{
    conn: conn,
    free_user: free_user,
    symbol: symbol,
    symbols: symbols
  } do
    Enum.map(symbols, fn s ->
      insert(:watchlist, user: free_user, symbol: s)
    end)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@add_to_watchlist_mutation, %{symbolId: symbol.id}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "WATCHLIST_FREE_LIMIT"

    assert Watchlist.size_for_user(free_user) == 5
  end

  test "add to watchlist as a pro user with 5 existing watchlist tickers", %{
    conn: conn,
    plus_user: plus_user,
    symbol: symbol,
    symbols: symbols
  } do
    Enum.map(symbols, fn s ->
      insert(:watchlist, user: plus_user, symbol: s)
    end)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@add_to_watchlist_mutation, %{symbolId: symbol.id}))

    data = json_response(res, 200)["data"]["addToWatchlist"]
    assert data["ok"] == true

    assert Watchlist.size_for_user(plus_user) == 6
  end

  test "unauthenticated user adding to watchlist", %{conn: conn, symbol: symbol} do
    res =
      conn
      |> graphql(query(@add_to_watchlist_mutation, %{symbolId: symbol.id}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "removing from watchlist", %{conn: conn, free_user: free_user, symbol: symbol} do
    insert(:watchlist, user: free_user, symbol: symbol)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@remove_from_watchlist_mutation, %{symbolId: symbol.id}))

    data = json_response(res, 200)["data"]["removeFromWatchlist"]
    assert data["ok"] == true

    assert Watchlist
           |> Repo.all()
           |> length() == 0
  end

  test "remove from watchlist when symbol doesn't exist", %{conn: conn, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@remove_from_watchlist_mutation, %{symbolId: 9_999_999_999}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "Symbol not found"
  end

  test "unauthenticated user removing from watchlist", %{conn: conn, symbol: symbol} do
    res =
      conn
      |> graphql(query(@remove_from_watchlist_mutation, %{symbolId: symbol.id}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  defp setup_factories(_) do
    %{
      symbol: insert(:symbol, symbol: "AAPL", name: "Apple Inc."),
      symbols: insert_list(5, :symbol),
      free_user: insert(:user, is_plus: false),
      plus_user: insert(:user, is_plus: true)
    }
  end

  # This should be moved out to helpers
  defp graphql(conn, query) do
    conn |> post("/graphql", query)
  end
end
