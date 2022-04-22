defmodule Flowscan.AbsintheHelpers do
  @moduledoc false

  alias Flowscan.Guardian

  def authenticate_conn(conn, user) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{token}")
  end

  def query(query, variables \\ %{}) do
    %{
      "operationName" => "",
      "query" => query,
      "variables" => variables
    }
  end
end
