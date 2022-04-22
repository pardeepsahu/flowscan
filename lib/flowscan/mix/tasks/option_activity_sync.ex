defmodule Mix.Tasks.OptionActivitySync do
  @moduledoc false

  use Mix.Task
  alias Flowscan.Services.OptionActivitySync

  @shortdoc "Update options activity"
  def run(_) do
    Mix.Task.run("app.start")
    OptionActivitySync.run(true)
  end
end
