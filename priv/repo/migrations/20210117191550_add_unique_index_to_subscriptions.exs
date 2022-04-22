defmodule Flowscan.Repo.Migrations.AddUniqueIndexToSubscriptions do
  @moduledoc false
  use Ecto.Migration

  def change do
    create index(:subscriptions, [:user_id, :qonversion_purchase_original_id], unique: true)
  end
end
