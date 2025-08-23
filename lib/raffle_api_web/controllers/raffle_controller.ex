defmodule RaffleApiWeb.RaffleController do
  use RaffleApiWeb, :controller

  alias RaffleApi.Raffles
  alias RaffleApi.Raffles.Raffle

  action_fallback RaffleApiWeb.FallbackController

  def index(conn, _params) do
    raffles = Raffles.list_raffles()
    render(conn, :index, raffles: raffles)
  end

  def create(conn, %{"raffle" => raffle_params}) do
    with {:ok, %Raffle{} = raffle} <- Raffles.create_raffle(raffle_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/raffles/#{raffle}")
      |> render(:show, raffle: raffle)
    end
  end

  def show(conn, %{"id" => id}) do
    raffle = Raffles.get_raffle!(id)
    render(conn, :show, raffle: raffle)
  end
end
