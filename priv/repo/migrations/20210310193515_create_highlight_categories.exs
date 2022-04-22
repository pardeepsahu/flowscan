defmodule Flowscan.Repo.Migrations.CreateHighlightCategories do
  use Ecto.Migration

  def change do
    create table(:highlight_categories) do
      add :title, :string, null: false
      add :description, :string, null: false
      add :slug, :string, null: false
      add :weight, :integer, default: 0, null: false
      add :is_active, :boolean, default: false, null: false

      timestamps()
    end

    create index(:highlight_categories, [:slug], unique: true)
  end
end
