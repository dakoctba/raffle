defmodule RaffleApi.Users.UserBuffer do
  use GenServer
  require Logger

  @flush_interval 3_000
  @max_batch 1_000

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def insert(data), do: GenServer.cast(__MODULE__, {:insert, data})

  def init(_) do
    schedule_flush()
    {:ok, %{queue: [], flushing: false}}
  end

  def handle_cast({:insert, data}, %{queue: queue, flushing: flushing} = state) do
    entry =
      data
      |> Map.new(fn
        {k, v} when is_binary(k) -> {String.to_atom(k), v}
        kv -> kv
      end)

    new_queue = [entry | queue]

    if length(new_queue) >= @max_batch and not flushing do
      persist_async(new_queue)
      {:noreply, %{queue: [], flushing: true}}
    else
      {:noreply, %{state | queue: new_queue}}
    end
  end

  def handle_info(:flush, %{queue: queue, flushing: false} = _state) do
    persist_async(queue)
    {:noreply, %{queue: [], flushing: true}}
  end

  def handle_info(:flush, state) do
    schedule_flush()
    {:noreply, state}
  end

  def handle_info(:flush_done, state) do
    schedule_flush()
    {:noreply, %{state | flushing: false}}
  end

  defp schedule_flush do
    Process.send_after(self(), :flush, @flush_interval)
  end

  defp persist_async([]), do: :ok

  defp persist_async(batch) do
    Logger.debug("Persistindo #{length(batch)} registros no banco.")

    Task.Supervisor.async_nolink(RaffleApi.UserBufferSupervisor, fn ->
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      clean_batch =
        Enum.map(batch, fn item ->
          %{
            id: item[:id],
            name: item[:name],
            email: item[:email],
            inserted_at: now,
            updated_at: now
          }
        end)

      case RaffleApi.Repo.insert_all(RaffleApi.Users.User, clean_batch) do
        {count, _} ->
          Logger.info("Persistidos #{count} registros no banco.")
      end
    end)

    # Mesmo que a task falhe, a gente espera pelo flush_done
    send(self(), :flush_done)
  end
end
