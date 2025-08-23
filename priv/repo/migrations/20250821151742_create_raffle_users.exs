defmodule RaffleApi.Repo.Migrations.CreateRaffleUsers do
  use Ecto.Migration

  def change do
    create table(:raffle_users) do
      add :user_id, references(:users, on_delete: :nothing)
      add :raffle_id, references(:raffles, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:raffle_users, [:user_id])
    create index(:raffle_users, [:raffle_id])
  end
end
