defmodule FlowscanWeb.SubscriptionWebhookControllerTest do
  use FlowscanWeb.ConnCase
  alias Flowscan.Services
  import Mock

  @subscription_renewed_event Poison.decode!("""
                              {
                                "time": 1610895731,
                                "revenue": {
                                  "value": 28.0415,
                                  "currency": "EUR",
                                  "value_usd": 33.8725
                                },
                                "user_id": "6UFJilrfdSeCvF4QHbCQ6ZihWjI6Vql5",
                                "device_id": "043079A9-FE33-4FCA-85B9-048860960B06",
                                "event_name": "subscription_renewed",
                                "product_id": "pro_monthly_29_7d_trial",
                                "properties": {
                                  "_q_custom_user_id": "7847778b-a3e7-4de9-a918-6023c3fa5eec"
                                },
                                "advertiser_id": null,
                                "custom_user_id": "7847778b-a3e7-4de9-a918-6023c3fa5eec"
                              }
                              """)

  describe "event" do
    setup_with_mocks([
      {Services.Subscriptions, [],
       update_qonversion_data: fn _user, _qonversion_user_id ->
         :ok
       end}
    ]) do
      qonversion_user_id = "6UFJilrfdSeCvF4QHbCQ6ZihWjI6Vql5"

      {:ok, qonversion_user_id: qonversion_user_id}
    end

    test "updates Qonversion data when the user exists", %{
      conn: conn,
      qonversion_user_id: qonversion_user_id
    } do
      user =
        insert(:user,
          id: "7847778b-a3e7-4de9-a918-6023c3fa5eec",
          qonversion_user_id: qonversion_user_id
        )

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Basic xxx")
        |> post(Routes.subscription_webhook_path(conn, :event), @subscription_renewed_event)

      body = json_response(conn, 200)
      assert body == %{"ok" => true}

      assert called(
               Services.Subscriptions.update_qonversion_data(
                 :meck.is(fn called_user ->
                   assert called_user.__struct__ == Flowscan.User
                   assert called_user.id == user.id
                   true
                 end),
                 qonversion_user_id
               )
             )
    end

    test "doesn't throw an error when the user is not found", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Basic xxx")
        |> post(Routes.subscription_webhook_path(conn, :event), @subscription_renewed_event)

      body = json_response(conn, 200)
      assert body == %{"ok" => true}

      refute called(Services.Subscriptions.update_qonversion_data(:_, :_))
    end

    test "returns an error if the auth header is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Basic invalidtoken")
        |> post(Routes.subscription_webhook_path(conn, :event), @subscription_renewed_event)

      assert response(conn, 401) =~ "unauthorized"
    end
  end
end
