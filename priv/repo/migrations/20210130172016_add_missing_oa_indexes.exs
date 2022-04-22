defmodule Flowscan.Repo.Migrations.AddMissingOAIndexes do
  use Ecto.Migration

  def change do
    drop index(:option_activity, [:datetime, :is_published])
    create index(:option_activity, [:is_published])
    create index(:option_activity, [:is_pro])
    create index(:option_activity, [:symbol_id])
    create index(:option_activity, [:datetime])
  end
end
