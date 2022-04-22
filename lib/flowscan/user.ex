defmodule Flowscan.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ecto.UUID
  alias Flowscan.AuditLog
  alias Flowscan.Email
  alias Flowscan.Mailer
  alias Flowscan.Repo

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :token, :string, virtual: true
    field :refresh_token, :string, virtual: true
    field :is_plus, :boolean, default: false
    field :is_sign_in_with_apple, :boolean, default: false
    field :is_tos_accepted, :boolean, default: false
    field :federated_user_id, :string, null: true
    field :password_reset_token, :string
    field :password_reset_token_expires_at, :utc_datetime
    field :notifications_watchlist, :boolean, default: true
    field :notifications_highlights, :boolean, default: true
    field :plus_started_at, :utc_datetime, null: true
    field :plus_expires_at, :utc_datetime, null: true
    field :qonversion_user_id, :string, null: true

    # field :last_auth_at, :utc_datetime
    # field :last_token_rotation_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :is_tos_accepted])
    |> validate_required(:email, message: "E-mail is required")
    |> validate_password
    |> validate_format(:email, ~r/@/, message: "Invalid e-mail address")
    |> unique_constraint(:email, message: "User already exists")
    |> put_password_hash
  end

  def federated_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :is_sign_in_with_apple, :federated_user_id])
    |> unique_constraint(:federated_user_id, message: "User already exists")
  end

  def accept_tos_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_tos_accepted])
  end

  def request_password_reset_changeset(user, attrs) do
    user
    |> cast(attrs, [:password_reset_token, :password_reset_token_expires_at])
  end

  def password_reset_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_reset_token, :password_reset_token_expires_at])
    |> validate_password
    |> put_password_hash
  end

  def notifications_changeset(user, attrs) do
    user
    |> cast(attrs, [:notifications_watchlist, :notifications_highlights])
  end

  def plus_subscription_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_plus, :plus_started_at, :plus_expires_at, :qonversion_user_id])
  end

  def find_by_id(id) do
    Repo.get(__MODULE__, id)
  end

  def find_by_email(email) do
    Repo.get_by(__MODULE__, email: email)
  end

  def find_by_sign_in_with_apple(federated_user_id) do
    Repo.get_by(__MODULE__, federated_user_id: federated_user_id, is_sign_in_with_apple: true)
  end

  def expired_plus_users do
    now = DateTime.utc_now()

    __MODULE__
    |> where(is_plus: true)
    |> where([q], q.plus_expires_at < ^now)
    |> Repo.all()
  end

  def signup(attrs, platform \\ nil) do
    __MODULE__.__struct__()
    |> changeset(Map.put(attrs, "is_tos_accepted", true))
    |> Repo.insert()
  end

  def create_apple_user(sub, email) do
    existing_user =
      __MODULE__
      |> where(email: ^email, is_sign_in_with_apple: false)
      |> Repo.one()

    if existing_user do
      existing_user
      |> federated_changeset(%{"federated_user_id" => sub, "is_sign_in_with_apple" => true})
      |> Repo.update()
    else
      __MODULE__.__struct__()
      |> federated_changeset(%{
        "federated_user_id" => sub,
        "email" => email,
        "is_sign_in_with_apple" => true
      })
      |> Repo.insert()
    end
  end

  def request_password_reset(email) do
    Logger.info("Requesting password reset for user #{email}")

    case __MODULE__.find_by_email(email) do
      %__MODULE__{} = user ->
        expires_at = DateTime.utc_now() |> Timex.shift(hours: 1)

        user
        |> request_password_reset_changeset(%{
          password_reset_token: UUID.generate(),
          password_reset_token_expires_at: expires_at
        })
        |> Repo.update!()

        user = Repo.get(__MODULE__, user.id)
        user |> Email.password_reset_email() |> Mailer.deliver_later()

      _ ->
        nil
    end
  end

  def password_reset_token_is_valid?(password_reset_token) do
    now = DateTime.utc_now()

    __MODULE__
    |> where(password_reset_token: ^password_reset_token)
    |> where([q], q.password_reset_token_expires_at > ^now)
    |> Repo.exists?()
  end

  def password_reset(password_reset_token, password) do
    now = DateTime.utc_now()

    user =
      __MODULE__
      |> where(password_reset_token: ^password_reset_token)
      |> where([q], q.password_reset_token_expires_at > ^now)
      |> Repo.one()

    if user do
      Logger.info("Resetting password for user #{user.email}")

      user
      |> password_reset_changeset(%{password: password, password_reset_token: nil})
      |> Repo.update()
    else
      {:error, "Invalid or expired password reset token"}
    end
  end

  def update_notification_settings(user, notifications_watchlist, notifications_highlights) do
    user
    |> notifications_changeset(%{
      notifications_watchlist: notifications_watchlist,
      notifications_highlights: notifications_highlights
    })
    |> Repo.update()
  end

  def update_plus_subscription(
        %Flowscan.User{} = user,
        is_plus,
        plus_started_at,
        plus_expires_at,
        qonversion_user_id
      ) do
    changeset = %{
      is_plus: is_plus,
      plus_expires_at: plus_expires_at,
      qonversion_user_id: qonversion_user_id
    }

    changeset =
      if user.plus_started_at,
        do: changeset,
        else: changeset |> Map.put(:plus_started_at, plus_started_at)

    AuditLog.create(user, "plus_subscription_update", changeset)
    user |> plus_subscription_changeset(changeset) |> Repo.update()
  end

  def expire_plus_subscription(%Flowscan.User{} = user) do
    changeset = %{is_plus: false}
    AuditLog.create(user, "plus_subscription_expired", %{plus_expires_at: user.plus_expires_at})
    user |> plus_subscription_changeset(changeset) |> Repo.update()
  end

  def accept_tos(%Flowscan.User{} = user) do
    user |> accept_tos_changeset(%{is_tos_accepted: true}) |> Repo.update()
  end

  def notification_user_ids_for_featured_highlights(plus_only) do
    __MODULE__
    |> select([:id])
    |> where(notifications_highlights: true)
    |> (fn query ->
          case plus_only do
            true ->
              query
              |> where(is_plus: true)

            _ ->
              query
          end
        end).()
    |> Repo.all()
    |> Enum.map(fn u -> u.id end)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, Argon2.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp validate_password(changeset) do
    changeset
    |> validate_required(:password, message: "Password can't be empty")
    |> validate_length(:password, min: 6, message: "The password is too short")
  end
end
