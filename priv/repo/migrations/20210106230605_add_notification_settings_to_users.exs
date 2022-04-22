defmodule Flowscan.Repo.Migrations.AddNotificationSettingsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notifications_watchlist, :boolean, default: true
      add :notifications_highlights, :boolean, default: true
    end
  end
end
