defmodule FlowscanWeb.Schema.OptionContractTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  object :option_contract_ohlcv do
    field :date, :date
    # field :volume, :integer
    field :open, :decimal
    field :open_interest, :integer
    field :close, :decimal
    field :low, :decimal
    field :high, :decimal

    field :volume, :integer do
      resolve(fn data, _, _ ->
        volume = if data.alternative_volume, do: data.alternative_volume, else: data.volume
        {:ok, volume}
      end)
    end
  end
end
