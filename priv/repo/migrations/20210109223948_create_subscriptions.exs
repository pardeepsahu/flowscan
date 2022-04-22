defmodule Flowscan.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :entitlement, :string, null: false
      add :starts, :utc_datetime, null: false
      add :expires, :utc_datetime, null: false
      add :platform, :string, null: false
      add :platform_product_id, :string, null: false
      add :qonversion_purchase_original_id, :string, null: false
      add :qonversion_user_id, :string, null: false
      add :current_period_start, :utc_datetime, null: false
      add :current_period_end, :utc_datetime, null: false
      add :current_period_type, :string, null: false
      add :renew_state, :string, null: false
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:subscriptions, [:user_id])
    create index(:subscriptions, [:qonversion_user_id])
    create index(:subscriptions, [:qonversion_purchase_original_id])
  end
end
