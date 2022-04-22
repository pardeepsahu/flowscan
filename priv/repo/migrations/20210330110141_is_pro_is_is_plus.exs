defmodule Flowscan.Repo.Migrations.IsProIsIsPlus do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute "ALTER TABLE users RENAME COLUMN is_pro TO is_plus;"
    execute "ALTER TABLE users RENAME COLUMN pro_started_at TO plus_started_at;"
    execute "ALTER TABLE users RENAME COLUMN pro_expires_at TO plus_expires_at;"
    execute "ALTER TABLE option_activity RENAME COLUMN is_pro TO is_plus;"
    execute "ALTER TABLE highlights RENAME COLUMN is_pro TO is_plus;"
    execute "ALTER INDEX option_activity_is_pro_index RENAME TO option_activity_is_plus_index;"
  end

  def down do
    execute "ALTER TABLE users RENAME COLUMN is_plus TO is_pro;"
    execute "ALTER TABLE users RENAME COLUMN plus_started_at TO pro_started_at;"
    execute "ALTER TABLE users RENAME COLUMN plus_expires_at TO pro_expires_at;"
    execute "ALTER TABLE option_activity RENAME COLUMN is_plus TO is_pro;"
    execute "ALTER TABLE highlights RENAME COLUMN is_plus TO is_pro;"
    execute "ALTER INDEX option_activity_is_plus_index RENAME TO option_activity_is_pro_index;"
  end
end
