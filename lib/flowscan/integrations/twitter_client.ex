defmodule Flowscan.Integrations.TwitterClient do
  @moduledoc false

  def configure do
    ExTwitter.configure(
      consumer_key: Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:twitter_consumer_key],
      consumer_secret:
        Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:twitter_consumer_secret],
      access_token: Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:twitter_access_token],
      access_token_secret:
        Application.get_env(:flowscan, FlowscanWeb.Endpoint)[:twitter_access_token_secret]
    )
  end

  def update(body) do
    configure()
    ExTwitter.update(body)
  end
end
