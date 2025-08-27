defmodule RaffleApi.Repo.Migrations.AddDrawnAtToRaffles do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :drawn_at, :utc_datetime
      add :winner_user_id, references(:users, type: :uuid)
    end

    create index(:raffles, [:winner_user_id])
  end
end
