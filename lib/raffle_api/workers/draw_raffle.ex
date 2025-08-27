defmodule RaffleApi.Workers.DrawRaffle do
  use Oban.Worker,
    queue: :raffles,
    unique: [keys: [:raffle_id], states: [:available, :scheduled], period: :infinity],
    replace: [scheduled: [:scheduled_at]]

  @impl true
  def perform(%Oban.Job{args: %{"raffle_id" => id}}) do
    case RaffleApi.Raffles.run_draw(id) do
      {:ok, _raffle} -> :ok
      {:error, :no_participants} -> :discard
      {:error, reason} -> {:error, reason}
    end
  end
end
