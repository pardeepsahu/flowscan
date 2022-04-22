defmodule FlowscanWeb.Graphql.OptionActivityTest do
  @moduledoc false
  use FlowscanWeb.ConnCase
  import Flowscan.AbsintheHelpers
  import Ecto.Query
  alias Flowscan.{OptionActivity, Repo}

  setup [:setup_factories]

  @option_activity_query """
  query optionActivity($cursor: ID, $symbolId: ID, $watchlist: Boolean, $filters: OptionActivityFilter){
    optionActivity(cursor: $cursor, symbolId: $symbolId, watchlist: $watchlist, filters: $filters) {
      id
      datetime
      symbolId
      ticker
      strike
      expirationDate
      isPut
      isSweep
      isRepeatSweep
      isBullish
      isBearish
      costBasis
      size
      volume
      openInterest
      underlyingPrice
    }
  }
  """

  @option_activity_details_query """
  query optionActivityDetails($optionActivityId: ID){
    optionActivityDetails(optionActivityId: $optionActivityId) {
      id
      datetime
      strike
      ticker
      expirationDate
      isPut
      isSweep
      isRepeatSweep
      costBasis
      size
      optionSymbol
      underlyingPrice
      volume
      openInterest
      isBullish
      isBearish
      isBuy
      isSell
      aboveAsk
      belowBid
      atAsk
      atBid
      earnings
      symbol {
        id
        name
      }
    }
  }
  """

  test "retrieve the latest unusual activity as an anonymous user, use cursor", %{
    conn: conn
  } do
    res =
      conn
      |> graphql(query(@option_activity_query, %{cursor: nil}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "retrieve the latest unusual activity as free user, use cursor", %{
    conn: conn,
    free_user: free_user
  } do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_query, %{cursor: nil}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 20

    latest =
      OptionActivity
      |> where(is_plus: false)
      |> preload(:symbol)
      |> order_by(desc: :datetime, desc: :id)
      |> limit(1)
      |> Repo.one()

    assert Integer.to_string(latest.id) == hd(data)["id"]
    assert latest.symbol.id == hd(data)["symbolId"]
    assert latest.symbol.symbol == hd(data)["ticker"]

    last_id = List.last(data)["id"]

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_query, %{cursor: last_id}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 10
  end

  test "retrieve the latest unusual activity as a pro user, use cursor, verify ETFs are not returned by default",
       %{
         conn: conn,
         plus_user: plus_user
       } do
    insert_list(10, :option_activity, is_etf: true)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{cursor: nil}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 20

    latest =
      OptionActivity
      |> where(is_etf: false)
      |> order_by(desc: :datetime, desc: :id)
      |> limit(1)
      |> Repo.one()

    assert Integer.to_string(latest.id) == hd(data)["id"]

    last_id = List.last(data)["id"]

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{cursor: last_id}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 15
  end

  test "retrieve the latest unusual activity for a specific symbol, as an anonymous user", %{
    conn: conn
  } do
    symbol = insert(:symbol, symbol: "DOESNOTEXIST")
    insert(:option_activity, is_plus: true, symbol: symbol)

    res =
      conn
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "retrieve the latest unusual activity for a specific symbol, as a pro user, use cursor", %{
    conn: conn,
    plus_user: plus_user
  } do
    symbol = insert(:symbol, symbol: "DOESNOTEXIST")
    insert_list(10, :option_activity, is_plus: false, symbol: symbol, is_etf: true)
    insert_list(21, :option_activity, is_plus: true, symbol: symbol)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 20

    latest =
      OptionActivity
      |> where(symbol_id: ^symbol.id)
      |> order_by(desc: :datetime, desc: :id)
      |> limit(1)
      |> Repo.one()

    assert Integer.to_string(latest.id) == hd(data)["id"]
    assert latest.size == hd(data)["size"]

    last_id = List.last(data)["id"]

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, cursor: last_id}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 11
  end

  test "retrieving watchlist for a non-pro user", %{
    conn: conn,
    free_user: free_user,
    symbol: symbol
  } do
    insert(:watchlist, user: free_user, symbol: symbol)
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: false)
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: false)
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: true)
    insert(:option_activity, symbol: insert(:symbol), is_plus: false)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_query, %{watchlist: true}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 2
    assert hd(data)["symbolId"] == symbol.id
    assert hd(data)["ticker"] == symbol.symbol
  end

  test "retrieving watchlist for a pro user", %{
    conn: conn,
    plus_user: plus_user,
    symbol: symbol
  } do
    insert(:watchlist, user: plus_user, symbol: symbol)
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: false, is_etf: true)
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: false)
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: true, is_etf: true)
    insert(:option_activity, symbol: insert(:symbol), is_plus: false)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{watchlist: true}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 3
  end

  test "retrieving watchlist for a user with empty watchlist", %{
    conn: conn,
    plus_user: plus_user,
    symbol: symbol
  } do
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: false)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{watchlist: true}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert data == []
  end

  test "retrieving watchlist for an unauthenticated user", %{
    conn: conn,
    symbol: symbol,
    free_user: free_user
  } do
    insert(:watchlist, user: free_user, symbol: symbol)
    insert(:option_activity, symbol: symbol, ticker: symbol.symbol, is_plus: false)

    res =
      conn
      |> graphql(query(@option_activity_query, %{watchlist: true}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "retrieve non-pro activity details as an anonymous user", %{
    conn: conn,
    free_option_activity: free_option_activity
  } do
    activity = hd(free_option_activity)

    res =
      conn
      |> graphql(query(@option_activity_details_query, %{optionActivityId: activity.id}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "retrieve pro activity details as a free user", %{
    conn: conn,
    free_user: free_user,
    plus_option_activity: plus_option_activity
  } do
    activity = hd(plus_option_activity)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_details_query, %{optionActivityId: activity.id}))

    data = json_response(res, 200)["data"]["optionActivityDetails"]
    assert data == nil
  end

  test "retrieve pro activity details as a pro user", %{
    conn: conn,
    plus_user: plus_user,
    plus_option_activity: plus_option_activity
  } do
    activity = hd(plus_option_activity)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_details_query, %{optionActivityId: activity.id}))

    data = json_response(res, 200)["data"]["optionActivityDetails"]
    assert data["id"] == Integer.to_string(activity.id)
  end

  test "filters for free users", %{conn: conn, symbol: symbol, free_user: free_user} do
    _bullish_call =
      insert(:option_activity,
        is_put: false,
        is_bearish: false,
        is_bullish: true,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: false
      )

    bearish_call =
      insert(:option_activity,
        is_put: false,
        is_bearish: true,
        is_bullish: false,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: false
      )

    bullish_put =
      insert(:option_activity,
        is_put: true,
        is_bearish: false,
        is_bullish: true,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: false
      )

    _plus_bullish_call =
      insert(:option_activity,
        is_put: false,
        is_bearish: false,
        is_bullish: true,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: true
      )

    _different_symbol =
      insert(:option_activity, is_put: false, is_bullish: true, is_bearish: false, is_plus: false)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, filters: %{bullish: true}}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 2

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, filters: %{bearish: true}}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 1
    assert hd(data)["id"] == Integer.to_string(bearish_call.id)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, filters: %{call: true}}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 2

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, filters: %{put: true}}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 1
    assert hd(data)["id"] == Integer.to_string(bullish_put.id)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(
        query(@option_activity_query, %{symbolId: symbol.id, filters: %{bullish: true, put: true}})
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 1
    assert hd(data)["id"] == Integer.to_string(bullish_put.id)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(
        query(@option_activity_query, %{symbolId: symbol.id, filters: %{bearish: true, put: true}})
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert data == []

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(
        query(@option_activity_query, %{
          symbolId: symbol.id,
          filters: %{bearish: true, bullish: true, put: true, call: true}
        })
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 3
  end

  test "plus-only filters", %{conn: conn, symbol: symbol, plus_user: plus_user} do
    _bullish_put =
      insert(:option_activity,
        expiration_date: ~D[2021-01-01],
        strike: 99.5,
        is_put: true,
        is_bearish: false,
        is_bullish: true,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: false,
        is_sweep: false,
        cost_basis: 50_000
      )

    bullish_aggressive_call =
      insert(:option_activity,
        expiration_date: ~D[2021-03-01],
        strike: 100,
        is_put: false,
        is_bearish: false,
        is_bullish: true,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: false,
        is_sweep: false,
        cost_basis: 50_000,
        signals: ["aggressive", "above_ask"]
      )

    plus_bullish_sweep =
      insert(:option_activity,
        expiration_date: ~D[2022-01-01],
        strike: 200,
        is_put: false,
        is_bearish: false,
        is_bullish: true,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: true,
        is_sweep: true,
        cost_basis: 30_000
      )

    plus_bearish_large =
      insert(:option_activity,
        expiration_date: ~D[2022-09-30],
        strike: 200.1,
        is_put: false,
        is_bearish: true,
        is_bullish: false,
        symbol: symbol,
        ticker: symbol.symbol,
        is_plus: true,
        is_sweep: false,
        cost_basis: 1_000_001
      )

    _different_symbol = insert(:option_activity, is_put: false, is_bullish: true, is_plus: false)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, filters: %{bullish: true}}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 3

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, filters: %{sweep: true}}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 1
    assert hd(data)["id"] == Integer.to_string(plus_bullish_sweep.id)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(query(@option_activity_query, %{symbolId: symbol.id, filters: %{large: true}}))

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 1
    assert hd(data)["id"] == Integer.to_string(plus_bearish_large.id)

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(
        query(@option_activity_query, %{symbolId: symbol.id, filters: %{aggressive: true}})
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 1
    assert hd(data)["id"] == Integer.to_string(bullish_aggressive_call.id)

    # strike
    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(
        query(@option_activity_query, %{
          symbolId: symbol.id,
          filters: %{strike_lte: 1000}
        })
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 4

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(
        query(@option_activity_query, %{
          symbolId: symbol.id,
          filters: %{strike_gte: 100, strike_lte: 200}
        })
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 2

    # expiration date
    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(
        query(@option_activity_query, %{
          symbolId: symbol.id,
          filters: %{expiration_date_lte: "2022-09-01"}
        })
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 3

    res =
      conn
      |> authenticate_conn(plus_user)
      |> graphql(
        query(@option_activity_query, %{
          symbolId: symbol.id,
          filters: %{expiration_date_gte: "2021-02-19", expiration_date_lte: "2022-05-01"}
        })
      )

    data = json_response(res, 200)["data"]["optionActivity"]
    assert length(data) == 2
  end

  defp setup_factories(_) do
    %{
      free_user: insert(:user, is_plus: false),
      plus_user: insert(:user, is_plus: true),
      free_option_activity: insert_list(30, :option_activity, is_plus: false),
      plus_option_activity: insert_list(10, :option_activity, is_plus: true),
      symbol: insert(:symbol, symbol: "AAPL", name: "Apple Inc."),
      symbols: insert_list(5, :symbol)
    }
  end

  # This should be moved out to helpers
  defp graphql(conn, query) do
    conn |> post("/graphql", query)
  end
end
