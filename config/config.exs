# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :raffle_api,
  ecto_repos: [RaffleApi.Repo],
  generators: [timestamp_type: :utc_datetime]

config :raffle_api, RaffleApi.Repo,
  migration_primary_key: [type: :uuid],
  migration_foreign_key: [type: :uuid]

# Configures the endpoint
config :raffle_api, RaffleApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RaffleApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: RaffleApi.PubSub,
  live_view: [signing_salt: "K74uuGiK"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :raffle_api, RaffleApi.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
