defmodule Flowscan.Repo.Migrations.AddDataFieldsToHighlights do
  use Ecto.Migration

  def change do
    alter table(:highlights) do
      add :cost_basis, :decimal, null: true
      add :percent_per_day_to_strike, :decimal, null: true
    end
  end
end
