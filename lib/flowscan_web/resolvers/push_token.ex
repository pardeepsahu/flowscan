defmodule FlowscanWeb.Resolvers.PushToken do
  @moduledoc false
  alias Flowscan.PushToken
  alias Flowscan.Repo
  require Logger

  def update(_parent, %{onesignal_player_id: onesignal_player_id}, %{
        context: %{current_user: current_user}
      }) do
    update_push_token(onesignal_player_id, current_user)
  end

  def update(_parent, _params, _context) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def delete(_parent, %{onesignal_player_id: onesignal_player_id}, %{
        context: %{current_user: current_user}
      }) do
    delete_push_token(onesignal_player_id, current_user)
  end

  def delete(_parent, _params, _context) do
    {:error, "NOT_AUTHENTICATED"}
  end

  defp update_push_token(onesignal_player_id, user) do
    token =
      case PushToken.find_by_onesignal_player_id(onesignal_player_id) |> Repo.preload(:user) do
        existing_token = %PushToken{} ->
          if !is_nil(existing_token.user_id) and !is_nil(user) and
               existing_token.user_id != user.id do
            Logger.warn("Updating push token with mismatching users (id=#{existing_token.id})")
          end

          existing_token

        nil ->
          %PushToken{}
      end

    {:ok, _result} =
      token
      |> PushToken.changeset(%{
        onesignal_player_id: onesignal_player_id,
        user_id: user.id
      })
      |> Repo.insert_or_update()

    {:ok, %{ok: true}}
  end

  defp delete_push_token(onesignal_player_id, user) do
    PushToken.delete(onesignal_player_id, user.id)
    {:ok, %{ok: true}}
  end
end
