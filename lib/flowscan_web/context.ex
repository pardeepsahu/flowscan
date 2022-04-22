defmodule FlowscanWeb.Context do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  alias Flowscan.{Guardian, User}

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claim} <- Guardian.decode_and_verify(token),
         user when not is_nil(user) <- User.find_by_id(claim["sub"]) do
      %{current_user: %{user | is_plus: true}}
    else
      _ -> %{}
    end
  end
end
