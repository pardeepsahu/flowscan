use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :flowscan, Flowscan.Repo,
  username: "postgres",
  password: "123456",
  database: "flowscan_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :flowscan, FlowscanWeb.Endpoint,
  http: [port: 4002],
  server: false,
  option_activity_response_size: 15,
  option_activity_initial_response_size: 20,
  subscription_webhook_token: "xxx"

config :flowscan, Oban, queues: false, plugins: false

config :flowscan, Flowscan.Mailer, adapter: Bamboo.TestAdapter

# Print only warnings and errors during test
config :logger, level: :warn
