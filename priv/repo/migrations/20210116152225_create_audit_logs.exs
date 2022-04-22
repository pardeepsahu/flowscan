defmodule Flowscan.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :type, :string
      add :body, :map
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end
  end
end
