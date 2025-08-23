defmodule RaffleApi.Raffles.RaffleUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "raffle_users" do

    field :user_id, :id
    field :raffle_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(raffle_user, attrs) do
    raffle_user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
