defmodule Flowscan.Repo.Migrations.AddSignalsToOptionActivity do
  use Ecto.Migration

  def change do
    alter table(:option_activity) do
      add :signals, {:array, :string}
    end
  end
end
