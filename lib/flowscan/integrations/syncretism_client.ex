defmodule Flowscan.Integrations.SyncretismClient do
  @moduledoc false

  use HTTPoison.Base
  alias HTTPoison.Response
  use NewRelic.Tracer
  require Logger

  @trace {:request, category: :external}
  def historical(option_symbol) do
    url = "/ops/historical/#{option_symbol}"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body}

      response ->
        {:error, response}
    end
  end

  def process_request_url(url) do
    "https://api.syncretism.io" <> url
  end

  def process_response_body(body) do
    body |> Jason.decode!()
  end
end
