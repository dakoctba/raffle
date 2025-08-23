defmodule RaffleApiWeb.RaffleControllerTest do
  use RaffleApiWeb.ConnCase

  import RaffleApi.RafflesFixtures
  alias RaffleApi.Raffles.Raffle

  @create_attrs %{
    description: "some description",
    title: "some title"
  }
  @update_attrs %{
    description: "some updated description",
    title: "some updated title"
  }
  @invalid_attrs %{description: nil, title: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all raffles", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/raffles")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create raffle" do
    test "renders raffle when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/raffles", raffle: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/raffles/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description",
               "title" => "some title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/raffles", raffle: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update raffle" do
    setup [:create_raffle]

    test "renders raffle when data is valid", %{conn: conn, raffle: %Raffle{id: id} = raffle} do
      conn = put(conn, ~p"/api/v1/raffles/#{raffle}", raffle: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/v1/raffles/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some updated description",
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, raffle: raffle} do
      conn = put(conn, ~p"/api/v1/raffles/#{raffle}", raffle: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete raffle" do
    setup [:create_raffle]

    test "deletes chosen raffle", %{conn: conn, raffle: raffle} do
      conn = delete(conn, ~p"/api/v1/raffles/#{raffle}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/v1/raffles/#{raffle}")
      end
    end
  end

  defp create_raffle(_) do
    raffle = raffle_fixture()

    %{raffle: raffle}
  end
end
