defmodule Flowscan.Repo.Migrations.IndexOptionSymbol do
  @moduledoc false
  use Ecto.Migration

  def change do
    create index(:option_activity, [:option_symbol])
  end
end
