defmodule RaffleApi.Raffles.Raffle do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :scheduled_at, :inserted_at, :updated_at]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "raffles" do
    field :name, :string
    field :scheduled_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(raffle, attrs) do
    raffle
    |> cast(attrs, [:name, :scheduled_at])
    |> validate_required([:name, :scheduled_at])
    |> unique_constraint([:name, :scheduled_at],
      name: :raffles_name_scheduled_at_index,
      message: "Já existe um sorteio com esse nome e data"
    )
  end
end
