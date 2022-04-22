defmodule Mix.Tasks.ReformatHighlights do
  @moduledoc false
  use Mix.Task
  import Ecto.Query
  alias Flowscan.Highlight
  alias Flowscan.Repo
  alias Flowscan.Services.HighlightClassifier

  @shortdoc "Reformat option_activity highlights"
  def run(_) do
    Mix.Task.run("app.start")

    highlights =
      Highlight
      |> where(type: :option_activity)
      |> where([q], not is_nil(q.option_activity_id))
      |> preload([:option_activity])
      |> Repo.all()

    highlights
    |> Enum.each(fn highlight ->
      updates = HighlightClassifier.format_option_activity(highlight.option_activity)

      highlight |> Highlight.changeset(updates) |> Repo.update!()
    end)
  end
end
