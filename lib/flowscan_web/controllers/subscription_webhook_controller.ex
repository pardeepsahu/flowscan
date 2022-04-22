defmodule FlowscanWeb.SubscriptionWebhookController do
  use FlowscanWeb, :controller
  alias Flowscan.Services.Subscriptions
  alias Flowscan.SubscriptionEvent
  alias Flowscan.User
  require Logger

  def event(conn, data) do
    auth_header = hd(get_req_header(conn, "authorization"))

    if auth_header == valid_auth_header() do
      SubscriptionEvent.create(data["event_name"], data)

      # TODO: Introduce Oban and process in a queue
      qonversion_user_id = data["user_id"]
      user_id = data["custom_user_id"]

      if user_id do
        user = User.find_by_id(user_id)

        if user do
          Logger.info("SubscriptionWebhookController: Updating Qonversion data",
            user_id: user.id,
            qonversion_user_id: qonversion_user_id
          )

          Subscriptions.update_qonversion_data(user, qonversion_user_id)
        end
      end

      json(conn, %{ok: true})
    else
      Logger.error("SubscriptionWebhookController accessed with invalid auth header")

      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    end
  end

  defp valid_auth_header do
    subscription_webhook_token =
      Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:subscription_webhook_token]

    "Basic #{subscription_webhook_token}"
  end
end
