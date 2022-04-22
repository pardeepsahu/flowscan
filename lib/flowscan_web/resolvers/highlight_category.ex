defmodule FlowscanWeb.Resolvers.HighlightCategory do
  @moduledoc false
  alias Flowscan.HighlightCategory

  def list(_parent, _options, %{context: %{current_user: _current_user}}) do
    {:ok, HighlightCategory.list()}
  end

  def list(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end
end
