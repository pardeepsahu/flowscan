defmodule Mix.Tasks.MergeDuplicateFigis do
  @moduledoc false

  use Mix.Task
  import Ecto.Query
  alias Flowscan.Repo
  alias Flowscan.{EarningsCalendar, OptionActivity, OptionOhlcv, Symbol, SymbolOhlcv, Watchlist}
  require Logger

  @shortdoc "Merge symbols that have changed tickers / FIGI dupes"
  def run(_) do
    Mix.Task.run("app.start")

    fetch_duplicate_figis()
    |> Enum.each(fn f ->
      [orphan, current] = fetch_orphan_and_current_symbol(f.figi)
      IO.puts("#{orphan.symbol} -> #{current.symbol}")

      update_option_activity =
        from OptionActivity,
          where: [symbol_id: ^orphan.id]

      update_watchlist =
        from Watchlist,
          where: [symbol_id: ^orphan.id]

      update_earnings_calendar = from EarningsCalendar, where: [symbol_id: ^orphan.id]

      delete_symbol_ohlcv = from SymbolOhlcv, where: [symbol_id: ^orphan.id]
      delete_option_ohlcv = from OptionOhlcv, where: [symbol_id: ^orphan.id]

      Ecto.Multi.new()
      |> Ecto.Multi.update_all(:option_activity, update_option_activity,
        set: [symbol_id: current.id]
      )
      |> Ecto.Multi.update_all(:watchlist, update_watchlist, set: [symbol_id: current.id])
      |> Ecto.Multi.update_all(:earnings_calendar, update_earnings_calendar,
        set: [symbol_id: current.id]
      )
      |> Ecto.Multi.delete_all(:symbol_ohlcv, delete_symbol_ohlcv)
      |> Ecto.Multi.delete_all(:option_ohlcv, delete_option_ohlcv)
      |> Repo.transaction()
      |> case do
        {:ok, _} ->
          Repo.delete(orphan)

        {:error, name, value, changes_so_far} ->
          Logger.error("! Failed merging symbols #{orphan.symbol}->#{current.symbol}")
          Logger.error(" - name=#{name} value=#{value}")
          Logger.error(inspect(changes_so_far))
      end
    end)
  end

  defp fetch_duplicate_figis do
    Symbol
    |> select([:figi])
    |> where([q], not is_nil(q.figi))
    |> group_by([:figi])
    |> having(fragment("COUNT(*) > 1"))
    |> Repo.all()
  end

  defp fetch_orphan_and_current_symbol(figi) do
    symbols =
      Symbol
      |> where(figi: ^figi)
      |> order_by(:inserted_at)
      |> Repo.all()

    [Enum.at(symbols, 0), Enum.at(symbols, 1)]
  end
end
