defmodule FlowscanWeb.Resolvers.Highlight do
  @moduledoc false
  alias Flowscan.Highlight

  def featured(_parent, _options, %{context: %{current_user: _current_user}}) do
    {:ok, Highlight.recent(nil, "featured")}
  end

  def featured(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def feed(_parent, _args, %{context: %{current_user: _current_user}}) do
    {:ok, Highlight.feed()}
  end

  def feed(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def recent_feed(_parent, _args, %{context: %{current_user: _current_user}}) do
    {:ok, Highlight.recent_feed()}
  end

  def recent_feed(_parent, _args, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end
end
