defmodule Flowscan.Repo.Migrations.AddHasSignedInToPushToken do
  use Ecto.Migration

  def change do
    alter table(:push_tokens) do
      add :last_user_id, :string, null: true
    end
  end
end
