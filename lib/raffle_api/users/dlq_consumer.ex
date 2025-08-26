defmodule RaffleApi.Users.DLQConsumer do
  use Broadway
  require Logger
  alias Broadway.Message

  @queue System.get_env("USERS_DLQ", "raffle_dlq")
  @rabbit_host System.get_env("RABBITMQ_HOST", "localhost")
  @rabbit_user System.get_env("RABBITMQ_USER", "guest")
  @rabbit_pass System.get_env("RABBITMQ_PASS", "guest")

  @batch_size String.to_integer(System.get_env("DLQ_BATCH_SIZE", "500"))
  @batch_timeout String.to_integer(System.get_env("DLQ_BATCH_TIMEOUT_MS", "1000"))
  @proc_concurrency String.to_integer(System.get_env("DLQ_PROC_CONCURRENCY", "1"))
  @batch_concurrency String.to_integer(System.get_env("DLQ_BATCH_CONCURRENCY", "1"))

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayRabbitMQ.Producer,
          queue: @queue,
          connection: [host: @rabbit_host, username: @rabbit_user, password: @rabbit_pass],
          on_failure: :reject_and_requeue
        },
        concurrency: @proc_concurrency
      ],
      processors: [default: [concurrency: @proc_concurrency]],
      batchers: [
        db: [
          concurrency: @batch_concurrency,
          batch_size: @batch_size,
          batch_timeout: @batch_timeout
        ]
      ]
    )
  end

  def handle_message(_, %Message{data: json} = message, _ctx) do
    case Jason.decode(json) do
      {:ok, data} ->
        message
        |> Message.put_batcher(:db)
        |> Message.update_data(fn _ -> data end)

      {:error, err} ->
        Logger.error("DLQ: JSON inválido descartado: #{inspect(err)} payload=#{inspect(json)}")
        message
    end
  end

  def handle_batch(:db, messages, _batch_info, _ctx) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    users =
      for %Message{data: data} <- messages do
        %{
          id: data["id"],
          name: data["name"],
          email: data["email"],
          inserted_at: now,
          updated_at: now
        }
      end

    try do
      RaffleApi.Repo.insert_all(RaffleApi.Users.User, users,
        on_conflict: :nothing,
        conflict_target: [:id]
      )

      Logger.info("DLQ -> DB: inseridos #{length(users)} registro(s)")
      messages
    rescue
      e ->
        Logger.error("DLQ -> DB: erro ao inserir lote (requeue): #{Exception.message(e)}")
        Enum.map(messages, &Message.failed(&1, {:db_error, Exception.message(e)}))
    end
  end
end
