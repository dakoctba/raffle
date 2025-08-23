defmodule RaffleApiWeb.RaffleJoinController do
  use RaffleApiWeb, :controller

  alias RaffleApi.Raffles

  def join(conn, %{"id" => raffle_id, "user_id" => user_id}) do
    case Raffles.create_raffle_user(%{"raffle_id" => raffle_id, "user_id" => user_id}) do
      {:ok, _raffle_user} ->
        json(conn, %{message: "Usuário inscrito no sorteio com sucesso!"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  def translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
