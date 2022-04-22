defmodule FlowscanWeb.Resolvers.OptionContract do
  @moduledoc false
  alias Flowscan.Data
  alias Flowscan.Symbol

  def ohlcv_3mo(_parent, %{symbol_id: symbol_id, option_symbol: option_symbol}, %{
        context: %{current_user: _current_user}
      }) do
    symbol = Symbol.find_by_id(symbol_id)
    {:ok, Data.OptionContract.ohlcv_3mo(symbol, option_symbol)}
  end

  def ohlcv_3mo(_parent, %{symbol_id: _symbol_id, option_symbol: _option_symbol}, _resolution) do
    {:error, "NOT_AUTHENTICATED"}
  end
end
