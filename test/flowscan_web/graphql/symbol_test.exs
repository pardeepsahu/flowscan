defmodule FlowscanWeb.Graphql.SymbolTest do
  @moduledoc false
  import Mock
  use FlowscanWeb.ConnCase
  alias Flowscan.Integrations.IexcloudClient
  alias Flowscan.Utils.MarketHours
  import Flowscan.AbsintheHelpers

  setup [:setup_factories]

  @symbol_search_query """
  query symbolSearch($query: String!) {
    symbolSearch(query: $query) {
      symbol
      name
    }
  }
  """

  @symbol_query """
  query symbol($symbolId: ID!) {
    symbol(symbolId: $symbolId) {
      symbol
      name
      inWatchlist
      strikeRange {
        min
        max
      }
    }
  }
  """

  @symbol_ohlcv """
  query symbolOhlcv($symbolId: ID!) {
    symbolOhlcv(symbolId: $symbolId) {
      date
      close
      low
      high
      volume
    }
  }
  """

  @iex_ohlcv_data {:ok,
                   [
                     %{
                       "close" => 124.28,
                       "date" => "2021-06-01",
                       "high" => 125.35,
                       "low" => 123.94,
                       "open" => 125.08,
                       "symbol" => "AAPL",
                       "updated" => 1_622_595_605_000,
                       "volume" => 67_637_118
                     },
                     %{
                       "close" => 125.06,
                       "date" => "2021-06-02",
                       "high" => 125.24,
                       "low" => 124.05,
                       "open" => 124.28,
                       "symbol" => "AAPL",
                       "updated" => 1_622_682_028_000,
                       "volume" => 59_278_862
                     },
                     %{
                       "close" => 123.54,
                       "date" => "2021-06-03",
                       "high" => 124.85,
                       "low" => 123.13,
                       "open" => 124.68,
                       "symbol" => "AAPL",
                       "updated" => 1_622_768_403_000,
                       "volume" => 76_229_170
                     },
                     %{
                       "close" => 125.89,
                       "date" => "2021-06-04",
                       "high" => 126.16,
                       "low" => 123.85,
                       "open" => 124.07,
                       "symbol" => "AAPL",
                       "updated" => 1_622_855_764_000,
                       "volume" => 75_169_343
                     }
                   ]}

  test "search exact match", %{conn: conn, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@symbol_search_query, %{query: "aapl"}))

    data = json_response(res, 200)["data"]["symbolSearch"]
    assert length(data) == 1

    assert hd(data) == %{
             "name" => "Apple Inc.",
             "symbol" => "AAPL"
           }
  end

  test "search partial matches", %{conn: conn, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@symbol_search_query, %{query: "aa"}))

    data = json_response(res, 200)["data"]["symbolSearch"]
    assert length(data) == 3

    assert Enum.at(data, 0)["symbol"] == "AA"
    assert Enum.at(data, 1)["symbol"] == "AAP"
    assert Enum.at(data, 2)["symbol"] == "AAPL"
  end

  test "search by name", %{conn: conn, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@symbol_search_query, %{query: "app"}))

    data = json_response(res, 200)["data"]["symbolSearch"]
    assert length(data) == 1

    assert Enum.at(data, 0)["symbol"] == "AAPL"
  end

  test "lookup a symbol", %{conn: conn, aapl: aapl, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@symbol_query, %{symbolId: aapl.id}))

    data = json_response(res, 200)["data"]["symbol"]
    assert data["symbol"] == "AAPL"
    assert data["name"] == "Apple Inc."
    assert data["inWatchlist"] == false
  end

  test "lookup a symbol not in watchlist", %{
    conn: conn,
    free_user: free_user,
    aapl: aapl
  } do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@symbol_query, %{symbolId: aapl.id}))

    data = json_response(res, 200)["data"]["symbol"]

    assert data["symbol"] == "AAPL"
    assert data["name"] == "Apple Inc."
    assert data["inWatchlist"] == false
  end

  test "lookup a symbol in watchlist", %{
    conn: conn,
    free_user: free_user,
    aapl: aapl
  } do
    insert(:watchlist, user: free_user, symbol: aapl)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@symbol_query, %{symbolId: aapl.id}))

    data = json_response(res, 200)["data"]["symbol"]
    assert data["symbol"] == "AAPL"
    assert data["name"] == "Apple Inc."
    assert data["inWatchlist"] == true
  end

  test "lookup a symbol and retrieve min/max strike range", %{
    conn: conn,
    free_user: free_user,
    aapl: aapl
  } do
    insert(:option_activity, symbol: aapl, strike: 20)
    insert(:option_activity, symbol: aapl, strike: 50)
    insert(:option_activity, symbol: aapl, strike: 120)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@symbol_query, %{symbolId: aapl.id}))

    data = json_response(res, 200)["data"]["symbol"]
    assert data["strikeRange"]["min"] == "20"
    assert data["strikeRange"]["max"] == "120"
  end

  test "retrieve OHLCV data for a ticker", %{conn: conn, free_user: free_user, aapl: aapl} do
    with_mock MarketHours, previous_trading_day: fn -> ~D[2021-06-04] end do
      with_mock IexcloudClient,
        historical_prices: fn _symbol, _range -> @iex_ohlcv_data end do
        res =
          conn
          |> authenticate_conn(free_user)
          |> graphql(query(@symbol_ohlcv, %{symbolId: aapl.id}))

        assert called(IexcloudClient.historical_prices("AAPL", "3m"))
        data = json_response(res, 200)["data"]["symbolOhlcv"]
        assert Enum.count(data) == 4
        day = hd(data)
        assert day["close"] == "124.28"
        assert day["date"] == "2021-06-01"
        assert day["high"] == "125.35"
        assert day["low"] == "123.94"
        assert day["volume"] == 67_637_118
      end
    end
  end

  defp setup_factories(_) do
    %{
      aapl: insert(:symbol, symbol: "AAPL", name: "Apple Inc."),
      symbols: [
        insert(:symbol, symbol: "A", name: "Agilent Technologies Inc."),
        insert(:symbol, symbol: "AA", name: "Definitely Not Alcoa Corp."),
        insert(:symbol, symbol: "AAP", name: "Advance Auto Parts Inc."),
        insert(:symbol, symbol: "AAX", name: "Disabled Co.", is_active: false),
        insert(:symbol, symbol: "BA", name: "Boeing Company")
      ],
      free_user: insert(:user, is_plus: false)
    }
  end

  # This should be moved out to helpers
  defp graphql(conn, query) do
    conn |> post("/graphql", query)
  end
end
