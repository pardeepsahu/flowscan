defmodule FlowscanWeb.Resolvers.User do
  @moduledoc false

  alias Flowscan.Services.Subscriptions
  alias Flowscan.User
  alias Flowscan.UserMeta
  alias FlowscanWeb.Auth
  alias FlowscanWeb.SignInWithAppleToken

  def current_user(_parent, _args, %{context: %{current_user: current_user}}) do
    {:ok, %{current_user | is_plus: true}}
  end

  def current_user(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def authenticate(_parent, %{email: email, password: password}, _resolution) do
    Auth.authenticate(email, password)
  end

  def signup(_parent, %{email: email, password: password, platform: platform}, _resolution) do
    Auth.signup(email, password, platform)
  end

  def signup(_parent, %{email: email, password: password}, _resolution) do
    Auth.signup(email, password)
  end

  def refresh_token(_parent, %{refresh_token: refresh_token}, _resolution) do
    Auth.refresh_token(refresh_token)
  end

  def request_password_reset(_parent, %{email: email}, _resolution) do
    Auth.request_password_reset(email)
  end

  def password_reset(
        _parent,
        %{password_reset_token: password_reset_token, password: password},
        _resolution
      ) do
    Auth.password_reset(password_reset_token, password)
  end

  def notification_settings(_parent, _args, %{context: %{current_user: current_user}}) do
    {:ok, current_user}
  end

  def notification_settings(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def update_notification_settings(
        _parent,
        %{
          notifications_watchlist: notifications_watchlist,
          notifications_highlights: notifications_highlights
        },
        %{context: %{current_user: current_user}}
      ) do
    User.update_notification_settings(
      current_user,
      notifications_watchlist,
      notifications_highlights
    )
  end

  def update_notification_settings(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def sign_in_with_apple(_parent, %{identity_token: identity_token}, _resolution) do
    # TODO: nonce is supported, but we're not verifying it
    {:ok, claims} = SignInWithAppleToken.verify_and_validate(identity_token)
    Auth.sign_in_with_apple(claims)
  end

  def verify_user_subscription(_parent, %{qonversion_user_id: qonversion_user_id}, %{
        context: %{current_user: current_user}
      }) do
    case Subscriptions.verify_user_subscription(current_user, qonversion_user_id) do
      {:ok, %User{} = user} -> {:ok, user}
      _ -> {:error, "SUBSCRIPTION_FAILED"}
    end
  end

  def verify_user_subscription(_parent, %{qonversion_user_id: _qonversion_user_id}, _) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def accept_tos(_parent, _args, %{context: %{current_user: current_user}}) do
    case User.accept_tos(current_user) do
      {:ok, %User{} = user} -> {:ok, user}
      _ -> {:error, "ACCEPT_TOS_FAILED"}
    end
  end

  def accept_tos(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def user_meta(_parent, _args, %{context: %{current_user: current_user}}) do
    {:ok, UserMeta.for_user_id(current_user.id)}
  end

  def user_meta(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def user_meta_interaction(_parent, %{interaction: interaction}, %{
        context: %{current_user: current_user}
      }) do
    {:ok, UserMeta.interaction(current_user, interaction)}
  end

  def user_meta_interaction(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end
end
