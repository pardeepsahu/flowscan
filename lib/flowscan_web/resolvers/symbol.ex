defmodule FlowscanWeb.Resolvers.Symbol do
  @moduledoc false
  alias Flowscan.Data.StockQuote

  def search(_parent, %{query: query}, %{context: %{current_user: _current_user}}) do
    {:ok, Flowscan.Symbol.search(query)}
  end

  def search(_parent, %{query: _query}, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def lookup(_parent, %{symbol_id: symbol_id}, %{context: %{current_user: _current_user}}) do
    {:ok, Flowscan.Symbol.find_by_id(symbol_id)}
  end

  def lookup(_parent, %{symbol_id: _symbol_id}, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end

  def ohlcv_3mo(_parent, %{symbol_id: symbol_id}, %{context: %{current_user: _current_user}}) do
    symbol = Flowscan.Symbol.find_by_id(symbol_id)
    {:ok, StockQuote.ohlcv_3mo(symbol)}
  end

  def ohlcv_3mo(_parent, %{symbol_id: _symbol_id}, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end
end
