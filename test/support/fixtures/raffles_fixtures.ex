defmodule RaffleApi.RafflesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaffleApi.Raffles` context.
  """

  @doc """
  Generate a raffle.
  """
  def raffle_fixture(attrs \\ %{}) do
    {:ok, raffle} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> RaffleApi.Raffles.create_raffle()

    raffle
  end

  @doc """
  Generate a raffle_user.
  """
  def raffle_user_fixture(attrs \\ %{}) do
    {:ok, raffle_user} =
      attrs
      |> Enum.into(%{

      })
      |> RaffleApi.Raffles.create_raffle_user()

    raffle_user
  end
end
