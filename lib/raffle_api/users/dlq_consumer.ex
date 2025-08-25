defmodule RaffleApi.Users.DLQConsumer do
  use Broadway
  require Logger
  alias Broadway.Message

  @max_batch_size String.to_integer(System.get_env("DLQ_BATCH_SIZE") || "500")
  @batch_timeout String.to_integer(System.get_env("DLQ_BATCH_TIMEOUT_MS") || "1000")

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayRabbitMQ.Producer,
          queue: "raffle_dlq",
          connection: [host: "localhost", username: "guest", password: "guest"],
          on_failure: :reject_and_requeue
        },
        concurrency: 1
      ],
      processors: [default: [concurrency: 1]],
      batchers: [
        db: [
          concurrency: 1,
          batch_size: @max_batch_size,
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
