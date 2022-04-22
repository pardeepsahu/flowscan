defmodule Flowscan.Repo.Migrations.CreateFeedback do
  use Ecto.Migration

  def change do
    create table(:feedback) do
      add :body, :string
      add :sentiment, :feedback_sentiment_type
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:feedback, [:user_id])
  end
end
