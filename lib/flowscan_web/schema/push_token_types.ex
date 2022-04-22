defmodule FlowscanWeb.Schema.PushTokenTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :push_token do
    field :ok, :boolean
  end
end
