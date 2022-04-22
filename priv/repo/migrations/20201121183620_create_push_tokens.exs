defmodule Flowscan.Repo.Migrations.CreatePushTokens do
  use Ecto.Migration

  def change do
    create table(:push_tokens) do
      add :onesignal_player_id, :string
      add :user_id, references(:users, on_delete: :nothing, type: :uuid), null: true

      timestamps()
    end

    create index(:push_tokens, [:user_id])
    create index(:push_tokens, [:onesignal_player_id], unique: true)
  end
end
