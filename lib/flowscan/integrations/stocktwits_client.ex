defmodule Flowscan.Integrations.StocktwitsClient do
  @moduledoc false

  use HTTPoison.Base
  alias HTTPoison.Response
  use NewRelic.Tracer
  require Logger

  @trace {:request, category: :external}
  def create_message(body, sentiment \\ nil) do
    url = "/messages/create.json"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "POST",
      component: "#{__MODULE__}"
    )

    post_body = %{body: body}
    post_body = if sentiment, do: Map.put(post_body, :sentiment, sentiment), else: post_body
    post_body = post_body |> URI.encode_query()

    case __MODULE__.post(url, post_body) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body}

      response ->
        {:error, response}
    end
  end

  def access_token do
    Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:stocktwits_access_token]
  end

  def create_message_api_url do
    Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:stocktwits_create_message_api_url]
  end

  def process_request_url(_url) do
    token = access_token()
    create_message_api_url() <> "?access_token=#{token}"
  end

  def process_response_body(body) do
    body |> Jason.decode!()
  end

  def process_request_headers(headers) do
    Keyword.merge(headers, Accept: "application/json")
    |> Keyword.merge("Content-Type": "application/x-www-form-urlencoded")
  end
end
