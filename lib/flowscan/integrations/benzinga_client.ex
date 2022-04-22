defmodule Flowscan.Integrations.BenzingaClient do
  @moduledoc false

  use HTTPoison.Base
  alias HTTPoison.Error
  alias HTTPoison.Response
  use NewRelic.Tracer
  require Logger

  @trace {:request, category: :external}
  def option_activity(pagesize, updated \\ nil, date \\ nil) do
    recv_timeout = 20 * 1000

    params = [
      token: api_key(),
      pagesize: pagesize,
      "parameters[updated]": updated,
      "parameters[date]":
        if(date, do: date |> Timex.local() |> Timex.format!("{YYYY}-{0M}-{0D}"), else: nil)
    ]

    url = "/v1/signal/option_activity"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url, [],
           params: params,
           recv_timeout: recv_timeout
         ) do
      {:ok, %Response{status_code: 200, body: []}} ->
        {:ok, []}

      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body["option_activity"]}

      {:error, %Error{reason: reason}} ->
        Logger.error("#{__MODULE__} HTTP error: " <> Atom.to_string(reason))
        {:error, reason}

      response ->
        Logger.error("#{__MODULE__} HTTP error")
        {:error, response}
    end
  end

  def api_key do
    Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:benzinga_api_key]
  end

  def process_request_url(url) do
    "https://api.benzinga.com/api" <> url
  end

  def process_response_body(body) do
    body |> Jason.decode!()
  end

  def process_request_headers(headers) do
    Keyword.merge(headers, Accept: "application/json")
  end
end
