defmodule FlowscanWeb.AuthTest do
  @moduledoc false
  use Flowscan.DataCase
  alias Flowscan.Repo
  alias Flowscan.User
  alias FlowscanWeb.Auth

  @claims %{
    "iss" => "https://appleid.apple.com",
    "aud" => "com.nodehub.flowscan",
    "exp" => 1_610_224_174,
    "iat" => 1_610_137_774,
    "sub" => "000880.01ce567de74242f8b8301ff8df4c9637.2325",
    "nonce" => "e3e647f8b2aeb9aa955acb507880ca11b09266042dcd5465dcf2299c03b1218a",
    "c_hash" => "E7pUiOkWJvTbjwqmHRHtWA",
    "email" => "m@sandis.lv",
    "email_verified" => "true",
    "auth_time" => 1_610_137_774,
    "nonce_supported" => true
  }

  # TODO: Also needs GQL tests
  describe "auth" do
    test "sign_in_with_apple/1 creates an account if user doesn't exist" do
      {:ok, user} = Auth.sign_in_with_apple(@claims)
      assert String.length(user.token) > 0
      assert String.length(user.refresh_token) > 0
      assert user.is_sign_in_with_apple
      assert user.federated_user_id == @claims["sub"]
      user = Repo.get_by(User, email: @claims["email"])
      assert user.email == @claims["email"]
      refute user.is_tos_accepted
    end

    test "sign_in_with_apple/1 matches an existing Apple account, even if the email is different" do
      og_user =
        Factory.insert(:user,
          email: "something@else.example",
          is_sign_in_with_apple: true,
          federated_user_id: @claims["sub"]
        )

      {:ok, user} = Auth.sign_in_with_apple(@claims)
      assert String.length(user.token) > 0
      assert String.length(user.refresh_token) > 0
      assert user.is_sign_in_with_apple
      assert user.federated_user_id == @claims["sub"]
      assert User.find_by_id(og_user.id).email == "something@else.example"
      assert length(Repo.all(User)) == 1
    end

    test "sign_in_with_apple/1 matches an existing account by email, if it's not a sign in with Apple account" do
      og_user =
        Factory.insert(:user,
          email: "m@sandis.lv"
        )

      {:ok, user} = Auth.sign_in_with_apple(@claims)
      assert String.length(user.token) > 0
      assert String.length(user.refresh_token) > 0
      assert user.is_sign_in_with_apple
      assert user.federated_user_id == @claims["sub"]
      assert User.find_by_id(og_user.id).email == og_user.email
      assert length(Repo.all(User)) == 1
    end
  end
end
