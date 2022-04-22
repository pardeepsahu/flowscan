defmodule FlowscanWeb.Auth do
  @moduledoc false
  alias Flowscan.{Guardian, User}
  import FlowscanWeb.GraphqlHelpers
  require Logger

  def authenticate(email, password) do
    error = {:error, [[field: :email, message: "Invalid email or password"]]}

    case User.find_by_email(String.downcase(email)) do
      nil ->
        error

      user ->
        case Argon2.check_pass(user, password) do
          {:error, _} -> error
          {:ok, user} -> {:ok, user_with_tokens(user)}
        end
    end
  end

  def signup(email, password, platform \\ nil) do
    User.signup(%{"email" => email, "password" => password}, platform)
    |> case do
      {:ok, user} ->
        {:ok, user_with_tokens(user)}

      {:error, changeset} ->
        {:error, extract_error_msg(changeset)}
    end
  end

  def refresh_token(refresh_token) do
    ttl = Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:ttl_access_token]

    with {:ok, user, _claims} <- Guardian.resource_from_token(refresh_token),
         {:ok, _old_token, {exchanged_token, _claims}} <-
           Guardian.exchange(refresh_token, "refresh", "access", ttl: ttl),
         {:ok, refresh_token} <- generate_refresh_token(user) do
      {:ok,
       Map.merge(user, %{token: exchanged_token, refresh_token: refresh_token, is_plus: true})}
    else
      {:error, :token_expired} ->
        Logger.info("Token expired")
        {:error, "TOKEN_EXPIRED"}

      {:error, message} ->
        Logger.error("Failed to refresh token: #{message}")
        {:error, "TOKEN_INVALID"}
    end
  end

  def request_password_reset(email) do
    User.request_password_reset(email)
    {:ok, %{ok: true}}
  end

  def password_reset(password_reset_token, password) do
    User.password_reset(password_reset_token, password)
    |> case do
      {:ok, user} ->
        {:ok, user_with_tokens(user)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, extract_error_msg(changeset)}

      {:error, error} ->
        {:error, error}
    end
  end

  def sign_in_with_apple(claims) do
    email = claims["email"]
    sub = claims["sub"]

    case User.find_by_sign_in_with_apple(sub) do
      %User{} = user ->
        {:ok, user_with_tokens(user)}

      _ ->
        case User.create_apple_user(sub, email) do
          {:ok, user} ->
            # TODO: Update email if needed
            {:ok, user_with_tokens(user)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, extract_error_msg(changeset)}

          _ ->
            Logger.error("Error creating account with Apple (#{email})")
            {:error, "Could not create an account"}
        end
    end
  end

  def user_with_tokens(user) do
    with {:ok, access_token} <- generate_access_token(user),
         {:ok, refresh_token} <- generate_refresh_token(user) do
      Map.merge(%{user | is_plus: true}, %{token: access_token, refresh_token: refresh_token})
    end
  end

  @spec generate_access_token(User.t()) :: {:ok, String.t()}
  defp generate_access_token(user) do
    ttl = Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:ttl_access_token]

    with {:ok, access_token, _claims} <-
           Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: ttl) do
      {:ok, access_token}
    end
  end

  @spec generate_refresh_token(User.t()) :: {:ok, String.t()}
  defp generate_refresh_token(user) do
    ttl = Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:ttl_refresh_token]

    with {:ok, refresh_token, _claims} <-
           Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: ttl) do
      {:ok, refresh_token}
    end
  end
end
