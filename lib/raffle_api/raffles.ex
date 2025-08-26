defmodule RaffleApi.Raffles do
  @moduledoc """
  The Raffles context.
  """

  import Ecto.Query, warn: false
  alias RaffleApi.Repo

  alias RaffleApi.Raffles.Raffle

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

  alias RaffleApi.Raffles.RaffleUser

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
end
