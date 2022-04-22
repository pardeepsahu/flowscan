defmodule FlowscanWeb.Schema.FilterRangeTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :strike_range do
    field :min, :decimal
    field :max, :decimal
  end
end
