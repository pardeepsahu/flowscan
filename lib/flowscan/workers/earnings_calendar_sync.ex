defmodule Flowscan.Workers.EarningsCalendarSync do
  @moduledoc false
  alias Flowscan.Services.EarningsCalendarSync

  use Oban.Worker, max_attempts: 10

  @impl Oban.Worker
  def perform(_job) do
    EarningsCalendarSync.run()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(600)
end
