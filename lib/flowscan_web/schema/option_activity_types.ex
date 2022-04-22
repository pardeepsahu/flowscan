defmodule FlowscanWeb.Schema.OptionActivityTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias Flowscan.EarningsCalendar

  import_types(Absinthe.Type.Custom)

  object :option_activity do
    field :datetime, non_null(:datetime) do
      resolve(fn option_activity, _, _ ->
        {:ok, Timex.Timezone.convert(option_activity.datetime, "America/New_York")}
      end)
    end

    field :id, :id
    field :symbol_id, :integer
    field :ticker, :string
    field :strike, :string
    field :expiration_date, :date
    field :is_put, :boolean
    field :is_sweep, :boolean
    field :is_bullish, :boolean
    field :is_bearish, :boolean
    field :is_buy, :boolean
    field :is_sell, :boolean
    field :cost_basis, :string
    field :underlying_price, :string
    field :volume, :integer
    field :open_interest, :integer
    field :is_plus, :boolean
    field :indicators, list_of(:string)

    # Used in details view
    field :size, :integer
    field :option_symbol, :string

    field :symbol, :symbol do
      resolve(fn option_activity, _, _ ->
        {:ok, Flowscan.Symbol.find_by_id(option_activity.symbol_id)}
      end)
    end

    field :is_repeat_sweep, :boolean do
      resolve(fn option_activity, _, _ ->
        {:ok, option_activity.signals && Enum.member?(option_activity.signals, "repeat_sweep")}
      end)
    end

    field :above_ask, :boolean do
      resolve(fn option_activity, _, _ ->
        {:ok,
         option_activity.signals &&
           Enum.member?(option_activity.signals, "above_ask")}
      end)
    end

    field :below_bid, :boolean do
      resolve(fn option_activity, _, _ ->
        {:ok,
         option_activity.signals &&
           Enum.member?(option_activity.signals, "below_bid")}
      end)
    end

    field :at_ask, :boolean do
      resolve(fn option_activity, _, _ ->
        {:ok,
         option_activity.signals &&
           Enum.member?(option_activity.signals, "at_ask")}
      end)
    end

    field :at_bid, :boolean do
      resolve(fn option_activity, _, _ ->
        {:ok,
         option_activity.signals &&
           Enum.member?(option_activity.signals, "at_bid")}
      end)
    end

    field :is_aggressive, :boolean do
      resolve(fn option_activity, _, _ ->
        {:ok, option_activity.signals && Enum.member?(option_activity.signals, "aggressive")}
      end)
    end

    field :earnings, :date do
      resolve(fn option_activity, _, _ ->
        earnings =
          case option_activity.indicators && Enum.member?(option_activity.indicators, "earnings") do
            true ->
              case EarningsCalendar.upcoming_earnings(
                     option_activity.symbol_id,
                     option_activity.datetime
                   ) do
                %EarningsCalendar{} = ec ->
                  ec.confirmed_earnings_date

                _ ->
                  nil
              end

            _ ->
              nil
          end

        {:ok, earnings}
      end)
    end
  end
end
