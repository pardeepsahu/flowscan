defmodule Flowscan.Repo.Migrations.AddDatetimeToHighlights do
  use Ecto.Migration

  def change do
    alter table(:highlights) do
      add :datetime, :utc_datetime
    end
  end
end
