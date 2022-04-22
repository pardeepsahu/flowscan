defmodule Flowscan.Repo.Migrations.MakeSymbolsFigiUnique do
  @moduledoc false
  use Ecto.Migration

  def change do
    drop index(:symbols, [:figi])
    create index(:symbols, [:figi], unique: true)
  end
end
