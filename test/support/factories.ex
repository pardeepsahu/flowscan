defmodule Flowscan.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Flowscan.Repo
  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("")

  def user_factory do
    %Flowscan.User{
      email: Faker.Internet.email(),
      password: "passweird",
      password_hash: Argon2.hash_pwd_salt("passweird")
    }
  end

  def option_activity_factory do
    symbol = build(:symbol)
    Flowscan.OptionActivity.fake_one(symbol)
  end

  def symbol_factory do
    %Flowscan.Symbol{
      symbol: string_of_length(4),
      name: Faker.Company.name(),
      is_active: true,
      iex_id: Faker.UUID.v4(),
      type: "cs"
    }
  end

  def watchlist_factory do
    %Flowscan.Watchlist{
      user: build(:user),
      symbol: build(:symbol)
    }
  end

  def push_token_factory do
    %Flowscan.PushToken{
      user: build(:user),
      onesignal_player_id: Faker.UUID.v4()
    }
  end

  def subscription_factory do
    %Flowscan.Subscription{
      entitlement: "Plus",
      starts: Faker.DateTime.backward(14),
      expires: Faker.DateTime.forward(14),
      platform: "app_store",
      platform_product_id: "pro_monthly_29_7d_trial",
      qonversion_user_id: Faker.UUID.v4(),
      qonversion_purchase_original_id: Faker.UUID.v4(),
      current_period_start: Faker.DateTime.backward(14),
      current_period_end: Faker.DateTime.forward(14),
      current_period_type: "normal",
      renew_state: "will_renew",
      user: build(:user)
    }
  end

  def highlight_category_factory do
    %Flowscan.HighlightCategory{
      title: Faker.Pizza.pizza(),
      description: Faker.Lorem.sentence(),
      slug: Faker.Internet.domain_name(),
      weight: 0,
      is_active: true
    }
  end

  def highlight_factory do
    %Flowscan.Highlight{
      ref_id: :rand.uniform(2_147_483_647),
      type: Enum.random([:option_activity, :symbol]),
      ticker: Faker.Lorem.word(),
      title: Faker.Lorem.sentence(),
      subtitle: Faker.Lorem.sentence(),
      info: Faker.Lorem.sentence(),
      sentiment: Enum.random([:positive, :negative, :neutral, :unusual]),
      is_plus: false,
      is_published: true,
      is_featured: false,
      category: build(:highlight_category),
      datetime: Faker.DateTime.backward(14) |> DateTime.truncate(:second),
      option_activity: build(:option_activity)
    }
  end

  def social_post_factory do
    %Flowscan.SocialPost{
      body: Faker.Lorem.sentence(),
      sentiment: Enum.random(["positive", "negative", "neutral", "unusual"]),
      ticker: Faker.Lorem.word(),
      type: Enum.random(["repeat_sweeps", "whales", "aggressive"]),
      is_published: false
    }
  end

  def eod_option_contract_factory do
    %Flowscan.EodOptionContract{
      option_symbol: Faker.UUID.v4(),
      date: Faker.Date.forward(30),
      symbol: build(:symbol),
      data_updated_at: Faker.DateTime.backward(14),
      is_complete: false,
      volume: Enum.random(0..1_000_000),
      open_interest: Enum.random(0..1_000_000)
    }
  end

  def symbol_ohlcv_factory do
    %Flowscan.SymbolOhlcv{
      symbol: build(:symbol),
      date: Faker.Date.forward(30),
      volume: Enum.random(0..1_000_000),
      open: (:rand.uniform() * 100) |> Float.round(2),
      close: (:rand.uniform() * 100) |> Float.round(2),
      high: (:rand.uniform() * 100) |> Float.round(2),
      low: (:rand.uniform() * 100) |> Float.round(2)
    }
  end

  defp string_of_length(length) do
    Enum.reduce(1..length, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end
end
