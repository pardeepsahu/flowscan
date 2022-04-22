defmodule Flowscan.SubscriptionEvent do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Flowscan.Repo

  schema "subscription_events" do
    field :body, :map
    field :event, :string

    timestamps()
  end

  @doc false
  def changeset(subscription_event, attrs) do
    subscription_event
    |> cast(attrs, [:event, :body])
    |> validate_required([:body])
  end

  def create(event, body) do
    __MODULE__.__struct__()
    |> changeset(%{
      "event" => event,
      "body" => body
    })
    |> Repo.insert!()
  end
end
