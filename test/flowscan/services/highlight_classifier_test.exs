defmodule Flowscan.Services.HighlightClassifierTest do
  @moduledoc false
  use Flowscan.DataCase
  alias Flowscan.Highlight
  alias Flowscan.OptionActivity
  alias Flowscan.Repo
  alias Flowscan.Services.Broadcasts
  alias Flowscan.Services.HighlightClassifier
  import Mock
  setup [:highlight_categories, :symbols]

  describe "HighlightClassifier" do
    setup_with_mocks([
      {Broadcasts, [], featured_highlight: fn _highlight -> :ok end}
    ]) do
      :ok
    end

    test "candidates/2 picks out aggressive activity, ignores repeat for the day, features opening/size>vol",
         %{
           aggressive_category: aggressive_category,
           aapl: aapl,
           msft: msft,
           pltr: pltr,
           nio: nio
         } do
      now = DateTime.utc_now()

      # Aggressive $50K bet - should expect this to be highlighted
      activity_one =
        insert(:option_activity,
          strike: 320,
          is_put: false,
          expiration_date: ~D[2022-01-01],
          symbol: aapl,
          ticker: aapl.symbol,
          underlying_price: 100,
          is_buy: true,
          is_bullish: true,
          cost_basis: 50_000,
          volume: 1_600_000,
          open_interest: 50_000,
          signals: ["aggressive"],
          datetime: now |> Timex.shift(minutes: -1)
        )

      # Aggressive $50K bet with size>vol - should expect this to be highlighted and featured
      activity_two =
        insert(:option_activity,
          strike: 320,
          is_put: false,
          expiration_date: ~D[2022-01-01],
          symbol: nio,
          ticker: nio.symbol,
          underlying_price: 100,
          is_buy: true,
          is_bullish: true,
          cost_basis: 50_000,
          volume: 10,
          size: 100,
          open_interest: 50_000,
          signals: ["aggressive"],
          datetime: now
        )

      # Identical bet in MSFT, but MSFT already has an aggressive highlight today
      insert(:highlight, category: aggressive_category, ticker: "MSFT")

      insert(:option_activity,
        strike: 320,
        is_put: false,
        expiration_date: ~D[2022-01-01],
        symbol: msft,
        ticker: msft.symbol,
        underlying_price: 100,
        is_buy: true,
        is_bullish: true,
        cost_basis: 50_000,
        signals: ["aggressive"],
        datetime: now
      )

      # $35k bet - too low to highlight
      insert(:option_activity,
        strike: 320,
        is_put: false,
        expiration_date: ~D[2022-01-01],
        symbol: pltr,
        ticker: pltr.symbol,
        underlying_price: 100,
        is_buy: true,
        is_bullish: true,
        cost_basis: 35_000,
        signals: ["aggressive"],
        datetime: now
      )

      cutoff = now |> Timex.shift(minutes: -10)
      highlight_changesets = HighlightClassifier.candidates(cutoff, :aggressive)

      assert length(highlight_changesets) == 2
      highlight_cs_one = Enum.at(highlight_changesets, 0)
      assert highlight_cs_one.valid?
      assert highlight_cs_one.changes[:info] == "Vol 1.6M / OI 50k"
      assert highlight_cs_one.changes[:is_published]
      assert highlight_cs_one.changes[:ref_id] == activity_one.id
      assert highlight_cs_one.changes[:sentiment] == :positive
      assert highlight_cs_one.changes[:subtitle] == "$50k"
      assert highlight_cs_one.changes[:ticker] == "AAPL"
      assert highlight_cs_one.changes[:title] == "01/01/22 320C"
      assert highlight_cs_one.changes[:type] == :option_activity
      refute highlight_cs_one.changes[:is_featured]

      highlight_cs_two = Enum.at(highlight_changesets, 1)
      assert highlight_cs_two.changes[:ref_id] == activity_two.id
      assert highlight_cs_two.changes[:is_featured]
    end

    test "candidates/2 highlights 2+ repeat sweep activities", %{
      aapl: aapl,
      msft: msft
    } do
      now = DateTime.utc_now()

      # Two repeat sweeps for the same contracts - highlight
      insert(:option_activity,
        strike: 320,
        is_put: false,
        expiration_date: ~D[2022-01-01],
        symbol: aapl,
        ticker: aapl.symbol,
        is_bullish: true,
        is_sweep: true,
        is_buy: true,
        signals: ["repeat_sweep", "above_ask"],
        datetime: now,
        option_symbol: "AAPL320C"
      )

      insert(:option_activity,
        strike: 320,
        is_put: false,
        expiration_date: ~D[2022-01-01],
        symbol: aapl,
        ticker: aapl.symbol,
        is_bullish: true,
        is_sweep: true,
        is_buy: true,
        signals: ["repeat_sweep", "above_ask"],
        datetime: now,
        option_symbol: "AAPL320C"
      )

      # Different strikes, doesn't count
      insert(:option_activity,
        strike: 310,
        is_put: false,
        expiration_date: ~D[2022-01-01],
        symbol: msft,
        ticker: msft.symbol,
        is_sweep: true,
        is_buy: true,
        signals: ["repeat_sweep", "above_ask"],
        datetime: now,
        option_symbol: "MSFT310C"
      )

      insert(:option_activity,
        strike: 320,
        is_put: false,
        expiration_date: ~D[2022-01-01],
        symbol: msft,
        ticker: msft.symbol,
        is_sweep: true,
        is_buy: true,
        signals: ["repeat_sweep", "above_ask"],
        datetime: now,
        option_symbol: "MSFT320C"
      )

      cutoff = now |> Timex.shift(minutes: -10)
      highlight_changesets = HighlightClassifier.candidates(cutoff, :repeat_sweeps)

      assert length(highlight_changesets) == 1
      highlight_cs = hd(highlight_changesets)
      assert highlight_cs.valid?
      assert highlight_cs.changes[:info] == "Repeat sweeps"
      assert highlight_cs.changes[:is_published]
      assert highlight_cs.changes[:ref_id] == aapl.id
      assert highlight_cs.changes[:sentiment] == :positive
      assert highlight_cs.changes[:subtitle] == nil
      assert highlight_cs.changes[:ticker] == "AAPL"
      assert highlight_cs.changes[:title] == "01/01/22 320C"
      assert highlight_cs.changes[:type] == :symbol
    end

    test "candidates/2 picks $1M+ non-ETF bets and highlights opening/size>vol activity", %{
      aapl: aapl,
      msft: msft
    } do
      now = DateTime.utc_now()

      activity_one =
        insert(:option_activity,
          strike: 320,
          is_put: false,
          expiration_date: ~D[2022-01-01],
          symbol: aapl,
          ticker: aapl.symbol,
          is_buy: true,
          is_bullish: true,
          is_etf: false,
          cost_basis: 1_200_000,
          underlying_price: 100.29,
          volume: 13_200,
          open_interest: 500,
          datetime: now |> Timex.shift(minutes: -1),
          signals: ["above_ask", "opening"]
        )

      activity_two =
        insert(:option_activity,
          strike: 320,
          is_put: false,
          expiration_date: ~D[2022-01-01],
          symbol: msft,
          ticker: msft.symbol,
          is_buy: true,
          is_bullish: true,
          is_etf: false,
          cost_basis: 1_200_000,
          underlying_price: 100.29,
          volume: 100,
          size: 300,
          open_interest: 500,
          datetime: now,
          signals: ["at_ask"]
        )

      insert(:option_activity, is_buy: false, cost_basis: 2_000_000)
      insert(:option_activity, is_etf: true, cost_basis: 2_000_000)

      cutoff = now |> Timex.shift(minutes: -10)
      highlight_changesets = HighlightClassifier.candidates(cutoff, :whales)

      assert length(highlight_changesets) == 2
      highlight_cs_one = Enum.at(highlight_changesets, 0)
      assert highlight_cs_one.valid?
      assert highlight_cs_one.changes[:info] == "Opening order"
      assert highlight_cs_one.changes[:is_published]
      assert highlight_cs_one.changes[:ref_id] == activity_one.id
      assert highlight_cs_one.changes[:sentiment] == :positive
      assert highlight_cs_one.changes[:subtitle] == "$1.2M"
      assert highlight_cs_one.changes[:ticker] == "AAPL"
      assert highlight_cs_one.changes[:title] == "01/01/22 320C"
      assert highlight_cs_one.changes[:type] == :option_activity
      assert highlight_cs_one.changes[:is_featured]

      highlight_cs_two = Enum.at(highlight_changesets, 1)
      assert highlight_cs_two.changes[:ref_id] == activity_two.id
      assert highlight_cs_two.changes[:is_featured]
    end

    test "publish!/1 inserts highlights" do
      cs = [
        Flowscan.Factory.highlight_factory(),
        Flowscan.Factory.highlight_factory()
      ]

      HighlightClassifier.publish!(cs)
      highlights = Repo.all(Highlight)
      highlight = hd(highlights)
      assert Enum.count(highlights) == 2
      assert highlight.is_published
    end

    test "publish!/1 broadcasts featured highlights" do
      highlight = %{Flowscan.Factory.highlight_factory() | is_featured: true}
      HighlightClassifier.publish!([highlight])
      assert called(Broadcasts.featured_highlight(:_))
    end

    test "publish!/1 marks option activity free if there haven't been any highlights in 1hr" do
      activity = insert(:option_activity, is_plus: true)

      highlight =
        Flowscan.Factory.highlight_factory()
        |> Map.merge(%{
          option_activity_id: activity.id,
          type: :option_activity,
          option_activity: activity,
          is_plus: true
        })

      HighlightClassifier.publish!([highlight])
      highlight = Repo.one(Highlight)
      activity = Repo.get(OptionActivity, activity.id)

      refute highlight.is_plus
      refute activity.is_plus
    end
  end

  defp highlight_categories(_) do
    %{
      aggressive_category: insert(:highlight_category, slug: "aggressive"),
      repeat_sweep_category: insert(:highlight_category, slug: "repeat_sweeps"),
      whales_category: insert(:highlight_category, slug: "whales")
    }
  end

  defp symbols(_) do
    %{
      aapl: insert(:symbol, symbol: "AAPL"),
      msft: insert(:symbol, symbol: "MSFT"),
      pltr: insert(:symbol, symbol: "PLTR"),
      nio: insert(:symbol, symbol: "NIO")
    }
  end
end
