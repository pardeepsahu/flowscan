defmodule Flowscan.WatchlistTest do
  @moduledoc false
  use Flowscan.DataCase

  describe "watchlist" do
    alias Flowscan.Watchlist

    test "notification_user_ids_for_symbol_id/1 returns watching users with watchlist notificiations enabled" do
      symbol = Factory.insert(:symbol)
      free_user_one = Factory.insert(:user, is_plus: false, notifications_watchlist: true)
      free_user_two = Factory.insert(:user, is_plus: false, notifications_watchlist: true)
      free_user_three = Factory.insert(:user, is_plus: false, notifications_watchlist: false)
      plus_user = Factory.insert(:user, is_plus: true, notifications_watchlist: true)

      Factory.insert(:watchlist, symbol: symbol, user: free_user_one)
      Factory.insert(:watchlist, symbol: symbol, user: free_user_two)
      Factory.insert(:watchlist, symbol: symbol, user: free_user_three)
      Factory.insert(:watchlist, symbol: symbol, user: plus_user)
      Factory.insert(:watchlist)

      assert Enum.count(Watchlist.notification_user_ids_for_symbol_id(symbol.id)) == 3
      assert Enum.count(Watchlist.notification_user_ids_for_symbol_id(symbol.id, true)) == 1
    end
  end
end
