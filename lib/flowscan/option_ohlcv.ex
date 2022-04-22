defmodule Flowscan.OptionOhlcv do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo

  schema "option_ohlcv" do
    field :close, :decimal
    field :date, :date
    field :high, :decimal
    field :iex_option_symbol, :string
    field :low, :decimal
    field :open, :decimal
    field :open_interest, :integer
    field :option_symbol, :string
    field :volume, :integer
    field :alternative_volume, :integer
    belongs_to(:symbol, Flowscan.Symbol, foreign_key: :symbol_id)

    timestamps()
  end

  @doc false
  def changeset(option_ohlcv, attrs) do
    option_ohlcv
    |> cast(attrs, [
      :date,
      :option_symbol,
      :volume,
      :open,
      :close,
      :low,
      :high,
      :open_interest,
      :iex_option_symbol,
      :alternative_volume
    ])
    |> validate_required([
      :date,
      :option_symbol,
      :volume,
      # :open,
      :close,
      # :low,
      # :high,
      :open_interest
      # :iex_option_symbol
    ])
  end

  def for_date_range(symbol_id, option_symbol, start_date, end_date) do
    __MODULE__
    |> select([:date, :volume, :open, :close, :low, :high, :open_interest, :alternative_volume])
    |> where(symbol_id: ^symbol_id, option_symbol: ^option_symbol)
    |> where([q], q.date >= ^start_date and q.date <= ^end_date)
    |> order_by(:date)
    |> Repo.all()
  end

  def insert_changeset(symbol, option_symbol, date, data) do
    __MODULE__.__struct__()
    |> changeset(%{
      option_symbol: option_symbol,
      date: date,
      volume: data[:volume],
      open: data[:open],
      close: data[:close],
      low: data[:low],
      high: data[:high],
      open_interest: data[:open_interest],
      iex_option_symbol: data[:iex_option_symbol],
      alternative_volume: data[:alternative_volume]
    })
    |> put_assoc(:symbol, symbol)
  end
end
