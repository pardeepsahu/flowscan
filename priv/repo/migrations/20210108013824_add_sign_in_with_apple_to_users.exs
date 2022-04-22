defmodule Flowscan.Repo.Migrations.AddSignInWithAppleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_sign_in_with_apple, :boolean, default: false
      add :federated_user_id, :string, null: true
    end
  end
end
