defmodule Flowscan.Services.SymbolSync do
  @moduledoc false

  require Logger
  alias Flowscan.{Integrations.IexcloudClient, OptionActivity, Repo, Symbol}
  import Ecto.Query

  def run do
    Logger.info("Updating symbols")
    {:ok, symbols} = IexcloudClient.symbols()
    symbols |> Enum.map(&create_or_update/1)
  end

  def create_or_update(data) do
    changeset = %{
      symbol: data["symbol"],
      name: data["name"],
      type: data["type"],
      iex_id: data["iexId"],
      figi: data["figi"],
      is_active: determine_is_active(data),
      is_optionable: determine_is_optionable(data["symbol"])
    }

    case find_existing_symbol(data["iexId"], data["figi"], data["symbol"]) do
      %Symbol{} = symbol ->
        if symbol.symbol != data["symbol"] do
          Logger.warn("Symbol changed: #{symbol.symbol} -> #{data["symbol"]}")
        end

        symbol
        |> Symbol.changeset(changeset)
        |> Repo.update!()

      _ ->
        %Symbol{}
        |> Symbol.changeset(changeset)
        |> Repo.insert!()
    end
  end

  def find_existing_symbol(iex_id, figi, symbol) do
    case iex_id && Repo.get_by(Symbol, iex_id: iex_id) do
      %Symbol{} = symbol ->
        symbol

      _ ->
        case figi && Repo.get_by(Symbol, figi: figi) do
          %Symbol{} = symbol ->
            symbol

          _ ->
            # TODO: This doesn't seem safe. Should check for nil figi, iex_id.
            Repo.get_by(Symbol, symbol: symbol)
        end
    end
  end

  def determine_is_active(data) do
    Enum.member?(["cs", "et", "ad"], data["type"])
  end

  def determine_is_optionable(symbol) do
    OptionActivity
    |> where(ticker: ^symbol)
    |> Repo.aggregate(:count, :id) > 0
  end
end
