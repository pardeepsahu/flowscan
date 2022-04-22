defmodule Flowscan.EarningsCalendar do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo

  schema "earnings_calendar" do
    belongs_to(:symbol, Flowscan.Symbol, foreign_key: :symbol_id)
    field :confirmed_earnings_date, :date
    field :estimate, :decimal
    field :fiscal_date_ending, :date
    field :preliminary_earnings_date, :date

    timestamps()
  end

  @doc false
  def changeset(earnings_calendar, attrs) do
    earnings_calendar
    |> cast(attrs, [
      :preliminary_earnings_date,
      :confirmed_earnings_date,
      :fiscal_date_ending,
      :estimate
    ])
    |> validate_required([
      :preliminary_earnings_date,
      :fiscal_date_ending
    ])
  end

  def find_for_fiscal_ending_date(symbol, fiscal_date_ending) do
    range_start = fiscal_date_ending |> Timex.shift(days: -14)
    range_end = fiscal_date_ending |> Timex.shift(days: 14)

    __MODULE__
    |> where(symbol_id: ^symbol.id)
    |> where([q], q.fiscal_date_ending >= ^range_start and q.fiscal_date_ending <= ^range_end)
    |> Repo.one()
  end

  def symbol_ids_with_earnings_soon() do
    __MODULE__
    |> select([:symbol_id])
    |> filter_earnings_soon()
    |> Repo.all()
    |> Enum.map(fn ec -> ec.symbol_id end)
  end

  def earnings_soon?(symbol_id) do
    __MODULE__
    |> where(symbol_id: ^symbol_id)
    |> filter_earnings_soon()
    |> Repo.exists?()
  end

  def upcoming_earnings(symbol_id, date) do
    cutoff = date |> Timex.shift(days: 14)

    __MODULE__
    |> where(symbol_id: ^symbol_id)
    |> where([q], q.confirmed_earnings_date >= ^date and q.confirmed_earnings_date <= ^cutoff)
    |> Repo.one()
  end

  defp filter_earnings_soon(query) do
    today = Timex.now()
    cutoff = Timex.now() |> Timex.shift(days: 14)

    query
    |> where([q], q.confirmed_earnings_date >= ^today and q.confirmed_earnings_date <= ^cutoff)
  end
end
