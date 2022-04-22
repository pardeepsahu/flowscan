defmodule Flowscan.Services.SubscriptionsTest do
  @moduledoc false
  use Flowscan.DataCase
  import Mock
  alias Flowscan.AuditLog
  alias Flowscan.Repo
  alias Flowscan.Services
  alias Flowscan.User

  setup [:setup_factories]

  @qonversion_active_response Poison.decode!("""
                              {
                                "data": {
                                  "object": "user",
                                  "id": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                  "created": 1610207106,
                                  "last_online": 1612974442,
                                  "entitlements": [
                                      {
                                          "object": "user_entitlement",
                                          "entitlement": "Plus",
                                          "active": 1,
                                          "started": 1610207553,
                                          "expires": 2114380800,
                                          "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                          "purchases": [
                                              {
                                                  "object": "purchase",
                                                  "platform": "app_store",
                                                  "platform_product_id": "pro_monthly_29_7d_trial",
                                                  "original_id": "1000000763021831",
                                                  "currency": "EUR",
                                                  "amount": 32.99,
                                                  "purchased": null,
                                                  "created": 1610207556,
                                                  "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                  "product": "pro_monthly_29_7d_trial"
                                              }
                                          ]
                                      }
                                  ],
                                  "purchases": [
                                      {
                                          "object": "purchase",
                                          "platform": "app_store",
                                          "platform_product_id": "pro_monthly_29_7d_trial",
                                          "original_id": "1000000763021831",
                                          "currency": "EUR",
                                          "amount": 32.99,
                                          "purchased": null,
                                          "created": 1610207556,
                                          "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                          "product": "pro_monthly_29_7d_trial"
                                      }
                                  ]
                                },
                                "_meta": null
                              }
                              """)

  @qonversion_inactive_entitlement_fragment Poison.decode!("""
                                                {
                                                  "object": "user_entitlement",
                                                  "entitlement": "Plus",
                                                  "active": 0,
                                                  "started": 1610207553,
                                                  "expires": 1612970747,
                                                  "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                  "purchases": [
                                                      {
                                                          "object": "purchase",
                                                          "platform": "app_store",
                                                          "platform_product_id": "pro_monthly_29_7d_trial",
                                                          "original_id": "1000000763021831",
                                                          "currency": "EUR",
                                                          "amount": 32.99,
                                                          "purchased": null,
                                                          "created": 1610207556,
                                                          "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                          "product": "pro_monthly_29_7d_trial"
                                                      }
                                                  ]
                                              }
                                            """)

  @qonversion_extend_active_entitlement_fragment Poison.decode!("""
                                                    {
                                                      "object": "user_entitlement",
                                                      "entitlement": "Plus",
                                                      "active": 1,
                                                      "started": 1610207553,
                                                      "expires": 2114380800,
                                                      "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                      "purchases": [
                                                          {
                                                              "object": "purchase",
                                                              "platform": "app_store",
                                                              "platform_product_id": "pro_monthly_29_7d_trial",
                                                              "original_id": "1000000763021831",
                                                              "currency": "EUR",
                                                              "amount": 32.99,
                                                              "purchased": null,
                                                              "created": 1610207556,
                                                              "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                              "product": "pro_monthly_29_7d_trial"
                                                          }
                                                      ]
                                                    }
                                                 """)

  @qonversion_active_but_expired_entitlement_fragment Poison.decode!("""
                                                      {
                                                        "object": "user_entitlement",
                                                        "entitlement": "Plus",
                                                        "active": 1,
                                                        "started": 1610207553,
                                                        "expires": 1612970747,
                                                        "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                        "purchases": [
                                                            {
                                                                "object": "purchase",
                                                                "platform": "app_store",
                                                                "platform_product_id": "pro_monthly_29_7d_trial",
                                                                "original_id": "1000000763021831",
                                                                "currency": "EUR",
                                                                "amount": 32.99,
                                                                "purchased": null,
                                                                "created": 1610207556,
                                                                "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                                "product": "pro_monthly_29_7d_trial"
                                                            }
                                                        ]
                                                      }
                                                      """)

  describe "Subscriptions" do
    test "verify_user_subscription/2 with an active non-expired entitlement updates subscriptions and user",
         %{
           free_user: user
         } do
      with_mock Flowscan.Integrations.QonversionClient,
        get_user: fn _user_id, _sandbox -> {:ok, @qonversion_active_response["data"]} end do
        qonversion_user_id = @qonversion_active_response["data"]["id"]

        Services.Subscriptions.verify_user_subscription(user, qonversion_user_id)

        # Verify is_plus, start and exp times and Qonversion user id are set
        user = Repo.get(User, user.id)
        assert user.is_plus
        assert user.plus_started_at == ~U[2021-01-09 15:52:33Z]
        assert user.plus_expires_at == ~U[2037-01-01 00:00:00Z]
        assert user.qonversion_user_id == qonversion_user_id

        assert Repo.get_by(AuditLog,
                 user_id: user.id,
                 type: "qonversion_get_user"
               )
      end
    end

    test "update_qonversion_data/2 marks an non-active Qonversion pro user inactive", %{
      plus_user: user
    } do
      response =
        @qonversion_active_response
        |> put_in(["data", "entitlements"], [@qonversion_inactive_entitlement_fragment])

      with_mock Flowscan.Integrations.QonversionClient,
        get_user: fn _user_id, _sandbox -> {:ok, response["data"]} end do
        qonversion_user_id = response["data"]["id"]
        Services.Subscriptions.update_qonversion_data(user, qonversion_user_id)
        user = Repo.get(User, user.id)
        refute user.is_plus
      end
    end
  end

  test "update_qonversion_data/2 extends existing subscriptions", %{
    plus_user: user
  } do
    response =
      @qonversion_active_response
      |> put_in(["data", "entitlements"], [
        @qonversion_extend_active_entitlement_fragment
      ])

    insert(:subscription, user: user, qonversion_purchase_original_id: "1000000763021831")

    with_mock Flowscan.Integrations.QonversionClient,
      get_user: fn _user_id, _sandbox -> {:ok, response["data"]} end do
      qonversion_user_id = response["data"]["id"]
      Services.Subscriptions.update_qonversion_data(user, qonversion_user_id)

      user = Repo.get(User, user.id)
      assert user.is_plus
      assert user.plus_started_at == ~U[2021-01-09 15:52:33Z]
      assert user.plus_expires_at == ~U[2037-01-01 00:00:00Z]
    end
  end

  test "update_qonversion_data/2 keeps is_plus active if Q returns is_active but expiry date is past",
       %{
         plus_user: user
       } do
    response =
      @qonversion_active_response
      |> put_in(["data", "entitlements"], [@qonversion_active_but_expired_entitlement_fragment])

    with_mock Flowscan.Integrations.QonversionClient,
      get_user: fn _user_id, _sandbox -> {:ok, response["data"]} end do
      qonversion_user_id = response["data"]["id"]
      Services.Subscriptions.update_qonversion_data(user, qonversion_user_id)

      user = Repo.get(User, user.id)
      assert user.is_plus
    end
  end

  defp setup_factories(_) do
    %{
      free_user: insert(:user, is_plus: false),
      plus_user:
        insert(:user,
          is_plus: true,
          qonversion_user_id: "some-sort-of-user-id"
        )
    }
  end
end
