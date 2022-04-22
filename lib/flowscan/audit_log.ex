defmodule Flowscan.AuditLog do
  @moduledoc false
  use Ecto.Schema
  alias Flowscan.Repo
  alias Flowscan.User
  import Ecto.Changeset

  schema "audit_logs" do
    belongs_to(:user, Flowscan.User, foreign_key: :user_id, type: :binary_id)
    field :body, :map
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:type, :body])
    |> validate_required([:type])
  end

  def create(%User{} = user, type, body) do
    __MODULE__.__struct__()
    |> changeset(%{
      type: type,
      body: body
    })
    |> put_assoc(:user, user)
    |> Repo.insert()
  end
end
