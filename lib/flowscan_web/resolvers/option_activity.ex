defmodule FlowscanWeb.Resolvers.OptionActivity do
  @moduledoc false
  alias Flowscan.Watchlist

  def list(_parent, options, %{context: %{current_user: current_user}}) do
    cursor = options[:cursor] || nil
    filters = options |> apply_filters(current_user)

    {:ok, Flowscan.OptionActivity.list(current_user.is_plus, filters, cursor)}
  end

  def list(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def by_id(_parent, %{option_activity_id: id}, %{context: %{current_user: current_user}}) do
    {:ok, Flowscan.OptionActivity.get_by_id(id, current_user.is_plus)}
  end

  def by_id(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  defp apply_filters(options, current_user) do
    filters = %{}

    filters =
      if options[:symbol_id],
        do: Map.put(filters, :symbol_ids, [options[:symbol_id]]),
        else: filters

    filters =
      if options[:watchlist],
        do: Map.put(filters, :symbol_ids, Watchlist.symbol_ids_for_user(current_user)),
        else: filters

    if options[:filters], do: Map.merge(filters, options[:filters]), else: filters
  end
end
