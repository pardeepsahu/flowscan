defmodule FlowscanWeb.Schema.SymbolTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias Flowscan.OptionActivity
  alias Flowscan.Watchlist

  object :symbol do
    field :id, :integer
    field :symbol, :string
    field :name, :string

    field :in_watchlist, :boolean do
      resolve(fn symbol, _, %{context: context} ->
        {:ok, Watchlist.in_watchlist?(context[:current_user], symbol)}
      end)
    end

    field :strike_range, :strike_range do
      resolve(fn symbol, _, _ ->
        {:ok, strike_range_for_symbol(symbol)}
      end)
    end
  end

  object :symbol_ohlcv do
    field :date, :date
    field :volume, :integer
    field :open, :decimal
    field :close, :decimal
    field :low, :decimal
    field :high, :decimal
  end

  defp strike_range_for_symbol(symbol) do
    key = "strike_range:#{symbol.id}"

    case Cachex.get!(:data, key) do
      [min, max] ->
        %{min: min, max: max}

      _ ->
        [min, max] = OptionActivity.strike_range(symbol.id)
        Cachex.set!(:data, key, [min, max], ttl: :timer.hours(24))
        %{min: min, max: max}
    end
  end
end
