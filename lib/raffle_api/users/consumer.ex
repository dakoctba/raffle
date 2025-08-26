defmodule RaffleApi.Users.Consumer do
  use Broadway
  alias Broadway.Message
  alias RaffleApi.Users.Publisher

  @queue System.get_env("USERS_QUEUE", "raffle_queue")
  @rabbit_host System.get_env("RABBITMQ_HOST", "localhost")
  @rabbit_user System.get_env("RABBITMQ_USER", "guest")
  @rabbit_pass System.get_env("RABBITMQ_PASS", "guest")
  @max_retries String.to_integer(System.get_env("MAX_RETRIES", "3"))
  @batch_size String.to_integer(System.get_env("USERS_BATCH_SIZE", "1000"))
  @batch_timeout String.to_integer(System.get_env("USERS_BATCH_TIMEOUT_MS", "1000"))
  @processors_concurrency String.to_integer(System.get_env("USERS_PROC_CONCURRENCY", "8"))
  @batchers_concurrency String.to_integer(System.get_env("USERS_BATCH_CONCURRENCY", "2"))

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayRabbitMQ.Producer,
          queue: @queue,
          connection: [host: @rabbit_host, username: @rabbit_user, password: @rabbit_pass],
          on_failure: :reject
        },
        concurrency: @processors_concurrency
      ],
      processors: [default: [concurrency: @processors_concurrency]],
      batchers: [
        db: [
          concurrency: @batchers_concurrency,
          batch_size: @batch_size,
          batch_timeout: @batch_timeout
        ]
      ]
    )
  end

  def handle_message(_, %Message{data: json} = message, _context) do
    case Jason.decode(json) do
      {:ok, data} ->
        message
        |> Message.put_batcher(:db)
        |> Message.update_data(fn _ -> data end)

      {:error, _} ->
        Message.failed(message, :invalid_json)
    end
  end

  def handle_batch(:db, messages, _, _) do
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

      messages
    rescue
      e ->
        # Erro de DB: decidir entre retry ou DLQ por mensagem
        Enum.map(messages, fn msg ->
          attempt = get_attempt(msg)
          reason = {:db_error, Exception.message(e)}

          if attempt < @max_retries do
            # republish para fila de retry; ack a atual
            _ = Publisher.publish_retry(msg.data, attempt + 1, reason)
            msg
          else
            # estourou tentativas -> vai para DLQ
            Message.failed(msg, {:exceeded_retries, reason})
          end
        end)
    end
  end

  # Lê x-retries dos headers (Broadway expõe headers via metadata)
  defp get_attempt(%Message{metadata: md}) do
    case md[:headers] do
      nil ->
        0

      headers ->
        case Enum.find(headers, fn {k, _t, _v} -> k in ["x-retries", :"x-retries"] end) do
          {_, _, v} when is_integer(v) ->
            v

          {_, _, v} ->
            case Integer.parse(to_string(v)) do
              {n, _} -> n
              _ -> 0
            end

          _ ->
            0
        end
    end
  end
end
