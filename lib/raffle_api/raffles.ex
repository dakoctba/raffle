defmodule RaffleApi.Raffles do
  @moduledoc """
  The Raffles context.
  """

  import Ecto.Query, warn: false
  alias RaffleApi.Repo

  alias RaffleApi.Raffles.{Raffle, RaffleUser}

  @doc """
  Returns the list of raffles.

  ## Examples

      iex> list_raffles()
      [%Raffle{}, ...]

  """
  def list_raffles do
    Repo.all(Raffle)
  end

  @doc """
  Gets a single raffle.

  Raises `Ecto.NoResultsError` if the Raffle does not exist.

  ## Examples

      iex> get_raffle!(123)
      %Raffle{}

      iex> get_raffle!(456)
      ** (Ecto.NoResultsError)

  """
  def get_raffle!(id), do: Repo.get!(Raffle, id)

  @doc """
  Gets a single raffle.

  Do not raise an error if the raffle does not exist.

  ## Examples

      iex> get_raffle(123)
      %Raffle{}

      iex> get_raffle(456)
      nil
  """
  def get_raffle(id), do: Repo.get(Raffle, id)

  @doc """
  Creates a raffle.

  Idempotent: The FOR UPDATE instruction is used to lock the selected rows
  until the transaction is complete, preventing other transactions from modifying
  them.

  ## Examples

      iex> create_raffle(%{field: value})
      {:ok, %Raffle{}}

      iex> create_raffle(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_raffle(attrs) do
    %Raffle{}
    |> Raffle.changeset(attrs)
    |> Repo.insert()
    |> schedule_raffle()
  end

  @doc """
  Runs the draw for a raffle.

  ## Examples

      iex> run_draw(123)
      {:ok, %Raffle{}}

      iex> run_draw(456)
      {:error, :no_participants}

  """
  def run_draw(raffle_id) do
    Repo.transaction(fn ->
      raffle =
        Raffle
        |> where([r], r.id == ^raffle_id)
        |> lock("FOR UPDATE")
        |> Repo.one!()

      if raffle.drawn_at do
        raffle
      else
        case pick_random_user_id(raffle_id) do
          nil ->
            Repo.rollback(:no_participants)

          winner_id ->
            process_winner(raffle, winner_id)
        end
      end
    end)
    |> handle_draw_result()
  end

  @doc """
  Updates a raffle.

  ## Examples

      iex> update_raffle(raffle, %{field: new_value})
      {:ok, %Raffle{}}

      iex> update_raffle(raffle, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_raffle(%Raffle{} = raffle, attrs) do
    raffle
    |> Raffle.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a raffle.

  ## Examples

      iex> delete_raffle(raffle)
      {:ok, %Raffle{}}

      iex> delete_raffle(raffle)
      {:error, %Ecto.Changeset{}}

  """
  def delete_raffle(%Raffle{} = raffle) do
    Repo.delete(raffle)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking raffle changes.

  ## Examples

      iex> change_raffle(raffle)
      %Ecto.Changeset{data: %Raffle{}}

  """
  def change_raffle(%Raffle{} = raffle, attrs \\ %{}) do
    Raffle.changeset(raffle, attrs)
  end

  @doc """
  Returns the list of raffle_users.

  ## Examples

      iex> list_raffle_users()
      [%RaffleUser{}, ...]

  """
  def list_raffle_users do
    Repo.all(RaffleUser)
  end

  @doc """
  Gets a single raffle_user.

  Raises `Ecto.NoResultsError` if the Raffle user does not exist.

  ## Examples

      iex> get_raffle_user!(123)
      %RaffleUser{}

      iex> get_raffle_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_raffle_user!(id), do: Repo.get!(RaffleUser, id)

  @doc """
  Creates a raffle_user.

  ## Examples

      iex> create_raffle_user(%{field: value})
      {:ok, %RaffleUser{}}

      iex> create_raffle_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_raffle_user(attrs) do
    case validate_date(attrs["raffle_id"]) do
      {:ok, _raffle} ->
        %RaffleUser{}
        |> RaffleUser.changeset(attrs)
        |> Repo.insert()

      {:error, :raffle_expired} ->
        {:error, :raffle_expired}

      {:error, :raffle_not_found} ->
        {:error, :raffle_not_found}
    end
  end

  @doc """
  Updates a raffle_user.

  ## Examples

      iex> update_raffle_user(raffle_user, %{field: new_value})
      {:ok, %RaffleUser{}}

      iex> update_raffle_user(raffle_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_raffle_user(%RaffleUser{} = raffle_user, attrs) do
    raffle_user
    |> RaffleUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a raffle_user.

  ## Examples

      iex> delete_raffle_user(raffle_user)
      {:ok, %RaffleUser{}}

      iex> delete_raffle_user(raffle_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_raffle_user(%RaffleUser{} = raffle_user) do
    Repo.delete(raffle_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking raffle_user changes.

  ## Examples

      iex> change_raffle_user(raffle_user)
      %Ecto.Changeset{data: %RaffleUser{}}

  """
  def change_raffle_user(%RaffleUser{} = raffle_user, attrs \\ %{}) do
    RaffleUser.changeset(raffle_user, attrs)
  end

  defp validate_date(raffle_id) do
    case get_raffle(raffle_id) do
      %Raffle{scheduled_at: scheduled_at} = raffle ->
        case DateTime.compare(scheduled_at, DateTime.utc_now()) do
          :lt -> {:error, :raffle_expired}
          _ -> {:ok, raffle}
        end

      nil ->
        {:error, :raffle_not_found}
    end
  end

  defp schedule_raffle({:ok, %Raffle{id: raffle_id, scheduled_at: scheduled_at} = raffle}) do
    job =
      RaffleApi.Workers.DrawRaffle.new(
        %{"raffle_id" => raffle_id},
        scheduled_at: scheduled_at
      )

    case Oban.insert(job) do
      {:ok, _job} ->
        {:ok, raffle}

      {:error, reason} ->
        {:error, {:job_schedule_failed, reason}}
    end
  end

  defp schedule_raffle({:error, _} = error), do: error

  defp handle_draw_result({:ok, raffle}), do: {:ok, raffle}
  defp handle_draw_result({:error, :no_participants}), do: {:error, :no_participants}
  defp handle_draw_result({:error, :winner_user_not_found}), do: {:error, :winner_user_not_found}
  defp handle_draw_result({:error, changeset}), do: {:error, changeset}

  defp process_winner(raffle, winner_id) do
    changeset = Raffle.winner_changeset(raffle, winner_id)

    case Repo.update(changeset) do
      {:ok, updated_raffle} ->
        updated_raffle

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "changeset.errors")
        Repo.rollback(changeset)
    end
  end

  defp pick_random_user_id(raffle_id) do
    from(ru in RaffleUser,
      where: ru.raffle_id == ^raffle_id,
      order_by: fragment("random()"),
      select: ru.user_id,
      limit: 1
    )
    |> Repo.one()
  end
end
