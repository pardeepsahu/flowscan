defmodule Flowscan.Services.Subscriptions do
  @moduledoc false
  require Logger
  alias Flowscan.AuditLog
  alias Flowscan.Integrations.QonversionClient
  alias Flowscan.User

  # Note: seeing is_active=1 on an expired subscription, but seems to go away after a while. Test.

  @plus_entitlement "Plus"

  def verify_user_subscription(%User{} = user, qonversion_user_id) do
    update_qonversion_data(user, qonversion_user_id)
  end

  def update_qonversion_data(%User{} = user, qonversion_user_id) do
    qonversion_user_data =
      case QonversionClient.get_user(qonversion_user_id, false) do
        {:ok, data} ->
          data

        {:error, :not_found} ->
          Logger.warn("Retrying on Qonversion sandbox for user #{qonversion_user_id}")
          {:ok, sandbox_data} = QonversionClient.get_user(qonversion_user_id, true)
          sandbox_data
      end

    AuditLog.create(user, "qonversion_get_user", qonversion_user_data)

    # Update subscriptions table with the latest entitlement / purchase
    entitlement =
      Enum.find(qonversion_user_data["entitlements"], fn e ->
        e["entitlement"] == @plus_entitlement
      end)

    is_active = entitlement["active"]
    Logger.info("Subscription entitlement status is #{is_active}")

    user = update_user(user, entitlement)
    user
  end

  defp update_user(%User{} = user, entitlement) do
    is_plus = entitlement["active"] == 1
    plus_started_at = unix_to_datetime(entitlement["started"])
    plus_expires_at = unix_to_datetime(entitlement["expires"])
    qonversion_user_id = entitlement["user"]

    user
    |> User.update_plus_subscription(
      is_plus,
      plus_started_at,
      plus_expires_at,
      qonversion_user_id
    )
  end

  defp unix_to_datetime(nil) do
    nil
  end

  defp unix_to_datetime(unix_timestamp) do
    {:ok, dt} = DateTime.from_unix(unix_timestamp)
    dt
  end
end
