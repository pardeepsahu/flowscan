defmodule Flowscan.Repo.Migrations.CreateSocialPosts do
  use Ecto.Migration

  def change do
    create table(:social_posts) do
      add :ticker, :string
      add :type, :string
      add :body, :string
      add :sentiment, :string
      add :is_published, :boolean, default: false

      timestamps()
    end

    create index(:social_posts, [:ticker])
    create index(:social_posts, [:inserted_at])
  end
end
