defmodule Flowscan.Repo.Migrations.CreateEarningsCalendar do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:earnings_calendar) do
      add :preliminary_earnings_date, :date
      add :confirmed_earnings_date, :date
      add :fiscal_date_ending, :date
      add :estimate, :decimal
      add :symbol_id, references(:symbols, on_delete: :nothing)

      timestamps()
    end

    create index(:earnings_calendar, [:symbol_id])
    create index(:earnings_calendar, [:confirmed_earnings_date])
  end
end
