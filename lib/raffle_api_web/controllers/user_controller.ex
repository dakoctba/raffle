defmodule RaffleApiWeb.UserController do
  use RaffleApiWeb, :controller

  alias RaffleApi.Users
  alias RaffleApi.Users.Publisher


  def create(conn, user_params) do
    uuid = UUID.uuid4()
    enriched_data = Map.put(user_params, "id", uuid)

    case Publisher.publish_user(enriched_data) do
      :ok ->
        json(conn, %{id: uuid})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to enqueue user", reason: inspect(reason)})
    end
  end

  def show(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    json(conn, %{user: user})
  end
end
