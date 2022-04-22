defmodule Flowscan.Repo.Migrations.CreateSymbolOhlcv do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:symbol_ohlcv) do
      add :date, :date
      add :volume, :integer
      add :open, :decimal
      add :close, :decimal
      add :low, :decimal
      add :high, :decimal
      add :symbol_id, references(:symbols, on_delete: :nothing)

      timestamps()
    end

    create index(:symbol_ohlcv, [:symbol_id])
    create index(:symbol_ohlcv, [:symbol_id, :date], unique: true)
  end
end
