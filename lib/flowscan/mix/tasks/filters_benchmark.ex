defmodule Mix.Tasks.FiltersBenchmark do
  @moduledoc false

  use Mix.Task
  alias Flowscan.OptionActivity

  @shortdoc "Test filters performance"
  def run(_) do
    Mix.Task.run("app.start")

    filters = [
      :bullish,
      :bearish,
      :call,
      :put,
      :sweep,
      :large,
      :aggressive,
      :above_ask,
      :at_ask,
      :at_or_above_ask,
      :at_bid,
      :below_bid,
      :at_or_below_bid,
      :vol_gt_oi,
      :opening,
      :earnings_soon
    ]

    benchmarks =
      Enum.map(filters, fn filter ->
        {filter,
         fn ->
           filter_param = %{} |> Map.put(filter, true)
           OptionActivity.list(true, filter_param)
         end}
      end)
      |> Map.new()

    Benchee.run(benchmarks)
  end
end
