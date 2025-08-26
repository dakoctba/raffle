defmodule RaffleApiWeb.RaffleJSON do
  alias RaffleApi.Raffles.Raffle

  @doc """
  Renders a list of raffles.
  """
  def index(%{raffles: raffles}) do
    %{data: for(raffle <- raffles, do: data(raffle))}
  end

  @doc """
  Renders a single raffle.
  """
  def show(%{raffle: raffle}) do
    %{data: data(raffle)}
  end

  defp data(%Raffle{} = raffle) do
    %{
      id: raffle.id,
      name: raffle.name,
      scheduled_at: raffle.scheduled_at
    }
  end
end
