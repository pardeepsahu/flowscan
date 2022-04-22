defmodule Flowscan.Repo.Migrations.CreateOptionOhlcv do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:option_ohlcv) do
      add :date, :date
      add :option_symbol, :string
      add :volume, :integer
      add :open, :decimal
      add :close, :decimal
      add :low, :decimal
      add :high, :decimal
      add :open_interest, :integer
      add :iex_option_symbol, :string
      add :symbol_id, references(:symbols, on_delete: :nothing)

      timestamps()
    end

    create index(:option_ohlcv, [:symbol_id, :date, :option_symbol], unique: true)
  end
end
