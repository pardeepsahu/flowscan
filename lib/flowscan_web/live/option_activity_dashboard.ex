defmodule FlowscanWeb.Live.OptionActivityDashboard do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder
  alias Flowscan.OptionActivity
  alias Flowscan.Repo
  alias Flowscan.Services.ActivityClassifier
  import Ecto.Query

  @impl true
  def menu_link(_, _) do
    {:ok, "Option Activity"}
  end

  @impl true
  def render_page(_assigns) do
    table(
      columns: columns(),
      id: :option_activity_table,
      row_attrs: &row_attrs/1,
      row_fetcher: &fetch_option_activity/2,
      rows_name: "activities",
      title: "Option Activity"
    )
  end

  defp fetch_option_activity(params, _node) do
    # %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params
    %{limit: limit} = params

    data =
      OptionActivity
      |> order_by(desc: :inserted_at)
      |> limit(^limit)
      |> Repo.all()

    data_with_signals =
      Enum.map(data, fn i ->
        Map.put(
          Map.from_struct(i),
          :signals,
          Enum.join(
            Enum.map(ActivityClassifier.classify(i).signals, fn f -> Atom.to_string(f) end),
            ", "
          )
        )
      end)

    {data_with_signals, 10_000}
  end

  defp columns do
    [
      %{field: :ticker},
      %{field: :strike},
      %{field: :cost_basis},
      %{field: :inserted_at, sortable: :desc},
      %{field: :signals}
    ]
  end

  defp row_attrs(table) do
    [
      {"phx-click", "show_info"},
      {"phx-value-info", "Huh"},
      {"phx-page-loading", true}
    ]
  end
end
