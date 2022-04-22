defmodule FlowscanWeb.SignInWithAppleTokenFetchStrategy do
  @moduledoc false
  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    url = "https://appleid.apple.com/auth/keys"
    Keyword.merge(opts, jwks_url: url)
  end
end

defmodule FlowscanWeb.SignInWithAppleToken do
  @moduledoc false
  # no signer
  use Joken.Config, default_signer: nil

  # This hook implements a before_verify callback that checks whether it has a signer configuration
  # cached. If it does not, it tries to fetch it from the jwks_url.
  add_hook(JokenJwks, strategy: FlowscanWeb.SignInWithAppleTokenFetchStrategy)

  @impl true
  def token_config do
    default_claims(skip: [:aud, :iss])
    # |> add_claim("roles", nil, &(&1 in ["admin", "user"]))
    # |> add_claim("iss", nil, &(&1 == "some server iss"))
    |> add_claim("aud", nil, &(&1 == "com.nodehub.flowscan"))
  end
end
