defmodule RaffleApi.Repo.Migrations.CreateRaffles do
  use Ecto.Migration

  def change do
    create table(:raffles) do
      add :name, :string, null: false
      add :scheduled_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:raffles, [:name, :scheduled_at])
  end
end
