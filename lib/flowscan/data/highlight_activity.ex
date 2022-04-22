defmodule Flowscan.Data.HighlightActivity do
  @moduledoc false
  alias Flowscan.OptionActivity
  alias Flowscan.Repo
  import Ecto.Query

  def aggressive(cutoff) do
    recent(cutoff)
    |> OptionActivity.with_signal("aggressive")
    |> where([q], q.cost_basis >= 40_000)
    |> order_by(:datetime)
    |> Repo.all()
  end

  def repeat_sweeps(cutoff) do
    recent(cutoff)
    |> select([q], %{
      id: max(q.id),
      symbol_id: q.symbol_id,
      ticker: q.ticker,
      expiration_date: q.expiration_date,
      strike: q.strike,
      is_put: q.is_put
    })
    |> where(is_buy: true, is_sweep: true, is_etf: false)
    |> OptionActivity.with_signal("repeat_sweep")
    |> OptionActivity.with_one_of_signals("above_ask", "at_ask")
    |> group_by([:symbol_id, :ticker, :expiration_date, :strike, :is_put])
    |> having(fragment("COUNT(*) > 1"))
    |> Repo.all()
  end

  def whales(cutoff) do
    recent(cutoff)
    |> where(is_etf: false)
    |> OptionActivity.with_one_of_signals("above_ask", "at_ask")
    |> where([q], q.cost_basis >= 1_000_000)
    |> where(
      [q],
      (q.strike > q.underlying_price and q.is_put == false) or
        (q.strike < q.underlying_price and q.is_put == true)
    )
    |> order_by(:datetime)
    |> Repo.all()
  end

  defp recent(cutoff) do
    OptionActivity
    |> where(is_published: true, is_buy: true)
    |> where([q], q.datetime >= ^cutoff)
  end
end
