defmodule Flowscan.PushTokenTest do
  @moduledoc false
  use Flowscan.DataCase

  describe "push_tokens" do
    alias Flowscan.PushToken

    test "onesignal_player_ids_for_user_ids/1 returns the correct player ids" do
      test_user_one = Factory.insert(:user)
      test_user_two = Factory.insert(:user)
      Factory.insert_list(2, :push_token, user: test_user_one)
      token_for_user_two = Factory.insert(:push_token, user: test_user_two)
      some_other_token = Factory.insert(:push_token)

      tokens_to_test =
        PushToken.onesignal_player_ids_for_user_ids([test_user_one.id, test_user_two.id])

      assert length(tokens_to_test) == 3
      assert Enum.member?(tokens_to_test, token_for_user_two.onesignal_player_id)
      refute Enum.member?(tokens_to_test, some_other_token.onesignal_player_id)
    end
  end
end
