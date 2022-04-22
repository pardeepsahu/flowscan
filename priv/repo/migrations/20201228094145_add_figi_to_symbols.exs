defmodule Flowscan.Repo.Migrations.AddFigiToSymbols do
  use Ecto.Migration

  def change do
    alter table(:symbols) do
      add :figi, :string
    end

    create index(:symbols, [:figi])
  end
end
