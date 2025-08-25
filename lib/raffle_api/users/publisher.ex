# file: raffle_api/users/publisher.ex
defmodule RaffleApi.Users.Publisher do
  use GenServer
  require Logger

  @exchange "raffle_exchange"
  @dlx "raffle_dlx"
  @retry_exchange "raffle_retry_exchange"

  @queue "raffle_queue"
  @dlq "raffle_dlq"
  @retry_queue "raffle_retry_10s"

  @routing_key "raffle_queue"
  @dlq_routing_key "raffle_dlq"
  @retry_routing_key "raffle_retry_10s"

  # TTL padrão de 10s (pode vir de env)
  @retry_ttl String.to_integer(System.get_env("RETRY_TTL_MS") || "10000")

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def publish_user(data), do: GenServer.call(__MODULE__, {:publish, data})

  # publicar em retry (com headers)
  def publish_retry(data, attempt, reason \\ nil),
    do: GenServer.call(__MODULE__, {:publish_retry, data, attempt, reason})

  def init(:ok) do
    case AMQP.Connection.open() do
      {:ok, conn} ->
        {:ok, channel} = AMQP.Channel.open(conn)

        # Exchanges
        :ok = AMQP.Exchange.declare(channel, @exchange, :direct, durable: true)
        :ok = AMQP.Exchange.declare(channel, @dlx, :direct, durable: true)
        :ok = AMQP.Exchange.declare(channel, @retry_exchange, :direct, durable: true)

        # Fila principal com DLX (vai para DLQ quando rejeitada)
        {:ok, _} =
          AMQP.Queue.declare(channel, @queue, durable: true, arguments: [
            {"x-dead-letter-exchange", :longstr, @dlx},
            {"x-dead-letter-routing-key", :longstr, @dlq_routing_key}
          ])

        # DLQ (dead-letter queue)
        {:ok, _} = AMQP.Queue.declare(channel, @dlq, durable: true)

        # Fila de retry: tem TTL e devolve para a fila principal ao expirar
        {:ok, _} =
          AMQP.Queue.declare(channel, @retry_queue, durable: true, arguments: [
            {"x-message-ttl", :signedint, @retry_ttl},
            {"x-dead-letter-exchange", :longstr, @exchange},
            {"x-dead-letter-routing-key", :longstr, @routing_key}
          ])

        # Bindings
        :ok = AMQP.Queue.bind(channel, @queue, @exchange, routing_key: @routing_key)
        :ok = AMQP.Queue.bind(channel, @dlq, @dlx, routing_key: @dlq_routing_key)
        :ok = AMQP.Queue.bind(channel, @retry_queue, @retry_exchange, routing_key: @retry_routing_key)

        Logger.info("RabbitMQ publisher ready (DLQ + RETRY habilitados)")
        {:ok, %{channel: channel}}

      {:error, reason} ->
        Logger.error("Failed to connect to RabbitMQ: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  def handle_call({:publish, data}, _from, %{channel: chan} = state) do
    with {:ok, json} <- Jason.encode(data),
         :ok <- AMQP.Basic.publish(chan, @exchange, @routing_key, json, persistent: true) do
      {:reply, :ok, state}
    else
      error ->
        Logger.error("Failed to publish user: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:publish_retry, data, attempt, reason}, _from, %{channel: chan} = state) do
    headers =
      [{"x-retries", :signedint, attempt}] ++
        (if reason, do: [{"x-retry-reason", :longstr, to_string(reason)}], else: [])

    with {:ok, json} <- Jason.encode(data),
         :ok <-
           AMQP.Basic.publish(
             chan,
             @retry_exchange,
             @retry_routing_key,
             json,
             persistent: true,
             headers: headers
           ) do
      {:reply, :ok, state}
    else
      error ->
        Logger.error("Failed to publish to retry: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end
end
