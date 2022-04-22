defmodule Flowscan.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :flowscan,
      version: "0.1.0",
      elixir: "~> 1.12.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Flowscan.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :bamboo,
        :bamboo_smtp,
        :os_mon,
        :cachex,
        :poison
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.7"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.16.4"},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:absinthe, "~> 1.6.6"},
      {:absinthe_plug, "~> 1.5.8"},
      {:absinthe_phoenix, "~> 2.0.2"},
      {:cors_plug, "~> 2.0"},
      {:timex, "~> 3.5"},
      {:guardian, "~> 2.0"},
      {:argon2_elixir, "~> 2.0"},
      {:bamboo, "~> 1.6"},
      {:bamboo_smtp, "~> 3.0.0"},
      {:faker, "~> 0.15"},
      {:httpoison, "~> 1.7", override: true},
      {:sentry, "~> 8.0"},
      {:ecto_psql_extras, "~> 0.7.1"},
      {:joken, "~> 2.0"},
      {:joken_jwks, "~> 1.1.0"},
      {:oauther, "~> 1.1"},
      {:extwitter, "~> 0.12.2"},
      {:cachex, "~> 3.3"},
      {:oban, "~> 2.7"},
      {:nimble_csv, "1.1.0"},
      # {:libcluster, "~> 3.2"},
      {:new_relic_agent, "~> 1.0"},
      {:new_relic_absinthe, "~> 0.0.4"},
      {:one_signal,
       github: "sandisk/one_signal", ref: "3cf8c3fcdabe112f66d2743b6f576a8e8db52633"},
      {:poison, "~> 3.1.0"},
      {:benchee, "~> 1.0"},
      # {:benchee, "~> 1.0", only: :dev},
      {:ex_machina, "~> 2.4", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      {:credo, "~> 1.5.0-rc.2", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
