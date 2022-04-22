defmodule Flowscan.Services.ExpiredPlusJanitor do
  @moduledoc false

  require Logger
  alias Flowscan.Services.Subscriptions
  alias Flowscan.User

  def run do
    expired_users = User.expired_plus_users()

    # Update Qonversion data for all that have Qonversion id
    expired_users
    |> Enum.filter(fn user -> !is_nil(user.qonversion_user_id) end)
    |> Enum.each(fn user ->
      Logger.info("ExpiredPlusJanitor: Updating Qonversion data",
        user_id: user.id,
        qonversion_user_id: user.qonversion_user_id
      )

      Subscriptions.update_qonversion_data(user, user.qonversion_user_id)
    end)

    expired_users = User.expired_plus_users()

    expired_users
    |> Enum.each(fn user ->
      Logger.info("Disabling expired pro subscription for user #{user.id}", %{
        plus_expires_at: user.plus_expires_at
      })

      user |> User.expire_plus_subscription()
    end)
  end
end
