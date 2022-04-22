defmodule Flowscan.Repo.Migrations.AddSignalsToHighlights do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:highlights) do
      add :indicators, {:array, :string}
    end
  end
end
