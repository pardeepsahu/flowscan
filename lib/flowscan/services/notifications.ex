defmodule Flowscan.Services.Notifications do
  @moduledoc false

  import OneSignal.Param
  alias Flowscan.{Highlight, OptionActivity, PushToken}

  @notification_chunk_size 1500
  @android_channel_watchlist "e928e36d-4c49-4942-a827-f42f2f44e5ae"
  @android_channel_highlights "858eb1a5-a913-4439-ad49-ff4a5731ee29"

  def watchlist_notification(%OptionActivity{} = activity, user_ids) do
    player_ids = player_ids_for_user_ids(user_ids)

    new_notification()
    |> put_heading(OptionActivity.notification_display_string(activity))
    |> put_message(OptionActivity.notification_display_details_string(activity))
    |> put_data(:type, "watchlist")
    |> put_data(:deeplink, "flowscan://watchlist/#{activity.id}")
    |> put_ios_sound("nil")
    |> put_thread_id(activity.ticker)
    |> put_android_group(activity.ticker)
    |> set_android_channel_id(@android_channel_watchlist)
    |> chunk_and_notify_player_ids(player_ids)
  end

  def featured_highlight_notification(%Highlight{} = highlight, user_ids) do
    player_ids = player_ids_for_user_ids(user_ids)

    deeplink =
      case highlight.type do
        :option_activity -> "flowscan://highlights/optionActivity/#{highlight.ref_id}"
        :symbol -> "flowscan://highlights/symbol/#{highlight.ref_id}"
        _ -> nil
      end

    new_notification()
    |> put_heading(Highlight.notification_display_string(highlight))
    |> put_message(Highlight.notification_display_details_string(highlight))
    |> put_data(:type, "highlight")
    |> put_data(:deeplink, deeplink)
    |> set_android_channel_id(@android_channel_highlights)
    |> chunk_and_notify_player_ids(player_ids)
  end

  defp new_notification do
    OneSignal.new()
  end

  defp player_ids_for_user_ids(user_ids) do
    PushToken.onesignal_player_ids_for_user_ids(user_ids)
  end

  defp chunk_and_notify_player_ids(%OneSignal.Param{} = notification, player_ids) do
    chunks = player_ids |> Enum.chunk_every(@notification_chunk_size)

    tasks =
      chunks
      |> Enum.map(&Task.async(fn -> notification |> put_player_ids(&1) |> notify() end))

    Task.await_many(tasks, 60_000)
  end
end
