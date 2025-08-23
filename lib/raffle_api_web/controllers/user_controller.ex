defmodule RaffleApiWeb.UserController do
  use RaffleApiWeb, :controller

  alias RaffleApi.Users
  alias RaffleApi.Users.UserBuffer

  action_fallback RaffleApiWeb.FallbackController

  def create(conn, user_params) do
    uuid = UUID.uuid4()

    user_data = Map.put(user_params, "id", uuid)

    UserBuffer.insert(user_data)
    json(conn, %{id: uuid})
  end

  def show(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    json(conn, %{user: user})
  end
end
