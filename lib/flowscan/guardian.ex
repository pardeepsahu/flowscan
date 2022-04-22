defmodule Flowscan.Guardian do
  @moduledoc false

  use Guardian, otp_app: :flowscan
  alias Flowscan.User

  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  def resource_from_claims(claims) do
    {:ok, User.find_by_id(claims["sub"])}
  end
end
