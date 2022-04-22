defmodule Flowscan.Repo.Migrations.CreateOptionActivity do
  use Ecto.Migration

  def change do
    create table(:option_activity) do
      add :symbol_id, references(:symbols, on_delete: :nothing)
      add :ticker, :string
      add :datetime, :utc_datetime
      add :strike, :decimal
      add :expiration_date, :date
      add :is_put, :boolean, default: false, null: false
      add :is_sweep, :boolean, default: false, null: false
      add :is_etf, :boolean, default: false, null: false
      add :is_bullish, :boolean, default: false, null: false
      add :is_bearish, :boolean, default: false, null: false
      add :aggressor_ind, :decimal
      add :cost_basis, :decimal
      add :price, :decimal
      add :size, :integer
      add :bid, :decimal
      add :ask, :decimal
      add :midpoint, :decimal
      add :trade_count, :integer
      add :open_interest, :integer
      add :volume, :integer
      add :underlying_price, :decimal, null: true
      add :description, :text
      add :option_symbol, :string
      add :benzinga_signal_id, :string
      add :benzinga_updated, :integer
      add :is_published, :boolean, default: false, null: false
      add :is_pro, :boolean, default: false, null: false

      timestamps()
    end

    create index("option_activity", [:datetime, :is_published])
    create index("option_activity", [:benzinga_signal_id], unique: true)
  end
end
