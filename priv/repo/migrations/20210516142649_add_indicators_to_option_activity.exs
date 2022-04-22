defmodule Flowscan.Repo.Migrations.AddIndicatorsToOptionActivity do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:option_activity) do
      add :indicators, {:array, :string}
    end
  end
end
