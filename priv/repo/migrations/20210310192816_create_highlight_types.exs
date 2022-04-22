defmodule Flowscan.Repo.Migrations.CreateHighlightTypes do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE highlight_type AS ENUM ('option_activity', 'symbol')"
    drop_query = "DROP TYPE highlight_type"
    execute(create_query, drop_query)
  end
end
