defmodule FlowscanWeb.AbsintheTelemetry.Start do
  @moduledoc false
  def run(input, _options) do
    NewRelic.start_transaction("GQL", "GQL")
    {:ok, input}
  end
end

defmodule FlowscanWeb.AbsintheTelemetry.Stop do
  @moduledoc false
  def run(input, _options) do
    NewRelic.stop_transaction()
    {:ok, input}
  end
end
