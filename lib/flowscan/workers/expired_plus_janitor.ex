defmodule Flowscan.Workers.ExpiredPlusJanitor do
  @moduledoc false
  alias Flowscan.Services.ExpiredPlusJanitor

  use Oban.Worker, max_attempts: 5, unique: [fields: [:worker], period: 60]

  @impl Oban.Worker
  def perform(_job) do
    ExpiredPlusJanitor.run()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(60)
end
