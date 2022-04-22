defmodule FlowscanWeb.Resolvers.Feedback do
  @moduledoc false
  alias Flowscan.Email
  alias Flowscan.Feedback
  alias Flowscan.Mailer
  require Logger

  def submit(_parent, %{body: body} = params, %{
        context: %{current_user: current_user}
      }) do
    feedback = Feedback.submit(current_user, body, Map.get(params, :sentiment))
    feedback |> Email.feedback_alert_email() |> Mailer.deliver_later()
    {:ok, %{ok: true}}
  end

  def submit(_parent, _params, _context) do
    {:error, "NOT_AUTHENTICATED"}
  end
end
