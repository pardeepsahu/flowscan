defmodule FlowscanWeb.Router do
  use FlowscanWeb, :router
  import Plug.BasicAuth

  # scope "/api", FlowscanWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).

  pipeline :api do
    plug FlowscanWeb.Context
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :api

    post "/subscription-webhook", FlowscanWeb.SubscriptionWebhookController, :event
    get "/healthcheck", FlowscanWeb.HealthcheckController, :healthcheck

    if Mix.env() in [:dev, :test] do
      forward "/graphql", Absinthe.Plug,
        schema: FlowscanWeb.Schema,
        json_codec: Jason

      forward "/_graphiql", Absinthe.Plug.GraphiQL,
        schema: FlowscanWeb.Schema,
        socket: FlowscanWeb.AbsintheSocket
    end
  end

  scope "/inapp" do
    pipe_through :browser

    get "/reset-password/:password_reset_token", FlowscanWeb.InappLinkController, :reset_password
  end

  pipeline :protected do
    plug :basic_auth,
      username: System.get_env("PHX_DASHBOARD_USERNAME"),
      password: System.get_env("PHX_DASHBOARD_PASSWORD")
  end

  if Mix.env() in [:prod, :dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/-" do
      pipe_through [:fetch_session, :protect_from_forgery, :protected]

      live_dashboard "/dashboard",
        metrics: FlowscanWeb.Telemetry,
        ecto_repos: [Flowscan.Repo]

      # additional_pages: [option_activity: FlowscanWeb.Live.OptionActivityDashboard]
    end
  end
end
