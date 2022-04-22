defmodule Flowscan.Repo.Migrations.CreateUserMeta do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:user_meta, primary_key: false) do
      add :id, references(:users, on_delete: :nothing, type: :uuid), primary_key: true
      add :rate_prompt, :rate_prompt_type, default: "hide", null: false
      add :rate_prompt_updated_at, :naive_datetime, null: true


      timestamps()
    end
  end
end
