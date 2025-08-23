defmodule RaffleApi.Repo do
  use Ecto.Repo,
    otp_app: :raffle_api,
    adapter: Ecto.Adapters.Postgres
end
