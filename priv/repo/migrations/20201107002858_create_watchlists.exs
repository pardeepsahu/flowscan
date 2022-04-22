defmodule Flowscan.Repo.Migrations.CreateWatchlists do
  use Ecto.Migration

  def change do
    create table(:watchlists) do
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)
      add :symbol_id, references(:symbols, on_delete: :nothing)

      timestamps()
    end

    create index(:watchlists, [:user_id, :symbol_id], unique: true)
  end
end
