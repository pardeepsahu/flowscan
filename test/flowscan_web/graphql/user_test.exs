defmodule FlowscanWeb.Graphql.UserTest do
  @moduledoc false
  use FlowscanWeb.ConnCase
  use Bamboo.Test
  import Flowscan.AbsintheHelpers
  import Mock
  alias Ecto.UUID
  alias Flowscan.{Guardian, Repo, User, UserMeta}
  alias FlowscanWeb.Auth

  @current_user_query """
  query currentUser {
    currentUser {
      id
      email
      isPlus
      hasBeenPlus
    }
  }
  """

  @auth_mutation """
  mutation ($email: String!, $password: String!) {
    authenticate(email: $email, password: $password) {
      id
      email
      isPlus
      token
      refreshToken
      isTosAccepted
    }
  }
  """

  @signup_mutation """
  mutation ($email: String!, $password: String!, $platform: String) {
    signup(email: $email, password: $password, platform: $platform) {
      id
      email
      isPlus
      token
      refreshToken
      isTosAccepted
    }
  }
  """

  @refresh_token_mutation """
  mutation ($refreshToken: String!) {
    refreshToken(refreshToken: $refreshToken) {
      id
      email
      isPlus
      token
      refreshToken
    }
  }
  """

  @request_password_reset_mutation """
  mutation ($email: String!) {
    requestPasswordReset(email: $email) {
      ok
    }
  }
  """

  @password_reset_mutation """
  mutation ($password_reset_token: String!, $password: String!) {
    passwordReset(password_reset_token: $password_reset_token, password: $password) {
      id
      token
      refreshToken
    }
  }
  """

  @notification_settings_query """
  query notificationSettings {
    notificationSettings {
      notificationsWatchlist
      notificationsHighlights
    }
  }
  """

  @update_notification_settings_mutation """
  mutation updateNotificationSettings ($notificationsWatchlist: Boolean!, $notificationsHighlights: Boolean!) {
    updateNotificationSettings(notificationsWatchlist: $notificationsWatchlist, notificationsHighlights: $notificationsHighlights) {
      notificationsWatchlist
      notificationsHighlights
    }
  }
  """

  @sign_in_with_apple_mutation """
  mutation signInWithApple($identityToken: String!) {
    signInWithApple(identityToken: $identityToken) {
      id
      email
      isPlus
      token
      refreshToken
      isTosAccepted
    }
  }
  """

  @verify_user_subscription_mutation """
  mutation verifyUserSubscription($qonversionUserId: String!) {
    verifyUserSubscription(qonversionUserId: $qonversionUserId) {
      isPlus
    }
  }
  """

  @accept_tos_mutation """
  mutation acceptTos {
    acceptTos {
      isTosAccepted
    }
  }
  """

  @meta_query """
  query userMeta {
    userMeta {
      showRatePrompt
    }
  }
  """

  @meta_interaction_mutation """
  mutation userMetaInteraction($interaction: String!) {
    userMetaInteraction(interaction: $interaction) {
        showRatePrompt
    }
  }
  """

  @qonversion_active_entitlement_response Poison.decode!("""
                                          {
                                            "data": {
                                                "object": "user",
                                                "id": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                "created": 1610207106,
                                                "last_online": 1610231711,
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
                                                                "purchase_token": "MIIyuQ...",
                                                                "platform": "app_store",
                                                                "platform_product_id": "pro_monthly_29_7d_trial",
                                                                "original_id": "1000000763021831",
                                                                "currency": "EUR",
                                                                "amount": 32.99,
                                                                "purchased": null,
                                                                "created": 1610207556,
                                                                "user": "7847778b-a3e7-4de9-a918-6023c3fa5eec",
                                                                "product": {
                                                                    "product_id": "pro_monthly_29_7d_trial",
                                                                    "type": null,
                                                                    "currency": "EUR",
                                                                    "price": 32.99,
                                                                    "introductory_price": null,
                                                                    "introductory_payment_mode": null,
                                                                    "introductory_duration": null,
                                                                    "subscription": {
                                                                        "period_duration": null,
                                                                        "started": 1610207553,
                                                                        "current_period_start": 1610231448,
                                                                        "current_period_end": 1610231748,
                                                                        "current_period_type": "normal",
                                                                        "renew_state": "will_renew"
                                                                    },
                                                                    "object": "product"
                                                                }
                                                            }
                                                        ]
                                                    }
                                                ]
                                            },
                                            "_meta": null
                                          }
                                          """)

  test "retrieve current user", %{conn: conn} do
    user = insert(:user)

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@current_user_query))

    current_user = json_response(res, 200)["data"]["currentUser"]
    assert current_user["email"] == user.email
  end

  test "unauthenticated user gets an error", %{conn: conn} do
    res =
      conn
      |> graphql(query(@current_user_query))

    response = json_response(res, 200)
    assert response["data"]["currentUser"] == nil
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "authenticate", %{conn: conn} do
    user = insert(:user, Argon2.add_hash("berger12"))

    res =
      conn
      |> graphql(
        query(@auth_mutation, %{
          "email" => user.email,
          "password" => "berger12"
        })
      )

    response = json_response(res, 200)
    assert response["data"]["authenticate"]["email"] == user.email
    assert String.length(response["data"]["authenticate"]["token"]) > 0
    assert String.length(response["data"]["authenticate"]["refreshToken"]) > 0
    refute response["data"]["authenticate"]["isTosAccepted"]
  end

  test "authenticate using username/password even if user used Apple", %{conn: conn} do
    user = insert(:user, Argon2.add_hash("berger12"))

    res =
      conn
      |> graphql(
        query(@auth_mutation, %{
          "email" => user.email,
          "password" => "berger12"
        })
      )

    response = json_response(res, 200)
    assert response["data"]["authenticate"]["email"] == user.email

    User.create_apple_user("something", user.email)

    res =
      conn
      |> graphql(
        query(@auth_mutation, %{
          "email" => user.email,
          "password" => "berger12"
        })
      )

    response = json_response(res, 200)
    assert String.length(response["data"]["authenticate"]["token"]) > 0
    assert String.length(response["data"]["authenticate"]["refreshToken"]) > 0
    assert length(Repo.all(User)) == 1
  end

  test "authenticate with invalid password", %{conn: conn} do
    user = insert(:user, Argon2.add_hash("berger12"))

    res =
      conn
      |> graphql(
        query(@auth_mutation, %{
          "email" => user.email,
          "password" => "Berger12"
        })
      )

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "Invalid email or password"
  end

  test "sign up", %{conn: conn} do
    res =
      conn
      |> graphql(
        query(@signup_mutation, %{
          "email" => Faker.Internet.email(),
          "password" => "qwerty"
        })
      )

    response = json_response(res, 200)
    assert String.length(response["data"]["signup"]["token"]) > 0
    assert String.length(response["data"]["signup"]["refreshToken"]) > 0
    assert response["data"]["signup"]["isTosAccepted"]
    assert User.find_by_email(response["data"]["signup"]["email"])
  end

  test "sign up with platform specified", %{conn: conn} do
    res =
      conn
      |> graphql(
        query(@signup_mutation, %{
          "email" => Faker.Internet.email(),
          "password" => "qwerty",
          "platform" => "android"
        })
      )

    response = json_response(res, 200)
    assert String.length(response["data"]["signup"]["token"]) > 0
  end

  test "sign up when the email already exists", %{conn: conn} do
    user = insert(:user)

    res =
      conn
      |> graphql(
        query(@signup_mutation, %{
          "email" => user.email,
          "password" => "qwerty"
        })
      )

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "User already exists"
  end

  test "sign up with invalid email", %{conn: conn} do
    res =
      conn
      |> graphql(
        query(@signup_mutation, %{
          "email" => "bruh.com",
          "password" => "qwerty"
        })
      )

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "Invalid e-mail address"
  end

  test "sign up with empty password", %{conn: conn} do
    res =
      conn
      |> graphql(
        query(@signup_mutation, %{
          "email" => "joe@example.com",
          "password" => ""
        })
      )

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "Password can't be empty"
  end

  test "refresh token", %{conn: conn} do
    user = Auth.user_with_tokens(insert(:user))

    res =
      conn
      |> graphql(query(@refresh_token_mutation, %{"refreshToken" => user.refresh_token}))

    response = json_response(res, 200)
    assert String.length(response["data"]["refreshToken"]["token"]) > 0
    assert String.length(response["data"]["refreshToken"]["refreshToken"]) > 0
  end

  test "expired access token", %{conn: conn} do
    user = insert(:user)

    {:ok, token, _claims} =
      Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {-5, :minutes})

    res =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> graphql(query(@current_user_query))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "expired refresh token", %{conn: conn} do
    user = insert(:user)

    {:ok, refresh_token, _claims} =
      Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {-5, :minutes})

    res =
      conn
      |> graphql(query(@refresh_token_mutation, %{"refreshToken" => refresh_token}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "TOKEN_EXPIRED"
  end

  test "has_been_plus", %{conn: conn} do
    user = insert(:user)

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@current_user_query))

    response = json_response(res, 200)
    refute response["data"]["currentUser"]["hasBeenPlus"]

    user = insert(:user, plus_started_at: ~U[2021-01-23 17:47:00Z])

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@current_user_query))

    response = json_response(res, 200)
    assert response["data"]["currentUser"]["hasBeenPlus"]
  end

  test "password reset end to end", %{conn: conn} do
    user = insert(:user)
    og_password_hash = user.password_hash

    res =
      conn
      |> graphql(
        query(@request_password_reset_mutation, %{
          "email" => user.email
        })
      )

    response = json_response(res, 200)
    assert response["data"]["requestPasswordReset"]["ok"]

    user = Repo.get(User, user.id)
    expected_email = Flowscan.Email.password_reset_email(user)
    assert_delivered_email(expected_email)

    res =
      conn
      |> graphql(
        query(@password_reset_mutation, %{
          "password_reset_token" => user.password_reset_token,
          "password" => "newpass2020"
        })
      )

    response = json_response(res, 200)
    assert response["data"]["passwordReset"]["id"] == user.id
    assert String.length(response["data"]["passwordReset"]["token"]) > 0
    assert String.length(response["data"]["passwordReset"]["refreshToken"]) > 0
    user = Repo.get(User, user.id)
    assert user.password_reset_token == nil
    assert user.password_hash != og_password_hash
  end

  test "request password reset for non-existent user", %{conn: conn} do
    res =
      conn
      |> graphql(
        query(@request_password_reset_mutation, %{
          "email" => "totally.made.up@example.com"
        })
      )

    response = json_response(res, 200)
    assert response["data"]["requestPasswordReset"]["ok"]
  end

  test "password reset with expired token", %{conn: conn} do
    token = UUID.generate()
    expires_at = DateTime.utc_now() |> Timex.shift(minutes: -10)
    insert(:user, password_reset_token: token, password_reset_token_expires_at: expires_at)

    res =
      conn
      |> graphql(
        query(@password_reset_mutation, %{
          "password_reset_token" => token,
          "password" => "newpass2020"
        })
      )

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "Invalid or expired password reset token"
  end

  test "password reset with invalid password", %{conn: conn} do
    token = UUID.generate()
    expires_at = DateTime.utc_now() |> Timex.shift(minutes: 10)
    insert(:user, password_reset_token: token, password_reset_token_expires_at: expires_at)

    res =
      conn
      |> graphql(
        query(@password_reset_mutation, %{
          "password_reset_token" => token,
          "password" => "kk"
        })
      )

    response = json_response(res, 200)
    assert hd(response["errors"])["field"] == "password"
    assert hd(response["errors"])["message"] == "The password is too short"
  end

  test "retrieve notification settings for user", %{
    conn: conn
  } do
    user = insert(:user)

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@notification_settings_query))

    data = json_response(res, 200)["data"]["notificationSettings"]
    assert data == %{"notificationsHighlights" => true, "notificationsWatchlist" => true}
  end

  test "updating notification settings for user", %{
    conn: conn
  } do
    user = insert(:user, notifications_highlights: false, notifications_watchlist: true)

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(
        query(@update_notification_settings_mutation, %{
          "notificationsHighlights" => true,
          "notificationsWatchlist" => false
        })
      )

    data = json_response(res, 200)["data"]["updateNotificationSettings"]
    assert data == %{"notificationsHighlights" => true, "notificationsWatchlist" => false}
    user = Repo.get(User, user.id)
    assert user.notifications_highlights
    refute user.notifications_watchlist
  end

  test "verifying subscription for a free user", %{
    conn: conn
  } do
    user = insert(:user, is_plus: false)

    with_mock Flowscan.Integrations.QonversionClient,
      get_user: fn _user_id, _sandbox ->
        {:ok, @qonversion_active_entitlement_response["data"]}
      end do
      res =
        conn
        |> authenticate_conn(user)
        |> graphql(
          query(@verify_user_subscription_mutation, %{
            "qonversionUserId" => "some-random-id"
          })
        )

      data = json_response(res, 200)["data"]["verifyUserSubscription"]
      assert data == %{"isPlus" => true}
      user = Repo.get(User, user.id)
      assert user.is_plus
    end
  end

  test "rate prompt meta", %{conn: conn} do
    user = insert(:user)

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@meta_query))

    data = json_response(res, 200)["data"]["userMeta"]
    assert data["showRatePrompt"] == false

    meta = Repo.get(UserMeta, user.id)
    assert meta.rate_prompt == :hide

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(
        query(@meta_interaction_mutation, %{
          "interaction" => "rate_prompt_shown"
        })
      )

    data = json_response(res, 200)["data"]["userMetaInteraction"]
    assert data["showRatePrompt"] == false
    meta = Repo.get(UserMeta, user.id)
    assert meta.rate_prompt == :rated

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(
        query(@meta_interaction_mutation, %{
          "interaction" => "rate_prompt_dismissed"
        })
      )

    data = json_response(res, 200)["data"]["userMetaInteraction"]
    assert data["showRatePrompt"] == false
    meta = Repo.get(UserMeta, user.id)
    assert meta.rate_prompt == :dismissed
  end

  test "end to end", %{conn: conn} do
    email = Faker.Internet.email()
    password = "foobar2020"

    res =
      conn
      |> graphql(
        query(@signup_mutation, %{
          "email" => email,
          "password" => password
        })
      )

    response = json_response(res, 200)
    assert String.length(response["data"]["signup"]["token"]) > 0

    res =
      conn
      |> graphql(
        query(@auth_mutation, %{
          "email" => email,
          "password" => password
        })
      )

    response = json_response(res, 200)
    assert response["data"]["authenticate"]["email"] == email
    token = response["data"]["authenticate"]["token"]
    refresh_token = response["data"]["authenticate"]["refreshToken"]

    user = User.find_by_email(email)

    res =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> graphql(query(@current_user_query))

    current_user = json_response(res, 200)["data"]["currentUser"]
    assert current_user["email"] == user.email

    res =
      conn
      |> graphql(query(@refresh_token_mutation, %{"refreshToken" => refresh_token}))

    response = json_response(res, 200)
    token = response["data"]["refreshToken"]["token"]
    refresh_token = response["data"]["refreshToken"]["refreshToken"]

    res =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> graphql(query(@current_user_query))

    current_user = json_response(res, 200)["data"]["currentUser"]
    assert current_user["email"] == user.email

    res =
      conn
      |> graphql(query(@refresh_token_mutation, %{"refreshToken" => refresh_token}))

    response = json_response(res, 200)
    assert String.length(response["data"]["refreshToken"]["token"]) > 0
    assert String.length(response["data"]["refreshToken"]["refreshToken"]) > 0
  end

  test "accepting terms of service", %{
    conn: conn
  } do
    user = insert(:user, is_tos_accepted: false)

    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@accept_tos_mutation, %{}))

    data = json_response(res, 200)["data"]["acceptTos"]
    assert data == %{"isTosAccepted" => true}
    user = Repo.get(User, user.id)
    assert user.is_tos_accepted
  end

  # This should be moved out to helpers
  defp graphql(conn, query) do
    conn |> post("/graphql", query)
  end
end
