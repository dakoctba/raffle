defmodule RaffleApi.Raffles.RaffleUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "raffle_users" do
    field :user_id, :binary_id
    field :raffle_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(raffle_user, attrs) do
    raffle_user
    |> cast(attrs, [:user_id, :raffle_id])
    |> validate_required([:user_id, :raffle_id])
    |> unique_constraint([:user_id, :raffle_id], name: :raffle_users_raffle_id_user_id_index)
  end
end
