defmodule FlowscanWeb.Schema.WatchlistTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :watchlist do
    field :ok, :boolean
  end
end
