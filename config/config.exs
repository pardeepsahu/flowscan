# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :flowscan,
  ecto_repos: [Flowscan.Repo]

# Configures the endpoint
config :flowscan, FlowscanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "BXBKd8DLcZLFN/O4JvYR3Mm2+fmm82hjftCAVGWHjkbRAwBhai+IooW1X9aIunhi",
  render_errors: [view: FlowscanWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Flowscan.PubSub,
  live_view: [signing_salt: "mnHqesoe"],
  ttl_access_token: {System.get_env("TTL_ACCESS_TOKEN") || 20_160, :minutes},
  ttl_refresh_token: {System.get_env("TTL_REFRESH_TOKEN") || 20_160, :minutes},
  option_activity_response_size: System.get_env("OPTION_ACTIVITY_SIZE") || 30,
  option_activity_initial_response_size: System.get_env("OPTION_INITIAL_ACTIVITY_SIZE") || 80,
  watchlist_free_limit: 3,
  iexcloud_api_key: System.get_env("IEXCLOUD_API_KEY"),
  benzinga_api_key: System.get_env("BENZINGA_API_KEY"),
  subscription_webhook_token: System.get_env("SUBSCRIPTION_WEBHOOK_TOKEN"),
  qonversion_api_key: System.get_env("QONVERSION_API_KEY"),
  qonversion_sandbox_api_key: System.get_env("QONVERSION_SANDBOX_API_KEY"),
  stocktwits_access_token: System.get_env("STOCKTWITS_ACCESS_TOKEN"),
  twitter_consumer_key: System.get_env("TWITTER_CONSUMER_KEY"),
  twitter_consumer_secret: System.get_env("TWITTER_CONSUMER_SECRET"),
  twitter_access_token: System.get_env("TWITTER_ACCESS_TOKEN"),
  twitter_access_token_secret: System.get_env("TWITTER_ACCESS_TOKEN_SECRET"),
  stocktwits_posting_enabled: System.get_env("STOCKTWITS_POSTING_ENABLED") == "true",
  stocktwits_create_message_api_url: System.get_env("STOCKTWITS_CREATE_MESSAGE_API_URL"),
  twitter_posting_enabled: System.get_env("TWITTER_POSTING_ENABLED") == "true",
  stock_data_fresh_ttl: System.get_env("STOCK_DATA_FRESH_TTL") || 60,
  alpha_vantage_api_key: System.get_env("ALPHA_VANTAGE_API_KEY")

config :flowscan, Oban,
  repo: Flowscan.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 86_400},
    {Oban.Plugins.Cron,
     crontab: [
       # Every minute during trading+buffer (11-22)
       {"*/1 11-22 * * 1-5", Flowscan.Workers.OptionActivitySync},
       # Every five minutes during trading+buffer
       {"*/5 11-22 * * 1-5", Flowscan.Workers.HighlightClassifier},
       {"*/5 11-22 * * 1-5", Flowscan.Workers.SocialPosting},
       # Once a day on weekdays
       {"0 13 * * 1-5", Flowscan.Workers.SymbolSync},
       {"10 13 * * 1-5", Flowscan.Workers.EarningsCalendarSync},
       # Once a day, every day
       {"0 3 * * *", Flowscan.Workers.ExpiredPlusJanitor}
     ]}
  ],
  queues: [default: 1, option_activity: 1, data: 2]

config :one_signal, OneSignal,
  api_key: System.get_env("ONESIGNAL_API_KEY"),
  app_id: System.get_env("ONESIGNAL_APP_ID")

# Configures Elixir's Logger
config :logger,
  backends: [:console]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :flowscan, Flowscan.Guardian,
  issuer: "flowscan",
  secret_key: System.get_env("SECRET_KEY")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
