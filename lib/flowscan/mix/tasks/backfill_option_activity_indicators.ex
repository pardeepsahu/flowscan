defmodule Mix.Tasks.BackfillOptionActivityIndicators do
  @moduledoc false

  use Mix.Task
  import Ecto.Query
  alias Flowscan.OptionActivity
  alias Flowscan.Repo
  require Logger

  @shortdoc "Backfill option activity indicators"
  def run(_) do
    Mix.Task.run("app.start")

    Logger.info("Retrieving all option activity IDs")
    ids = Repo.all(from oa in "option_activity", select: oa.id)

    Logger.info("Starting backfill")

    Enum.each(ids, fn oa_id ->
      :erlang.garbage_collect()
      Logger.info("Processing #{oa_id}")
      oa = Repo.get!(OptionActivity, oa_id)
      indicators = oa |> OptionActivity.indicators_for_activity(oa.signals)

      oa
      |> OptionActivity.changeset(%{
        indicators: Enum.map(indicators, fn f -> Atom.to_string(f) end)
      })
      |> Repo.update!()
    end)
  end
end
