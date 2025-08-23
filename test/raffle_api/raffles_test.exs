defmodule RaffleApi.RafflesTest do
  use RaffleApi.DataCase

  alias RaffleApi.Raffles

  describe "raffles" do
    alias RaffleApi.Raffles.Raffle

    import RaffleApi.RafflesFixtures

    @invalid_attrs %{description: nil, title: nil}

    test "list_raffles/0 returns all raffles" do
      raffle = raffle_fixture()
      assert Raffles.list_raffles() == [raffle]
    end

    test "get_raffle!/1 returns the raffle with given id" do
      raffle = raffle_fixture()
      assert Raffles.get_raffle!(raffle.id) == raffle
    end

    test "create_raffle/1 with valid data creates a raffle" do
      valid_attrs = %{description: "some description", title: "some title"}

      assert {:ok, %Raffle{} = raffle} = Raffles.create_raffle(valid_attrs)
      assert raffle.description == "some description"
      assert raffle.title == "some title"
    end

    test "create_raffle/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Raffles.create_raffle(@invalid_attrs)
    end

    test "update_raffle/2 with valid data updates the raffle" do
      raffle = raffle_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title"}

      assert {:ok, %Raffle{} = raffle} = Raffles.update_raffle(raffle, update_attrs)
      assert raffle.description == "some updated description"
      assert raffle.title == "some updated title"
    end

    test "update_raffle/2 with invalid data returns error changeset" do
      raffle = raffle_fixture()
      assert {:error, %Ecto.Changeset{}} = Raffles.update_raffle(raffle, @invalid_attrs)
      assert raffle == Raffles.get_raffle!(raffle.id)
    end

    test "delete_raffle/1 deletes the raffle" do
      raffle = raffle_fixture()
      assert {:ok, %Raffle{}} = Raffles.delete_raffle(raffle)
      assert_raise Ecto.NoResultsError, fn -> Raffles.get_raffle!(raffle.id) end
    end

    test "change_raffle/1 returns a raffle changeset" do
      raffle = raffle_fixture()
      assert %Ecto.Changeset{} = Raffles.change_raffle(raffle)
    end
  end

  describe "raffle_users" do
    alias RaffleApi.Raffles.RaffleUser

    import RaffleApi.RafflesFixtures

    @invalid_attrs %{}

    test "list_raffle_users/0 returns all raffle_users" do
      raffle_user = raffle_user_fixture()
      assert Raffles.list_raffle_users() == [raffle_user]
    end

    test "get_raffle_user!/1 returns the raffle_user with given id" do
      raffle_user = raffle_user_fixture()
      assert Raffles.get_raffle_user!(raffle_user.id) == raffle_user
    end

    test "create_raffle_user/1 with valid data creates a raffle_user" do
      valid_attrs = %{}

      assert {:ok, %RaffleUser{} = raffle_user} = Raffles.create_raffle_user(valid_attrs)
    end

    test "create_raffle_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Raffles.create_raffle_user(@invalid_attrs)
    end

    test "update_raffle_user/2 with valid data updates the raffle_user" do
      raffle_user = raffle_user_fixture()
      update_attrs = %{}

      assert {:ok, %RaffleUser{} = raffle_user} = Raffles.update_raffle_user(raffle_user, update_attrs)
    end

    test "update_raffle_user/2 with invalid data returns error changeset" do
      raffle_user = raffle_user_fixture()
      assert {:error, %Ecto.Changeset{}} = Raffles.update_raffle_user(raffle_user, @invalid_attrs)
      assert raffle_user == Raffles.get_raffle_user!(raffle_user.id)
    end

    test "delete_raffle_user/1 deletes the raffle_user" do
      raffle_user = raffle_user_fixture()
      assert {:ok, %RaffleUser{}} = Raffles.delete_raffle_user(raffle_user)
      assert_raise Ecto.NoResultsError, fn -> Raffles.get_raffle_user!(raffle_user.id) end
    end

    test "change_raffle_user/1 returns a raffle_user changeset" do
      raffle_user = raffle_user_fixture()
      assert %Ecto.Changeset{} = Raffles.change_raffle_user(raffle_user)
    end
  end
end
