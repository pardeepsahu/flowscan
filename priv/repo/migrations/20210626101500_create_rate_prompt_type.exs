defmodule Flowscan.Repo.Migrations.CreateRatePromptType do
  @moduledoc false
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE rate_prompt_type AS ENUM ('hide', 'show', 'rated', 'dismissed')"
    drop_query = "DROP TYPE rate_prompt_type"
    execute(create_query, drop_query)
  end
end
