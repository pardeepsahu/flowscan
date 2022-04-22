defmodule FlowscanWeb.InappLinkController do
  use FlowscanWeb, :controller
  alias Flowscan.User

  plug :put_layout, false

  def reset_password(conn, %{"password_reset_token" => password_reset_token}) do
    is_token_valid = User.password_reset_token_is_valid?(password_reset_token)

    render(conn, "index.html",
      is_token_valid: is_token_valid,
      password_reset_token: password_reset_token
    )
  end
end
