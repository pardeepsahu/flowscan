defmodule Flowscan.PushToken do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Flowscan.Repo

  schema "push_tokens" do
    field :onesignal_player_id, :string
    belongs_to(:user, Flowscan.User, foreign_key: :user_id, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(push_token, attrs) do
    push_token
    |> cast(attrs, [:onesignal_player_id, :user_id])
    |> validate_required([:onesignal_player_id, :user_id])
  end

  def find_by_onesignal_player_id(onesignal_player_id) do
    Repo.get_by(__MODULE__, onesignal_player_id: onesignal_player_id)
  end

  def onesignal_player_ids_for_user_ids(user_ids) do
    __MODULE__
    |> select([q], %{onesignal_player_id: q.onesignal_player_id})
    |> where([q], q.user_id in ^user_ids)
    |> Repo.all()
    |> Enum.map(fn p -> p.onesignal_player_id end)
  end

  def delete(onesignal_player_id, user_id) do
    from(pt in __MODULE__,
      where: pt.onesignal_player_id == ^onesignal_player_id and pt.user_id == ^user_id
    )
    |> Repo.delete_all()
  end
end
