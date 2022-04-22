defmodule Flowscan.Services.Broadcasts do
  @moduledoc false
  alias Flowscan.Highlight
  alias Flowscan.OptionActivity
  alias Flowscan.Services.Notifications
  alias Flowscan.User
  alias Flowscan.Watchlist

  def option_activity(%OptionActivity{} = option_activity) do
    option_activity |> broadcast_option_activity()

    if option_activity.is_buy do
      user_ids =
        Watchlist.notification_user_ids_for_symbol_id(
          option_activity.symbol_id,
          option_activity.is_plus
        )

      option_activity |> Notifications.watchlist_notification(user_ids)
    end
  end

  def featured_highlight(%Highlight{} = highlight) do
    highlight |> broadcast_featured_highlight()

    user_ids = User.notification_user_ids_for_featured_highlights(highlight.is_plus)
    highlight |> Notifications.featured_highlight_notification(user_ids)
  end

  defp broadcast_option_activity(option_activity) do
    # channels =
    #   case option_activity.is_plus do
    #     true ->
    #       # ["plus", "plus:#{option_activity.symbol_id}"]
    #       ["plus"]

    #     _ ->
    #       [
    #         "free",
    #         # "free:#{option_activity.symbol_id}",
    #         "plus"
    #         # "plus:#{option_activity.symbol_id}"
    #       ]
    #   end
    channels = ["free", "plus"]

    Absinthe.Subscription.publish(FlowscanWeb.Endpoint, option_activity, option_activity: channels)
  end

  defp broadcast_featured_highlight(highlight) do
    Absinthe.Subscription.publish(FlowscanWeb.Endpoint, highlight, featured_highlights: ["*"])
  end
end
