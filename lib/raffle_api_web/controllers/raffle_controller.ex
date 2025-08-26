defmodule RaffleApiWeb.RaffleController do
  use RaffleApiWeb, :controller

  alias RaffleApi.Raffles
  alias RaffleApi.Raffles.Raffle

  action_fallback RaffleApiWeb.FallbackController

  def index(conn, _params) do
    raffles = Raffles.list_raffles()
    render(conn, :index, raffles: raffles)
  end

  def create(conn, params) do
    case Raffles.create_raffle(params) do
      {:ok, %Raffle{} = raffle} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/v1/raffles/#{raffle}")
        |> json(%{id: raffle.id})

      {:error, _changeset} ->
        send_resp(conn, 409, "")
    end
  end

  def show(conn, %{"id" => id}) do
    raffle = Raffles.get_raffle!(id)
    render(conn, :show, raffle: raffle)
  end
end
