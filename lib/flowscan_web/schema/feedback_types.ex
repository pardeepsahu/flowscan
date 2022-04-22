defmodule FlowscanWeb.Schema.FeedbackTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :feedback do
    field :ok, :boolean
  end
end
