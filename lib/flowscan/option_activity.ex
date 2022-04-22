defmodule Flowscan.OptionActivity do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Flowscan.EarningsCalendar
  alias Flowscan.Repo
  alias Flowscan.Utils.MarketHours

  schema "option_activity" do
    belongs_to(:symbol, Flowscan.Symbol, foreign_key: :symbol_id)

    field :aggressor_ind, :decimal
    field :ask, :decimal
    field :bid, :decimal

    # == Premium
    field :cost_basis, :decimal

    # Benzinga: date_expiration
    field :expiration_date, :date

    # Benzinga: date + time
    field :datetime, :utc_datetime

    field :description, :string

    # Benzinga: sentiment
    field :is_bullish, :boolean, default: false
    field :is_bearish, :boolean, default: false

    field :is_buy, :boolean, default: false
    field :is_sell, :boolean, default: false

    # Benzinga: underlying_type
    field :is_etf, :boolean, default: false

    field :is_published, :boolean, default: false

    # Benzinga: put_call
    field :is_put, :boolean, default: false

    # Benzinga: option_activity_type
    field :is_sweep, :boolean, default: false

    field :midpoint, :decimal
    field :open_interest, :integer
    field :option_symbol, :string

    field :price, :decimal

    field :underlying_price, :decimal

    field :size, :integer
    field :strike, :decimal
    field :ticker, :string
    field :trade_count, :integer

    # Benzinga: id
    field :benzinga_signal_id, :string

    # Benzinga: updated
    field :benzinga_updated, :integer

    field :volume, :integer

    field :is_plus, :boolean, default: false

    field :signals, {:array, :string}
    field :indicators, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(option_activity, attrs) do
    option_activity
    |> cast(attrs, [
      :datetime,
      :ticker,
      :strike,
      :expiration_date,
      :is_put,
      :is_sweep,
      :is_etf,
      :is_bullish,
      :is_bearish,
      :is_buy,
      :is_sell,
      :indicators,
      :aggressor_ind,
      :cost_basis,
      :price,
      :underlying_price,
      :size,
      :bid,
      :ask,
      :midpoint,
      :trade_count,
      :open_interest,
      :volume,
      :description,
      :option_symbol,
      :benzinga_signal_id,
      :benzinga_updated,
      :is_published,
      :is_plus
    ])
    |> validate_required([
      :datetime,
      :ticker,
      :strike,
      :expiration_date,
      :is_put,
      :is_sweep,
      :is_etf,
      :is_bullish,
      :is_bearish,
      :aggressor_ind,
      :cost_basis,
      :size,
      :trade_count,
      :open_interest,
      :volume,
      :description,
      :option_symbol,
      :benzinga_signal_id,
      :benzinga_updated,
      :is_published,
      :is_plus
    ])
  end

  def classify_changeset(option_activity, attrs) do
    option_activity
    |> cast(attrs, [:is_published, :is_plus, :signals, :indicators, :is_buy, :is_sell])
  end

  def indicators_for_activity(option_activity, signals) do
    indicators = []

    indicators = if option_activity.is_bullish, do: indicators ++ [:bullish], else: indicators
    indicators = if option_activity.is_bearish, do: indicators ++ [:bearish], else: indicators
    indicators = if option_activity.is_sweep, do: indicators ++ [:sweep], else: indicators

    indicators =
      if Decimal.equal?(option_activity.cost_basis, 1_000_000) ||
           Decimal.gt?(option_activity.cost_basis, 1_000_000),
         do: indicators ++ [:whale],
         else: indicators

    indicators =
      if signals && Enum.member?(signals, :aggressive),
        do: indicators ++ [:aggressive],
        else: indicators

    indicators =
      if signals && Enum.member?(signals, :earnings),
        do: indicators ++ [:earnings],
        else: indicators

    indicators
  end

  def notification_display_string(option_activity) do
    emoji = if option_activity.is_put, do: "🟥", else: "🟩"
    expiration = format_expiration_date(option_activity.expiration_date)
    strike = format_strike(option_activity.strike, option_activity.is_put)
    "#{emoji} #{option_activity.ticker} #{expiration} #{strike}"
  end

  def notification_display_details_string(option_activity) do
    premium = format_large_number(option_activity.cost_basis)
    volume = format_large_number(option_activity.volume)
    open_interest = format_large_number(option_activity.open_interest)

    segments = [
      "$#{premium} premium",
      "Vol: #{volume}",
      "OI: #{open_interest}"
    ]

    segments =
      if option_activity.underlying_price,
        do: segments ++ [format_underlying(option_activity.underlying_price)],
        else: segments

    Enum.join(segments, ", ")
  end

  def dte(option_activity) do
    Timex.diff(option_activity.expiration_date, option_activity.datetime, :days)
  end

  def format_strike(strike, is_put) do
    char = if is_put, do: "P", else: "C"
    (strike |> Decimal.normalize() |> Decimal.to_string(:normal)) <> char
  end

  def format_expiration_date(expiration_date) do
    Timex.format!(expiration_date, "{0M}/{0D}/{YY}")
  end

  def format_underlying(underlying) do
    "= #{underlying}"
  end

  def format_large_number(number) do
    cond do
      Enum.member?([:eq, :gt], Decimal.compare(number, 10_000_000)) ->
        (Decimal.div(number, 1_000_000)
         |> Decimal.round(0)
         |> Decimal.normalize()
         |> Decimal.to_string(:normal)) <> "M"

      Enum.member?([:eq, :gt], Decimal.compare(number, 1_000_000)) ->
        (Decimal.div(number, 1_000_000)
         |> Decimal.round(1)
         |> Decimal.normalize()
         |> Decimal.to_string(:normal)) <> "M"

      Enum.member?([:eq, :gt], Decimal.compare(number, 1_000)) ->
        (Decimal.div(number, 1_000)
         |> Decimal.round(0)
         |> Decimal.normalize()
         |> Decimal.to_string(:normal)) <> "k"

      is_integer(number) ->
        Decimal.new(number) |> Decimal.to_string(:normal)

      true ->
        number |> Decimal.to_string(:normal)
    end
  end

  def format_contract_human(option_activity) do
    strike = option_activity.strike |> Decimal.normalize() |> Decimal.to_string(:normal)

    expiration_date =
      if option_activity.expiration_date.year == DateTime.utc_now().year,
        do: Timex.format!(option_activity.expiration_date, "{Mshort} {D}"),
        else: Timex.format!(option_activity.expiration_date, "{Mshort} {D} {YYYY}")

    kind = if option_activity.is_put, do: "puts", else: "calls"
    "#{expiration_date} $#{strike} #{kind}"
  end

  def list(is_plus, filters, cursor \\ nil) do
    __MODULE__
    |> select([
      :id,
      :symbol_id,
      :ticker,
      :datetime,
      :strike,
      :expiration_date,
      :is_put,
      :is_sweep,
      :is_bullish,
      :is_bearish,
      :cost_basis,
      :size,
      :open_interest,
      :volume,
      :underlying_price,
      :is_plus,
      :signals,
      :indicators
    ])
    |> filter_list(is_plus, filters, cursor)
    |> Repo.all()
  end

  defp filter_list(query, is_plus, filters, cursor) do
    initial_limit =
      Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:option_activity_initial_response_size]

    incremental_limit =
      Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:option_activity_response_size]

    limit = if is_nil(cursor), do: initial_limit, else: incremental_limit

    cursor_dt = if cursor, do: Repo.get(__MODULE__, cursor).datetime, else: nil

    # TODO: Restrict Plus filters

    query =
      query
      |> filter_bearish_bullish(filters)
      |> filter_calls_puts(filters)
      |> filter_sweep(filters)
      |> filter_large(filters)
      |> filter_aggressive(filters)
      |> filter_bid_ask(filters)
      |> filter_vol_gt_oi(filters)
      |> filter_opening(filters)
      |> filter_strike(filters)
      |> filter_expiration_date(filters)
      |> filter_earnings_soon(filters)
      # |> (fn q ->
      #       case is_plus do
      #         true -> q
      #         _ -> q |> where(is_plus: false)
      #       end
      #     end).()
      |> (fn q ->
            case Map.has_key?(filters, :symbol_ids) do
              true -> q |> where([q], q.symbol_id in ^filters[:symbol_ids])
              _ -> q |> where(is_etf: false)
            end
          end).()
      |> where(is_published: true)
      |> order_by(desc: :datetime, desc: :id)
      |> limit(^limit)

    if cursor, do: query |> where([q], q.datetime <= ^cursor_dt and q.id < ^cursor), else: query
  end

  defp filter_bearish_bullish(query, filters) do
    query
    |> (fn q ->
          cond do
            Map.get(filters, :bullish) && Map.get(filters, :bearish) ->
              q |> where([q], q.is_bullish == true or q.is_bearish == true)

            Map.get(filters, :bullish) ->
              q |> where([q], is_bullish: true)

            Map.get(filters, :bearish) ->
              q |> where([q], is_bearish: true)

            true ->
              q
          end
        end).()
  end

  defp filter_calls_puts(query, filters) do
    call = Map.get(filters, :call) == true
    put = Map.get(filters, :put) == true

    if (call && put) || (!call && !put) do
      query
    else
      cond do
        call -> query |> where(is_put: false)
        put -> query |> where(is_put: true)
        true -> query
      end
    end
  end

  defp filter_sweep(query, filters) do
    if Map.get(filters, :sweep) == true, do: query |> where([q], is_sweep: true), else: query
  end

  defp filter_large(query, filters) do
    if Map.get(filters, :large) == true,
      do: query |> where([q], q.cost_basis >= 1_000_000),
      else: query
  end

  defp filter_aggressive(query, filters) do
    if Map.get(filters, :aggressive) == true,
      # above_ask helps with performance
      do: query |> with_signal("aggressive"),
      else: query
  end

  defp filter_opening(query, filters) do
    if Map.get(filters, :opening) == true,
      # doesn't use signal, at least for now
      do: query |> where([q], q.size > q.open_interest),
      else: query
  end

  defp filter_bid_ask(query, filters) do
    filters =
      if Map.get(filters, :at_or_above_ask) == true,
        do: Map.merge(filters, %{above_ask: true, at_ask: true}),
        else: filters

    filters =
      if Map.get(filters, :at_or_below_bid) == true,
        do: Map.merge(filters, %{below_bid: true, at_bid: true}),
        else: filters

    bid_ask_filters =
      filters
      |> Enum.filter(fn {k, _v} -> Enum.member?([:above_ask, :at_ask, :at_bid, :below_bid], k) end)
      |> Enum.filter(fn {_k, v} -> v == true end)
      |> Enum.map(fn {k, _v} -> k end)

    if Enum.count(bid_ask_filters) > 0 do
      dynamic =
        Enum.reduce(bid_ask_filters, false, fn filter, acc ->
          dynamic([q], ^Atom.to_string(filter) in q.signals or ^acc)
        end)

      from q in query, where: ^dynamic
    else
      query
    end
  end

  defp filter_vol_gt_oi(query, filters) do
    if Map.get(filters, :vol_gt_oi) == true,
      do: query |> where([q], q.volume > q.open_interest),
      else: query
  end

  defp filter_strike(query, filters) do
    query =
      if Map.get(filters, :strike_gte),
        do: query |> where([q], q.strike >= ^filters[:strike_gte]),
        else: query

    if Map.get(filters, :strike_lte),
      do: query |> where([q], q.strike <= ^filters[:strike_lte]),
      else: query
  end

  defp filter_expiration_date(query, filters) do
    query =
      if Map.get(filters, :expiration_date_gte),
        do: query |> where([q], q.expiration_date >= ^filters[:expiration_date_gte]),
        else: query

    if Map.get(filters, :expiration_date_lte),
      do: query |> where([q], q.expiration_date <= ^filters[:expiration_date_lte]),
      else: query
  end

  defp filter_earnings_soon(query, filters) do
    if Map.get(filters, :earnings_soon) == true do
      # Avoid activity from previous earnings
      cutoff =
        Timex.now() |> Timex.to_date() |> Timex.shift(days: -14) |> MarketHours.beginning_of_day()

      symbol_ids_with_earnings_soon = EarningsCalendar.symbol_ids_with_earnings_soon()

      query
      |> where([q], q.symbol_id in ^symbol_ids_with_earnings_soon and q.datetime >= ^cutoff)
      |> with_signal("earnings")
    else
      query
    end
  end

  def repeat_sweep_count(option_activity) do
    interval = -5

    __MODULE__
    |> where(
      is_sweep: true,
      option_symbol: ^option_activity.option_symbol,
      is_buy: ^option_activity.is_buy,
      is_sell: ^option_activity.is_sell
    )
    |> where([q], q.datetime >= datetime_add(^option_activity.datetime, ^interval, "minute"))
    |> where([q], q.datetime < ^option_activity.datetime)
    |> where([q], q.id != ^option_activity.id)
    |> Repo.aggregate(:count, :id)
  end

  def mark_free!(option_activity) do
    option_activity
    |> changeset(%{is_plus: false})
    |> Repo.update!()
  end

  def is_otm(option_activity) do
    # TODO: This is technically wrong - OTM should be above break even price
    cond do
      is_nil(option_activity.underlying_price) ->
        false

      !option_activity.is_put &&
          Decimal.gt?(option_activity.strike, option_activity.underlying_price) ->
        true

      option_activity.is_put &&
          Decimal.lt?(option_activity.strike, option_activity.underlying_price) ->
        true

      true ->
        false
    end
  end

  def is_itm(option_activity) do
    cond do
      is_nil(option_activity.underlying_price) ->
        false

      !option_activity.is_put &&
          Decimal.lt?(option_activity.strike, option_activity.underlying_price) ->
        true

      option_activity.is_put &&
          Decimal.gt?(option_activity.strike, option_activity.underlying_price) ->
        true

      true ->
        false
    end
  end

  def strike_price_diff_percentage(option_activity) do
    Decimal.sub(option_activity.underlying_price, option_activity.strike)
    |> Decimal.div(option_activity.underlying_price)
    |> Decimal.abs()
  end

  def percent_per_day_to_strike(option_activity) do
    dte = dte(option_activity)

    if dte > 0 && option_activity.underlying_price do
      Decimal.div(strike_price_diff_percentage(option_activity), dte)
    else
      nil
    end
  end

  def with_signal(query, signal) do
    query
    |> where([q], ^signal in q.signals)
  end

  # TODO: This should support an arbitrary number of signals
  def with_one_of_signals(query, signal_one, signal_two) do
    query
    |> where([q], ^signal_one in q.signals or ^signal_two in q.signals)
  end

  def latest_benzinga_updated do
    query = from q in __MODULE__, select: max(q.benzinga_updated)
    query |> Repo.one()
  end

  def latest_by_datetime do
    query = from q in __MODULE__, select: max(q.datetime)
    query |> Repo.one()
  end

  def latest_prior_to(datetime) do
    query = from q in __MODULE__, select: max(q.datetime), where: q.datetime < ^datetime
    query |> Repo.one()
  end

  def strike_range(symbol_id) do
    query =
      from q in __MODULE__,
        select: [min(q.strike), max(q.strike)],
        where: q.symbol_id == ^symbol_id

    query |> Repo.one()
  end

  def get_by_benzinga_signal_id(signal_id) do
    Repo.get_by(__MODULE__, benzinga_signal_id: signal_id)
  end

  def get_by_id(id, is_plus) do
    # case is_plus do
    #   true -> Repo.get_by(__MODULE__, id: id, is_published: true)
    #   _ -> Repo.get_by(__MODULE__, id: id, is_published: true, is_plus: false)
    # end
    Repo.get_by(__MODULE__, id: id, is_published: true)
  end

  def fake_one(symbol) do
    price = (:rand.uniform() * 100) |> Float.round(2)
    size = Enum.random(20..10_000)
    is_bullish = Enum.random(0..1) == 1

    %Flowscan.OptionActivity{
      datetime: DateTime.truncate(Timex.now(), :second),
      symbol: symbol,
      ticker: symbol.symbol,
      strike: Enum.random(5..2000),
      expiration_date: Faker.Date.forward(180),
      is_put: Enum.random(0..1) == 1,
      is_sweep: Enum.random(0..1) == 1,
      is_etf: false,
      is_bullish: is_bullish,
      is_bearish: !is_bullish,
      aggressor_ind: :rand.uniform(),
      price: price,
      bid: Float.round(price - 0.1, 2),
      ask: Float.round(price + 0.1, 2),
      midpoint: price,
      size: size,
      cost_basis: Float.round(size * price, 2),
      trade_count: Enum.random(1..5),
      open_interest: Enum.random(50..1000),
      volume: Enum.random(50_000..100_000_000),
      description: Faker.Lorem.paragraph(),
      option_symbol: Faker.UUID.v4(),
      benzinga_signal_id: Faker.UUID.v4(),
      benzinga_updated: Timex.now() |> Timex.to_unix(),
      is_published: true
    }
  end
end
