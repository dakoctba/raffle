defmodule RaffleApi.Users.Publisher do
  use GenServer
  require Logger

  @queue "raffle_queue"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def publish_user(data) do
    GenServer.call(__MODULE__, {:publish, data})
  end

  def init(:ok) do
    case AMQP.Connection.open() do
      {:ok, conn} ->
        {:ok, channel} = AMQP.Channel.open(conn)
        AMQP.Queue.declare(channel, @queue, durable: true)
        Logger.info("📡 RabbitMQ publisher ready")
        {:ok, %{channel: channel}}

      {:error, reason} ->
        Logger.error("❌ Failed to connect to RabbitMQ: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  def handle_call({:publish, data}, _from, %{channel: chan} = state) do
    with {:ok, json} <- Jason.encode(data),
         :ok <- AMQP.Basic.publish(chan, "", @queue, json, persistent: true) do
      {:reply, :ok, state}
    else
      error ->
        Logger.error("❌ Failed to publish user: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end
end
