defmodule Flowscan.Subscription do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Flowscan.Repo
  alias Flowscan.User

  schema "subscriptions" do
    field :current_period_end, :utc_datetime
    field :current_period_start, :utc_datetime
    field :current_period_type, :string
    field :entitlement, :string
    field :expires, :utc_datetime
    field :platform, :string
    field :platform_product_id, :string
    field :renew_state, :string
    field :starts, :utc_datetime
    field :qonversion_purchase_original_id, :string
    field :qonversion_user_id, :string
    belongs_to(:user, Flowscan.User, foreign_key: :user_id, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :current_period_end,
      :current_period_start,
      :current_period_type,
      :entitlement,
      :expires,
      :platform,
      :platform_product_id,
      :renew_state,
      :starts,
      :qonversion_purchase_original_id,
      :qonversion_user_id
    ])
    |> validate_required([
      :current_period_end,
      :current_period_start,
      :current_period_type,
      :entitlement,
      :expires,
      :platform,
      :platform_product_id,
      :renew_state,
      :starts,
      :qonversion_purchase_original_id,
      :qonversion_user_id
    ])
  end

  def create_changeset(subscription, attrs, %User{} = user) do
    subscription |> changeset(attrs) |> put_assoc(:user, user)
  end

  def find_by_qonversion_purchase_original_id(
        %User{} = user,
        qonversion_purchase_original_id
      ) do
    Repo.get_by(__MODULE__,
      user_id: user.id,
      qonversion_purchase_original_id: qonversion_purchase_original_id
    )
  end
end
