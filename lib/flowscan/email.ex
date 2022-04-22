defmodule Flowscan.Email do
  @moduledoc false

  alias Flowscan.Feedback
  alias Flowscan.Repo
  import Bamboo.Email

  def password_reset_email(%Flowscan.User{} = user) do
    link = "https://api.flowscan.com/inapp/reset-password/#{user.password_reset_token}"

    html_body =
      "To change your password, open the following link on your mobile device: <a href=\"#{link}\">Reset password</a>"

    base_email()
    |> to(user.email)
    |> subject("Flowscan - Password Reset")
    |> html_body(html_body)
  end

  def feedback_alert_email(%Flowscan.Feedback{} = feedback) do
    feedback = Repo.get(Feedback, feedback.id) |> Repo.preload(:user)
    plus_str = if feedback.user.is_plus, do: " [plus]", else: ""
    user = "#{feedback.user.id}#{plus_str} <#{feedback.user.email}>"

    sentiment =
      case feedback.sentiment do
        :positive -> "👍"
        :negative -> "👎"
        _ -> ""
      end

    body = Enum.join([user, sentiment, feedback.body], "\n\n")

    base_email()
    |> to("support@flowscan.com")
    |> subject("Feedback submission")
    |> text_body(body)
  end

  defp base_email do
    new_email()
    |> from("Flowscan <support@flowscan.com>")
  end
end
