defmodule FlowscanWeb.HealthcheckController do
  use FlowscanWeb, :controller
  require Logger
  alias Flowscan.OptionActivity

  def healthcheck(conn, _) do
    _latest = OptionActivity.latest_by_datetime()
    json(conn, %{ok: true})
  end
end
