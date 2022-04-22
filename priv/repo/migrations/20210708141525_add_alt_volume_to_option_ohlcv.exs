defmodule Flowscan.Repo.Migrations.AddAltVolumeToOptionOhlcv do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:option_ohlcv) do
      add :alternative_volume, :integer, null: true
    end
  end
end
