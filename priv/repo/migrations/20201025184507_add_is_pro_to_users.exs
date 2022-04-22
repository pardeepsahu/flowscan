defmodule Flowscan.Repo.Migrations.AddIsProToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_pro, :boolean, default: false
    end
  end
end
