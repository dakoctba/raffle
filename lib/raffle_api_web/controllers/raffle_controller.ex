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

      {:error, changeset} ->
        conn
        |> put_status(:conflict)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  def show(conn, %{"id" => id}) do
    raffle = Raffles.get_raffle!(id)
    render(conn, :show, raffle: raffle)
  end

  def result(conn, %{"id" => id}) do
    case Raffles.get_raffle_result(id) do
      {:ok, winner} ->
        conn
        |> put_status(:ok)
        |> json(%{winner: winner})

      {:error, :raffle_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Sorteio não encontrado"})

      {:error, :raffle_not_drawn} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Sorteio ainda não foi realizado"})

      {:error, :winner_not_found} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Dados do vencedor não encontrados"})
    end
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
