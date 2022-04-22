defmodule Flowscan.UserMeta do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Flowscan.Repo

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "user_meta" do
    belongs_to(:user, Flowscan.User,
      foreign_key: :id,
      type: :binary_id,
      primary_key: true,
      define_field: false
    )

    field :rate_prompt, Ecto.Enum, values: [:hide, :show, :rated, :dismissed]
    field :rate_prompt_updated_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(user_meta, attrs) do
    user_meta
    |> cast(attrs, [:id, :rate_prompt, :rate_prompt_updated_at])
  end

  def for_user_id(id) do
    meta = Repo.get(__MODULE__, id)

    case meta do
      meta = %Flowscan.UserMeta{} ->
        meta

      nil ->
        __MODULE__.__struct__()
        |> changeset(%{id: id})
        |> Repo.insert!()
    end
  end

  def interaction(%Flowscan.User{} = user, interaction) do
    meta = for_user_id(user.id)

    case interaction do
      "rate_prompt_shown" ->
        meta
        |> changeset(%{rate_prompt: "rated", rate_prompt_updated_at: Timex.now()})
        |> Repo.update!()

      "rate_prompt_dismissed" ->
        meta
        |> changeset(%{rate_prompt: "dismissed", rate_prompt_updated_at: Timex.now()})
        |> Repo.update!()

      true ->
        meta
    end
  end
end
