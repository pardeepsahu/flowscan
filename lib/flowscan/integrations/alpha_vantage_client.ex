defmodule Flowscan.Integrations.AlphaVantageClient do
  @moduledoc false

  use HTTPoison.Base
  use NewRelic.Tracer
  alias HTTPoison.Response
  alias NimbleCSV.RFC4180, as: CSV
  require Logger

  @trace {:request, category: :external}
  def earnings_calendar do
    url = "/query"

    params = [
      function: "EARNINGS_CALENDAR",
      horizon: "3month",
      apikey: api_key()
    ]

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url, [], params: params) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body}

      response ->
        {:error, response}
    end
  end

  def process_request_url(url) do
    "https://www.alphavantage.co" <> url
  end

  def process_response_body(body) do
    body
    |> CSV.parse_string()
    |> Enum.map(fn row ->
      %{
        ticker: Enum.at(row, 0),
        name: Enum.at(row, 1),
        report_date: Enum.at(row, 2) |> Date.from_iso8601!(),
        fiscal_date_ending: Enum.at(row, 3) |> Date.from_iso8601!(),
        estimate: if(Enum.at(row, 4) == "", do: nil, else: Enum.at(row, 4) |> Decimal.new()),
        currency: Enum.at(row, 5)
      }
    end)
  end

  def api_key do
    Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:alpha_vantage_api_key]
  end
end
