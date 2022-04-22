defmodule Flowscan.Repo.Migrations.AddIsOptionableToSymbols do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:symbols) do
      add :is_optionable, :boolean, default: false
    end
  end
end
