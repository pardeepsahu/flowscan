defmodule Mix.Tasks.ExpiredPlusJanitor do
  @moduledoc false

  use Mix.Task
  alias Flowscan.Services.ExpiredPlusJanitor

  @shortdoc "Mark expired Plus subscriptions inactive"
  def run(_) do
    Mix.Task.run("app.start")
    ExpiredPlusJanitor.run()
  end
end
