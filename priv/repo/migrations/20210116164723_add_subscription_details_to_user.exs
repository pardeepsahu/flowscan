defmodule Flowscan.Repo.Migrations.AddSubscriptionDetailsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pro_started_at, :utc_datetime, null: true
      add :pro_expires_at, :utc_datetime, null: true
      add :qonversion_user_id, :string, null: true
    end
  end
end
