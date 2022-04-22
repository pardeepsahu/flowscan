defmodule Flowscan.Feedback do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Flowscan.Repo

  schema "feedback" do
    belongs_to(:user, Flowscan.User, foreign_key: :user_id, type: :binary_id)
    field :body, :string
    field :sentiment, Ecto.Enum, values: [:positive, :negative]

    timestamps()
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:body, :sentiment])
    |> validate_required([:body])
  end

  def submit(user, body, sentiment) do
    __MODULE__.__struct__()
    |> changeset(%{body: body, sentiment: sentiment})
    |> put_assoc(:user, user)
    |> Repo.insert!()
  end
end
