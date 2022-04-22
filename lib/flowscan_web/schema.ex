defmodule FlowscanWeb.Schema do
  @moduledoc false

  use Absinthe.Schema

  alias FlowscanWeb.Resolvers
  import_types(FlowscanWeb.Schema.FeedbackTypes)
  import_types(FlowscanWeb.Schema.FilterRangeTypes)
  import_types(FlowscanWeb.Schema.HighlightCategoryTypes)
  import_types(FlowscanWeb.Schema.HighlightTypes)
  import_types(FlowscanWeb.Schema.OptionActivityTypes)
  import_types(FlowscanWeb.Schema.OptionContractTypes)
  import_types(FlowscanWeb.Schema.PushTokenTypes)
  import_types(FlowscanWeb.Schema.SymbolTypes)
  import_types(FlowscanWeb.Schema.UserTypes)
  import_types(FlowscanWeb.Schema.WatchlistTypes)

  def middleware(middleware, _field, _object) do
    [NewRelic.Absinthe.Middleware] ++ middleware
  end

  input_object :option_activity_filter do
    field :bullish, :boolean
    field :bearish, :boolean
    field :call, :boolean
    field :put, :boolean
    field :sweep, :boolean
    field :large, :boolean
    field :aggressive, :boolean
    # Deprecated in 1.4
    field :above_ask, :boolean
    # Deprecated in 1.4
    field :at_ask, :boolean
    field :at_or_above_ask, :boolean
    # Deprecated in 1.4
    field :at_bid, :boolean
    # Deprecated in 1.4
    field :below_bid, :boolean
    field :at_or_below_bid, :boolean
    field :vol_gt_oi, :boolean
    field :opening, :boolean
    field :strike_gte, :decimal
    field :strike_lte, :decimal
    field :expiration_date_gte, :date
    field :expiration_date_lte, :date
    field :earnings_soon, :boolean
  end

  query do
    @desc "Option activity"
    field :option_activity, list_of(:option_activity) do
      arg(:cursor, :id)
      arg(:symbol_id, :id)
      arg(:watchlist, :boolean)
      arg(:filters, :option_activity_filter)

      resolve(&Resolvers.OptionActivity.list/3)
    end

    @desc "Option activity by ID"
    field :option_activity_details, :option_activity do
      arg(:option_activity_id, non_null(:id))

      resolve(&Resolvers.OptionActivity.by_id/3)
    end

    @desc "Option contract OHLCV"
    field :option_contract_ohlcv, list_of(:option_contract_ohlcv) do
      arg(:symbol_id, non_null(:id))
      arg(:option_symbol, non_null(:string))

      resolve(&Resolvers.OptionContract.ohlcv_3mo/3)
    end

    @desc "Current user"
    field :current_user, :user do
      resolve(&Resolvers.User.current_user/3)
    end

    @desc "Symbol search"
    field :symbol_search, list_of(:symbol) do
      arg(:query, non_null(:string))

      resolve(&Resolvers.Symbol.search/3)
    end

    @desc "Symbol"
    field :symbol, :symbol do
      arg(:symbol_id, non_null(:id))

      resolve(&Resolvers.Symbol.lookup/3)
    end

    @desc "Symbol OHLCV"
    field :symbol_ohlcv, list_of(:symbol_ohlcv) do
      arg(:symbol_id, non_null(:id))

      resolve(&Resolvers.Symbol.ohlcv_3mo/3)
    end

    @desc "Notification settings"
    field :notification_settings, :user_notification_settings do
      resolve(&Resolvers.User.notification_settings/3)
    end

    # DEPRECATED in v1.2
    @desc "Highlight categories"
    field :highlight_categories, list_of(:highlight_category) do
      resolve(&Resolvers.HighlightCategory.list/3)
    end

    # DEPRECATED in v1.2
    @desc "Featured highlights"
    field :featured_highlights, list_of(:highlight) do
      resolve(&Resolvers.Highlight.featured/3)
    end

    @desc "Highlight feed"
    field :highlights, list_of(:highlight) do
      resolve(&Resolvers.Highlight.feed/3)
    end

    @desc "Recent highlights"
    field :recent_highlights, list_of(:highlight) do
      resolve(&Resolvers.Highlight.recent_feed/3)
    end

    @desc "User metadata"
    field :user_meta, :user_meta do
      resolve(&Resolvers.User.user_meta/3)
    end
  end

  mutation do
    field :authenticate, :user do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.User.authenticate/3)
    end

    field :signup, :user do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:platform, :string)

      resolve(&Resolvers.User.signup/3)
    end

    field :refresh_token, :user do
      arg(:refresh_token, non_null(:string))

      resolve(&Resolvers.User.refresh_token/3)
    end

    field :request_password_reset, :request_password_reset do
      arg(:email, non_null(:string))

      resolve(&Resolvers.User.request_password_reset/3)
    end

    field :password_reset, :user do
      arg(:password_reset_token, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.User.password_reset/3)
    end

    field :sign_in_with_apple, :user do
      arg(:identity_token, non_null(:string))

      resolve(&Resolvers.User.sign_in_with_apple/3)
    end

    field :accept_tos, :user do
      resolve(&Resolvers.User.accept_tos/3)
    end

    field :user_meta_interaction, :user_meta do
      arg(:interaction, non_null(:string))

      resolve(&Resolvers.User.user_meta_interaction/3)
    end

    field :add_to_watchlist, :watchlist do
      arg(:symbol_id, non_null(:id))

      resolve(&Resolvers.Watchlist.add/3)
    end

    field :remove_from_watchlist, :watchlist do
      arg(:symbol_id, non_null(:id))

      resolve(&Resolvers.Watchlist.remove/3)
    end

    field :push_token, :push_token do
      arg(:onesignal_player_id, non_null(:string))

      resolve(&Resolvers.PushToken.update/3)
    end

    field :delete_push_token, :push_token do
      arg(:onesignal_player_id, non_null(:string))

      resolve(&Resolvers.PushToken.delete/3)
    end

    field :update_notification_settings, :user_notification_settings do
      arg(:notifications_watchlist, :boolean)
      arg(:notifications_highlights, :boolean)

      resolve(&Resolvers.User.update_notification_settings/3)
    end

    field :verify_user_subscription, :user do
      arg(:qonversion_user_id, :string)

      resolve(&Resolvers.User.verify_user_subscription/3)
    end

    field :submit_feedback, :feedback do
      arg(:body, non_null(:string))
      arg(:sentiment, :string)

      resolve(&Resolvers.Feedback.submit/3)
    end
  end

  subscription do
    field :option_activity, :option_activity do
      config(fn _, context ->
        cond do
          context[:context][:current_user] && context[:context][:current_user].is_plus ->
            {:ok, topic: "plus"}

          context[:context][:current_user] && !context[:context][:current_user].is_plus ->
            # {:ok, topic: "free"}
            {:ok, topic: "plus"}

          true ->
            {:error, "NOT_AUTHENTICATED"}
        end
      end)

      resolve(fn option_activity, _, _ ->
        {:ok, option_activity}
      end)
    end

    # DEPRECATED in v1.2
    field :featured_highlights, :highlight do
      config(fn _, context ->
        if context[:context][:current_user] do
          {:ok, topic: "*", context_id: "global"}
        else
          {:error, "NOT_AUTHENTICATED"}
        end
      end)

      resolve(fn highlight, _, _ -> {:ok, highlight} end)
    end
  end
end
