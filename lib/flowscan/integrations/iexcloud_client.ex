defmodule Flowscan.Integrations.IexcloudClient do
  @moduledoc false

  use HTTPoison.Base
  alias HTTPoison.Response
  use NewRelic.Tracer

  @trace {:request, category: :external}
  def symbols do
    url = "/ref-data/symbols"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      response -> {:error, response}
    end
  end

  @trace {:request, category: :external}
  def batch_quotes(tickers) do
    ticker_str = tickers |> Enum.join(",")
    url = "/stock/market/batch?types=quote&symbols=#{ticker_str}"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %Response{status_code: 404}} -> {:ok, []}
      response -> {:error, response}
    end
  end

  @trace {:request, category: :external}
  def options_chart(option_symbol, range) do
    url = "/options/#{option_symbol}/chart?range=#{range}"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %Response{status_code: 404}} -> {:ok, []}
      response -> {:error, response}
    end
  end

  @trace {:request, category: :external}
  def eod_options(ticker, expiration) do
    expiration_param = Timex.format!(expiration, "{0M}{YYYY}")
    url = "/stock/#{ticker}/options/#{expiration_param}"

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      response -> {:error, response}
    end
  end

  @trace {:request, category: :external}
  def historical_prices(ticker, range, date \\ nil) do
    url =
      if date do
        date_str = Timex.format!(date, "{YYYY}{0M}{0D}")
        "/stock/#{ticker}/chart/#{range}/#{date_str}"
      else
        "/stock/#{ticker}/chart/#{range}"
      end

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      response -> {:error, response}
    end
  end

  @trace {:request, category: :external}
  def stats(ticker, stat \\ nil) do
    url =
      if stat do
        "/stock/#{ticker}/stats/#{stat}"
      else
        "/stock/#{ticker}/stats/"
      end

    NewRelic.set_span(:http,
      url: process_request_url(url),
      method: "GET",
      component: "#{__MODULE__}"
    )

    case __MODULE__.get(url) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      response -> {:error, response}
    end
  end

  def benzinga_option_symbol_to_iex(ticker, option_symbol) do
    String.replace_prefix(option_symbol, ticker, ticker <> "20")
  end

  def api_key do
    Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:iexcloud_api_key]
  end

  def process_request_url(url) do
    "https://cloud.iexapis.com/v1" <> url
  end

  def process_response_body(body) do
    case body do
      "Unknown symbol" -> nil
      _ -> body |> Jason.decode!()
    end
  end

  def process_request_options(options), do: [params: [token: api_key()]] ++ options
end
