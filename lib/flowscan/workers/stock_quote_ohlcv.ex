defmodule Flowscan.Workers.StockQuoteOhlcv do
  @moduledoc false
  alias Flowscan.Data.StockQuote
  alias Flowscan.Symbol
  require Logger

  use Oban.Worker, queue: :data, max_attempts: 5, unique: [period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"symbol_id" => symbol_id, "range" => range}}) do
    symbol = Symbol.find_by_id(symbol_id)
    Logger.info("Fetching OHLCV data (#{symbol.symbol} #{range})")
    StockQuote.fetch_ohlcv(symbol, range)
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(60)
end
