defmodule Flowscan.Repo.Migrations.CreateEodOptionContract do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:eod_option_contract) do
      add :option_symbol, :string
      add :date, :date
      add :data_updated_at, :naive_datetime
      add :is_complete, :boolean, default: false, null: false
      add :volume, :integer
      add :open_interest, :integer
      add :ask, :decimal
      add :bid, :decimal
      add :open, :decimal
      add :close, :decimal
      add :low, :decimal
      add :high, :decimal
      add :symbol_id, references(:symbols, on_delete: :nothing)

      timestamps()
    end

    create index(:eod_option_contract, [:symbol_id])
    create index(:eod_option_contract, [:option_symbol, :date], unique: true)
  end
end
