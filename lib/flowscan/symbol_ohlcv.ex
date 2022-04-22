defmodule Flowscan.SymbolOhlcv do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo

  schema "symbol_ohlcv" do
    field :close, :decimal
    field :date, :date
    field :high, :decimal
    field :low, :decimal
    field :open, :decimal
    field :volume, :integer
    belongs_to(:symbol, Flowscan.Symbol, foreign_key: :symbol_id)

    timestamps()
  end

  @doc false
  def changeset(symbol_ohlcv, attrs) do
    symbol_ohlcv
    |> cast(attrs, [:date, :volume, :open, :close, :low, :high])
    |> validate_required([:date, :volume, :open, :close, :low, :high])
  end

  def for_date_range(symbol_id, start_date, end_date) do
    __MODULE__
    |> select([:date, :volume, :open, :close, :low, :high])
    |> where(symbol_id: ^symbol_id)
    |> where([q], q.date >= ^start_date and q.date <= ^end_date)
    |> order_by(:date)
    |> Repo.all()
  end

  def insert_changeset(symbol, date, volume, open, close, low, high) do
    __MODULE__.__struct__()
    |> changeset(%{
      date: date,
      volume: volume,
      open: open,
      close: close,
      low: low,
      high: high
    })
    |> put_assoc(:symbol, symbol)
  end
end
