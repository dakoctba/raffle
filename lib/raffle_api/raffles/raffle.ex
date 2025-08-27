defmodule RaffleApi.Raffles.Raffle do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :scheduled_at, :inserted_at, :updated_at]}

  @fields ~w(name scheduled_at winner_user_id drawn_at)a
  @required_fields ~w(name scheduled_at)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Phoenix.Param, key: :id}

  schema "raffles" do
    field :name, :string
    field :scheduled_at, :utc_datetime
    field :winner_user_id, :binary_id
    field :drawn_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(raffle, attrs) do
    raffle
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:winner_user_id)
    |> unique_constraint([:name, :scheduled_at],
      name: :raffles_name_scheduled_at_index,
      message: "Já existe um sorteio com esse nome e data"
    )
  end

  @doc """
  Changeset for setting the winner of a raffle.

  This changeset is used when a raffle draw is completed,
  setting both the winner_user_id and the drawn_at timestamp.
  """
  def winner_changeset(raffle, winner_user_id) do
    raffle
    |> cast(
      %{
        winner_user_id: winner_user_id,
        drawn_at: DateTime.utc_now() |> DateTime.truncate(:second)
      },
      [:winner_user_id, :drawn_at]
    )
    |> validate_required([:winner_user_id, :drawn_at])
    |> foreign_key_constraint(:winner_user_id)
    |> validate_winner_not_already_set()
  end

  defp validate_winner_not_already_set(changeset) do
    case changeset.data.drawn_at do
      nil -> changeset
      _ -> add_error(changeset, :drawn_at, "Sorteio já foi realizado")
    end
  end
end
