defmodule Flowscan.Repo.Migrations.RemoveLastUserIdFromPushToken do
  use Ecto.Migration

  def change do
    alter table(:push_tokens) do
      remove :last_user_id, :string
    end
  end
end
