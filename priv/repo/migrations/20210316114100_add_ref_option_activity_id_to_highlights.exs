defmodule Flowscan.Repo.Migrations.AddRefOptionActivityIdToHighlights do
  use Ecto.Migration

  def change do
    alter table(:highlights) do
      add :option_activity_id, references(:option_activity, on_delete: :nothing)
    end
  end
end
