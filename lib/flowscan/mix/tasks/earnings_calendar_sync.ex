defmodule Mix.Tasks.EarningsCalendarSync do
  @moduledoc false

  use Mix.Task
  alias Flowscan.Services.EarningsCalendarSync

  @shortdoc "Sync earnings calendar"
  def run(_) do
    Mix.Task.run("app.start")
    EarningsCalendarSync.run()
  end
end
