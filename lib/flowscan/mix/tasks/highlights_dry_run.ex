defmodule Mix.Tasks.HighlightsDryRun do
  @moduledoc false
  use Mix.Task
  alias Flowscan.Services.HighlightClassifier

  @shortdoc "Highlights dry run"
  def run(_) do
    Mix.Task.run("app.start")
    cutoff = DateTime.utc_now() |> Timex.shift(days: -7)
    HighlightClassifier.dry_run(cutoff)
  end
end
