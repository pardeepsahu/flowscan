defmodule Flowscan.Repo.Migrations.CreateHighlightSentimentTypes do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE highlight_sentiment_type AS ENUM ('positive', 'negative', 'neutral', 'unusual')"
    drop_query = "DROP TYPE highlight_sentiment_type"
    execute(create_query, drop_query)
  end
end
