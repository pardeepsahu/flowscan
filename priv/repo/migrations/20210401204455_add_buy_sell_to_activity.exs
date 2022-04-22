defmodule Flowscan.Repo.Migrations.AddBuySellToActivity do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:option_activity) do
      add :is_buy, :boolean, default: false
      add :is_sell, :boolean, default: false
    end
  end
end
