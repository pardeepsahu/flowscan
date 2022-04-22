defmodule Flowscan.Repo.Migrations.CreateSymbols do
  use Ecto.Migration

  def change do
    create table(:symbols) do
      add :symbol, :string
      add :name, :string
      add :is_active, :boolean, default: true, null: false
      add :iex_id, :string
      add :type, :string

      timestamps()
    end

    create index(:symbols, [:symbol], unique: true)
    create index(:symbols, [:iex_id], unique: true)
    create index(:symbols, [:is_active])
    create index(:symbols, [:name])
  end
end
