defmodule Flowscan.Workers.OptionActivitySync do
  @moduledoc false
  alias Flowscan.Services.OptionActivitySync

  use Oban.Worker,
    queue: :option_activity,
    max_attempts: 1,
    unique: [fields: [:worker], period: 60]

  @impl Oban.Worker
  def perform(_job) do
    OptionActivitySync.run()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(50)
end
