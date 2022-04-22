defmodule Flowscan.Workers.HighlightClassifier do
  @moduledoc false
  alias Flowscan.Services.HighlightClassifier

  use Oban.Worker, max_attempts: 1, unique: [fields: [:worker], period: 60]

  @impl Oban.Worker
  def perform(_job) do
    HighlightClassifier.run()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(60)
end
