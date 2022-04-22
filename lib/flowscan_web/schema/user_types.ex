defmodule FlowscanWeb.Schema.UserTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :user do
    field :id, :string
    field :email, :string
    field :token, :string
    field :refresh_token, :string
    field :is_plus, :boolean
    field :is_tos_accepted, :boolean

    field :has_been_plus, :boolean do
      resolve(fn user, _, _ ->
        {:ok, !is_nil(user.plus_started_at)}
      end)
    end
  end

  object :user_meta do
    field :show_rate_prompt, :boolean do
      resolve(fn user_meta, _, _ ->
        {:ok, user_meta.rate_prompt == :show}
      end)
    end
  end

  object :request_password_reset do
    field :ok, :boolean
  end

  object :user_notification_settings do
    field :notifications_watchlist, :boolean
    field :notifications_highlights, :boolean
  end
end
