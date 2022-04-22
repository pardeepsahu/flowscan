defmodule Mix.Tasks.ReclassifyOptionActivity do
  @moduledoc false

  use Mix.Task
  import Ecto.Query
  alias Flowscan.OptionActivity
  alias Flowscan.Repo
  alias Flowscan.Services.ActivityClassifier
  require Logger

  @shortdoc "Re-classify all option activity"
  def run(_) do
    Mix.Task.run("app.start")

    # unless System.get_env("APP_ENV") == "dev" do
    #   raise "Can only be ran on dev"
    # end

    Logger.info("Retrieving all option activity IDs")
    ids = Repo.all(from oa in "option_activity", select: oa.id)

    Logger.info("Starting classification")

    Enum.each(ids, fn oa_id ->
      :erlang.garbage_collect()
      Logger.info("Processing #{oa_id}")
      classifier = Repo.get!(OptionActivity, oa_id) |> ActivityClassifier.classify()

      classifier.activity
      |> OptionActivity.classify_changeset(%{
        signals: Enum.map(classifier.signals, fn f -> Atom.to_string(f) end),
        is_plus: classifier.is_plus,
        is_published: classifier.is_published,
        is_buy: classifier.is_buy,
        is_sell: classifier.is_sell
      })
      |> Repo.update!()
    end)
  end
end
