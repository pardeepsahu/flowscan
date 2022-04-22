defmodule Flowscan.Integrations.QonversionClient do
  @moduledoc false

  use HTTPoison.Base
  alias HTTPoison.Response
  use NewRelic.Tracer
  require Logger

  @trace {:request, category: :external}
  def get_user(user_id, sandbox) do
    url = "/users/#{user_id}"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    headers =
      if sandbox,
        do: %{Authorization: "Bearer #{sandbox_api_key()}"},
        else: %{Authorization: "Bearer #{api_key()}"}

    case __MODULE__.get(url, headers) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body["data"]}

      {:ok, %Response{status_code: 404}} ->
        {:error, :not_found}

      response ->
        {:error, response}
    end
  end

  def api_key do
    Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:qonversion_api_key]
  end

  def sandbox_api_key do
    Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:qonversion_sandbox_api_key]
  end

  def process_request_url(url) do
    "https://api.qonversion.io/v2" <> url
  end

  def process_response_body(body) do
    body |> Jason.decode!()
  end
end
