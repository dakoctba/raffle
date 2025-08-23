defmodule RaffleApi.Repo.Migrations.CreateRaffles do
  use Ecto.Migration

  def change do
    create table(:raffles) do
      add :title, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
