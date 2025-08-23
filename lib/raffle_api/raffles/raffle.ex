defmodule RaffleApi.Raffles.Raffle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "raffles" do
    field :title, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(raffle, attrs) do
    raffle
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end
end
