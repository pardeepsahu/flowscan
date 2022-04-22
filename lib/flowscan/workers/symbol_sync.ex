defmodule Flowscan.Workers.SymbolSync do
  @moduledoc false
  alias Flowscan.Services.SymbolSync

  use Oban.Worker, max_attempts: 5, unique: [fields: [:worker], period: 60]

  @impl Oban.Worker
  def perform(_job) do
    SymbolSync.run()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(60)
end
