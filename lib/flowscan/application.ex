defmodule Flowscan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      # {Cluster.Supervisor, [topologies, [name: Flowscan.ClusterSupervisor]]},
      # Start the Ecto repository
      Flowscan.Repo,
      # Start the Telemetry supervisor
      FlowscanWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Flowscan.PubSub},
      # Start the Endpoint (http/https)
      FlowscanWeb.Endpoint,
      {Absinthe.Subscription, FlowscanWeb.Endpoint},
      {FlowscanWeb.SignInWithAppleTokenFetchStrategy, time_interval: 60_000 * 10},
      # Start a worker by calling: Flowscan.Worker.start_link(arg)
      # {Flowscan.Worker, arg}
      {Oban, oban_config()},
      {Cachex, name: :data}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Flowscan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FlowscanWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:flowscan, Oban)
  end
end
