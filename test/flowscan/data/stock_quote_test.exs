defmodule Flowscan.Data.StockQuoteTest do
  @moduledoc false
  import Mock
  use Flowscan.DataCase
  use Oban.Testing, repo: Flowscan.Repo
  alias Flowscan.Data.StockQuote
  alias Flowscan.Integrations.IexcloudClient
  alias Flowscan.Utils.MarketHours

  setup [:clear_cache, :setup_factories]

  @iexcloud_batch_quotes_reponse Poison.decode!("""
                                   {
                                     "AAPL": {
                                         "quote": {
                                             "latestPrice": 119.99,
                                             "latestSource": "Close",
                                             "iexRealtimePrice": 118.01
                                         }
                                     },
                                     "AMZN": {
                                         "quote": {
                                             "latestPrice": 3074.96,
                                             "latestSource": "Close",
                                             "iexRealtimePrice": null
                                         }
                                     }
                                 }
                                 """)

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

  describe "StockQuote" do
    test "ohlcv_3mo/1 fetches, then returns quotes for a ticker that has no data", %{aapl: aapl} do
      with_mock MarketHours, previous_trading_day: fn -> ~D[2021-06-04] end do
        with_mock IexcloudClient,
          historical_prices: fn _symbol, _range -> @iex_ohlcv_data end do
          data = StockQuote.ohlcv_3mo(aapl)
          assert Enum.count(data) == 4
          assert called(IexcloudClient.historical_prices("AAPL", "3m"))

          refute_enqueued(
            worker: Flowscan.Workers.StockQuoteOhlcv,
            args: %{symbol_id: aapl.id, range: "5d"}
          )
        end
      end
    end

    test "ohlcv_3mo/1 fetched five days worth of data when it's recently stale", %{
      aapl: aapl
    } do
      with_mock MarketHours, previous_trading_day: fn -> ~D[2021-06-04] end do
        with_mock IexcloudClient,
          historical_prices: fn _symbol, _range -> @iex_ohlcv_data end do
          insert(:symbol_ohlcv, symbol: aapl, date: ~D[2021-06-01])
          data = StockQuote.ohlcv_3mo(aapl)
          assert Enum.count(data) == 4
          assert called(IexcloudClient.historical_prices("AAPL", "5d"))

          # assert_enqueued(
          # worker: Flowscan.Workers.StockQuoteOhlcv,
          # args: %{symbol_id: aapl.id, range: "5d"}
          # )
        end
      end
    end

    test "cached_fresh_quote/1 returns latest quote when there is one" do
      assert StockQuote.cached_fresh_quote("nio") == nil
      StockQuote.set_cached_fresh_quote("NiO", 200.71)
      assert StockQuote.cached_fresh_quote("NIO") == 200.71
    end

    test "fresh_quotes_for_tickers/1 calls IEx for any missing quotes and returns cached+newly retrieved" do
      with_mock Flowscan.Integrations.IexcloudClient,
        batch_quotes: fn _tickers -> {:ok, @iexcloud_batch_quotes_reponse} end do
        StockQuote.set_cached_fresh_quote("NIO", 200.71)

        assert StockQuote.fresh_quotes_for_tickers(["AAPL", "AMZN", "NIO"]) == %{
                 "AAPL" => 118.01,
                 "AMZN" => 3074.96,
                 "NIO" => 200.71
               }
      end
    end
  end

  defp clear_cache(_) do
    Cachex.reset(:data)
    :ok
  end

  defp setup_factories(_) do
    %{
      aapl: insert(:symbol, symbol: "AAPL")
    }
  end
end
