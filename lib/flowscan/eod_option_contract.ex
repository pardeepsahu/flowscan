defmodule Flowscan.EodOptionContract do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo
  alias Flowscan.Symbol
  require Logger

  schema "eod_option_contract" do
    field :ask, :decimal
    field :bid, :decimal
    field :close, :decimal
    field :data_updated_at, :utc_datetime
    field :date, :date
    field :high, :decimal
    field :is_complete, :boolean, default: false
    field :low, :decimal
    field :open, :decimal
    field :open_interest, :integer
    field :option_symbol, :string
    field :volume, :integer
    belongs_to(:symbol, Flowscan.Symbol, foreign_key: :symbol_id)

    timestamps()
  end

  @doc false
  def changeset(eod_option_contract, attrs) do
    eod_option_contract
    |> cast(attrs, [
      :option_symbol,
      :date,
      :data_updated_at,
      :is_complete,
      :volume,
      :open_interest,
      :ask,
      :bid,
      :open,
      :close,
      :low,
      :high
    ])
    |> validate_required([
      :option_symbol,
      :date,
      :data_updated_at,
      :is_complete,
      :volume,
      :open_interest
    ])
  end

  def find(option_symbol, date) do
    __MODULE__
    |> where(option_symbol: ^option_symbol, date: ^date)
    |> Repo.one()
  end

  def update_incomplete_from_option_activity(%Flowscan.OptionActivity{} = option_activity) do
    date = option_activity.datetime |> DateTime.to_date()

    existing =
      __MODULE__
      |> where(date: ^date, option_symbol: ^option_activity.option_symbol)
      |> Repo.one()

    cond do
      existing && !existing.is_complete && option_activity.datetime > existing.data_updated_at ->
        existing
        |> changeset(%{
          data_updated_at: option_activity.datetime,
          volume: option_activity.volume
        })
        |> Repo.update()

      !existing ->
        symbol = Repo.get(Symbol, option_activity.symbol_id)

        __MODULE__.__struct__()
        |> changeset(%{
          option_symbol: option_activity.option_symbol,
          date: date,
          data_updated_at: option_activity.datetime,
          is_complete: false,
          volume: option_activity.volume,
          open_interest: option_activity.open_interest
        })
        |> put_assoc(:symbol, symbol)
        |> Repo.insert()

      true ->
        nil
    end
  end

  def update_with_complete_data(data) do
    date =
      DateTime.from_unix!(data["date"], :millisecond)
      |> DateTime.truncate(:second)
      |> DateTime.to_date()

    option_symbol = data["id"]

    case __MODULE__
         |> where(date: ^date, option_symbol: ^option_symbol)
         |> Repo.one() do
      existing = %Flowscan.EodOptionContract{} ->
        if existing.is_complete do
          Logger.error(
            "#{__MODULE__} update_with_complete_data called on a complete record (#{option_symbol})"
          )
        end

        existing
        |> complete_data_changeset(data)
        |> Repo.update()

      _ ->
        symbol = Symbol.find_by_symbol(data["symbol"])

        __MODULE__.__struct__()
        |> complete_data_changeset(data)
        |> put_change(:date, date)
        |> put_change(:option_symbol, option_symbol)
        |> put_assoc(:symbol, symbol)

        # |> Repo.insert()
    end
  end

  defp complete_data_changeset(record, data) do
    data_updated_at =
      DateTime.from_unix!(data["updated"], :millisecond)
      |> DateTime.truncate(:second)

    record
    |> changeset(%{
      ask: data["ask"],
      bid: data["bid"],
      close: data["close"],
      data_updated_at: data_updated_at,
      high: data["high"],
      is_complete: true,
      low: data["low"],
      open: data["open"],
      open_interest: data["openInterest"],
      volume: data["volume"]
    })
  end
end
