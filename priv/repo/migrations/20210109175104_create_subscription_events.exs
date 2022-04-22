defmodule Flowscan.Repo.Migrations.CreateSubscriptionEvents do
  use Ecto.Migration

  def change do
    create table(:subscription_events) do
      add :event, :string, null: true
      add :body, :map

      timestamps()
    end
  end
end
