defmodule Flowscan.Repo.Migrations.CreateHighlights do
  use Ecto.Migration

  def change do
    create table(:highlights) do
      add :ref_id, :integer
      add :type, :highlight_type
      add :ticker, :string
      add :title, :string
      add :subtitle, :string
      add :info, :string
      add :sentiment, :highlight_sentiment_type
      add :is_pro, :boolean, default: false, null: false
      add :is_published, :boolean, default: false, null: false
      add :is_featured, :boolean, default: false, null: false
      add :category_id, references(:highlight_categories, on_delete: :nothing)

      timestamps()
    end

    create index(:highlights, [:category_id])
    create index(:highlights, [:is_published])
    create index(:highlights, [:is_featured])
    create index(:highlights, [:inserted_at])
  end
end
