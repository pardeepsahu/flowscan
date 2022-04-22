defmodule Flowscan.Services.SocialPostingTest do
  @moduledoc false
  use Flowscan.DataCase
  alias Flowscan.Repo
  alias Flowscan.Services.SocialPosting
  alias Flowscan.SocialPost

  setup [:highlight_categories]

  describe "SocialPosting" do
    test "create_from_highlights/1 create SocialPost records, ignores repeat tickers for 2h", %{
      aggressive_category: aggressive_category,
      whales_category: whales_category
    } do
      now = DateTime.utc_now()
      three_hours_ago = now |> Timex.shift(hours: -3)
      hour_and_a_half_ago = now |> Timex.shift(minutes: -90)

      insert(:social_post, ticker: "AAPL", inserted_at: three_hours_ago)
      insert(:social_post, ticker: "MSFT", inserted_at: hour_and_a_half_ago)

      highlights = [
        insert(:highlight,
          ticker: "AAPL",
          category: whales_category
        ),
        insert(:highlight, ticker: "MSFT", category: aggressive_category)
      ]

      highlights |> SocialPosting.create_from_highlights()
      assert SocialPost |> where(ticker: "AAPL") |> Repo.all() |> length() == 2
      assert SocialPost |> where(ticker: "MSFT") |> Repo.all() |> length() == 1
    end
  end

  defp highlight_categories(_) do
    %{
      aggressive_category: insert(:highlight_category, slug: "aggressive"),
      whales_category: insert(:highlight_category, slug: "whales")
    }
  end
end
