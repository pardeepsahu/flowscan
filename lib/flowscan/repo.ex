defmodule Flowscan.Repo do
  use Ecto.Repo,
    otp_app: :flowscan,
    adapter: Ecto.Adapters.Postgres
end
