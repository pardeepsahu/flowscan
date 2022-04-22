defmodule FlowscanWeb.Graphql.FeedbackTest do
  @moduledoc false
  use FlowscanWeb.ConnCase
  use Bamboo.Test
  import Flowscan.AbsintheHelpers
  alias Flowscan.Feedback
  alias Flowscan.Repo

  setup [:setup_user]

  @submit_feedback_mutation """
  mutation submitFeedback($body: String!, $sentiment: String) {
    submitFeedback(body: $body, sentiment: $sentiment) {
        ok
    }
  }
  """

  test "submit feedback with sentiment", %{conn: conn, user: user} do
    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@submit_feedback_mutation, %{body: "Testing", sentiment: "positive"}))

    data = json_response(res, 200)["data"]["submitFeedback"]
    assert data["ok"]

    feedback = Feedback |> Repo.one()
    assert feedback.user_id == user.id
    assert feedback.body == "Testing"
    assert feedback.sentiment == :positive

    expected_email = Flowscan.Email.feedback_alert_email(feedback)
    assert_delivered_email(expected_email)
  end

  test "submit feedback without sentiment", %{conn: conn, user: user} do
    res =
      conn
      |> authenticate_conn(user)
      |> graphql(query(@submit_feedback_mutation, %{body: "Testing again"}))

    data = json_response(res, 200)["data"]["submitFeedback"]
    assert data["ok"]

    feedback = Feedback |> Repo.one()
    assert feedback.user_id == user.id
    assert feedback.body == "Testing again"
    refute feedback.sentiment

    expected_email = Flowscan.Email.feedback_alert_email(feedback)
    assert_delivered_email(expected_email)
  end

  test "unauthenticated user", %{conn: conn} do
    res =
      conn
      |> graphql(query(@submit_feedback_mutation, %{body: "Testing again"}))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  defp setup_user(_) do
    %{
      user: insert(:user)
    }
  end

  # This should be moved out to helpers
  defp graphql(conn, query) do
    conn |> post("/graphql", query)
  end
end
