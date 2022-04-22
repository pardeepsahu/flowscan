defmodule Flowscan.Repo.Migrations.AddIsTosAcceptedToUsers do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_tos_accepted, :boolean, default: false
    end
  end
end
