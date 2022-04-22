defmodule Flowscan.Repo.Migrations.CreateFeedbackSentimentTypes do
  @moduledoc false
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE feedback_sentiment_type AS ENUM ('positive', 'negative')"
    drop_query = "DROP TYPE feedback_sentiment_type"
    execute(create_query, drop_query)
  end
end
