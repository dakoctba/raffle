defmodule RaffleApi.Users.Consumer do
  use Broadway

  alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayRabbitMQ.Producer,
          queue: "raffle_queue",
          connection: [
            host: "localhost",
            username: "guest",
            password: "guest"
          ],
          on_failure: :reject_and_requeue
        },
        concurrency: 8
      ],
      processors: [
        default: [concurrency: 8]
      ],
      batchers: [
        db: [
          concurrency: 10,
          batch_size: 1_000,
          batch_timeout: 1_000
        ]
      ]
    )
  end

  def handle_message(_, %Message{data: json} = message, _context) do
    {:ok, data} = Jason.decode(json)
    Message.put_batcher(message, :db)
    |> Message.update_data(fn _ -> data end)
  end

  def handle_batch(:db, messages, _, _) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    users =
      Enum.map(messages, fn %Message{data: data} ->
        %{
          id: data["id"],
          name: data["name"],
          email: data["email"],
          inserted_at: now,
          updated_at: now
        }
      end)

    RaffleApi.Repo.insert_all(RaffleApi.Users.User, users,
      on_conflict: :nothing,
      conflict_target: [:id]
    )

    messages
  end
end
