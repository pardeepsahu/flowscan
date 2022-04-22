defmodule FlowscanWeb.Graphql.PushTokenTest do
  use FlowscanWeb.ConnCase
  import Flowscan.AbsintheHelpers
  import Ecto.Query
  alias Flowscan.PushToken
  alias Flowscan.Repo

  setup [:setup_factories]

  @push_token_mutation """
  mutation pushToken($onesignalPlayerId: String!) {
    pushToken(onesignalPlayerId: $onesignalPlayerId) {
      ok
    }
  }
  """

  @delete_token_mutation """
  mutation deletePushToken($onesignalPlayerId: String!) {
    deletePushToken(onesignalPlayerId: $onesignalPlayerId) {
      ok
    }
  }
  """

  @sample_player_id "f5fedbdd-f5b6-4083-86ec-068e66d234ef"

  test "anonymous user push token", %{conn: conn} do
    res =
      conn
      |> graphql(query(@push_token_mutation, %{onesignalPlayerId: @sample_player_id}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"

    assert PushToken |> where(onesignal_player_id: @sample_player_id) |> Repo.all() |> length() ==
             0
  end

  test "authenticated user push token", %{conn: conn, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@push_token_mutation, %{onesignalPlayerId: @sample_player_id}))

    assert json_response(res, 200)["data"]["pushToken"]["ok"] == true

    assert PushToken
           |> where(
             user_id: ^free_user.id,
             onesignal_player_id: @sample_player_id
           )
           |> Repo.all()
           |> length() == 1
  end

  test "multiple tokens for the same user", %{conn: conn, free_user: free_user} do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@push_token_mutation, %{onesignalPlayerId: @sample_player_id}))

    assert json_response(res, 200)["data"]["pushToken"]["ok"] == true

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(
        query(@push_token_mutation, %{onesignalPlayerId: "f5fedbdd-f5b6-4083-86ec-068e66d234gg"})
      )

    assert json_response(res, 200)["data"]["pushToken"]["ok"] == true

    assert PushToken |> where(user_id: ^free_user.id) |> Repo.all() |> length() == 2
  end

  test "reclaiming token as another user", %{conn: conn, free_user: free_user} do
    another_user = insert(:user)
    token = insert(:push_token, user: another_user)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@push_token_mutation, %{onesignalPlayerId: token.onesignal_player_id}))

    assert json_response(res, 200)["data"]["pushToken"]["ok"] == true

    assert PushToken
           |> where(user_id: ^free_user.id, onesignal_player_id: ^token.onesignal_player_id)
           |> Repo.all()
           |> length() == 1

    assert PushToken
           |> where(onesignal_player_id: ^token.onesignal_player_id)
           |> Repo.all()
           |> length() == 1
  end

  test "deleting token (logout)", %{
    conn: conn,
    free_user: free_user
  } do
    insert(:push_token, user: free_user, onesignal_player_id: @sample_player_id)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@delete_token_mutation, %{onesignalPlayerId: @sample_player_id}))

    assert json_response(res, 200)["data"]["deletePushToken"]["ok"] == true

    assert PushToken
           |> Repo.all()
           |> length() == 0
  end

  test "deleting token when there isn't one", %{
    conn: conn,
    free_user: free_user
  } do
    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@delete_token_mutation, %{onesignalPlayerId: @sample_player_id}))

    assert json_response(res, 200)["data"]["deletePushToken"]["ok"] == true
  end

  test "deleting token when not authenticated", %{
    conn: conn,
    free_user: free_user
  } do
    insert(:push_token, user: free_user, onesignal_player_id: @sample_player_id)

    res =
      conn
      |> graphql(query(@delete_token_mutation, %{onesignalPlayerId: @sample_player_id}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"

    assert PushToken
           |> Repo.all()
           |> length() == 1
  end

  defp setup_factories(_) do
    %{
      free_user: insert(:user, is_plus: false)
    }
  end

  # This should be moved out to helpers
  defp graphql(conn, query) do
    conn |> post("/graphql", query)
  end
end
