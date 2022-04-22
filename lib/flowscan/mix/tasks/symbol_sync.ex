defmodule Mix.Tasks.SymbolSync do
  @moduledoc false

  use Mix.Task
  alias Flowscan.Services.SymbolSync

  @shortdoc "Synchronize symbol database"
  def run(_) do
    Mix.Task.run("app.start")
    SymbolSync.run()
  end
end
