defmodule Flowscan.Workers.SocialPosting do
  @moduledoc false
  alias Flowscan.Services.SocialPosting

  use Oban.Worker, max_attempts: 1, unique: [fields: [:worker], period: 60]

  @impl Oban.Worker
  def perform(_job) do
    SocialPosting.run()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(60)
end
