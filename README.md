
# RaffleApi

RaffleApi is a web application built with the [Phoenix Framework](https://www.phoenixframework.org/) and Elixir. It provides a robust backend for managing raffles, users, and message queues using RabbitMQ and PostgreSQL.

## Getting Started

### 1. Setup

* Run `mix setup` to install and setup dependencies.
* Start the Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`.
* Visit [`localhost:3002`](http://localhost:3002) from your browser.

### 2. Environment Variables

The application uses the following environment variables (see `.envrc`):

```env
# RabbitMQ connection
RABBITMQ_HOST=localhost
RABBITMQ_USER=guest
RABBITMQ_PASS=guest

# Main users queue (Consumer)
USERS_QUEUE=raffle_queue
MAX_RETRIES=3
USERS_BATCH_SIZE=1000
USERS_BATCH_TIMEOUT_MS=1000
USERS_PROC_CONCURRENCY=8
USERS_BATCH_CONCURRENCY=2

# DLQ (Dead Letter Queue Consumer)
USERS_DLQ=raffle_dlq
DLQ_BATCH_SIZE=500
DLQ_BATCH_TIMEOUT_MS=1000
DLQ_PROC_CONCURRENCY=1
DLQ_BATCH_CONCURRENCY=1

# Retry queue
RETRY_TTL_MS=10000
```

Set these variables in your environment or use a tool like [direnv](https://direnv.net/) to load them automatically.

### 3. Docker & Database

You can use Docker Compose to run the required services:

```sh
docker-compose up -d
```

This will start:

- **PostgreSQL** (port 5433, password: `postgres`)
- **RabbitMQ** (ports 5672, 15672 for management UI)

### 4. Dependencies

Key dependencies (see `mix.exs`):

- Phoenix ~> 1.8
- Ecto & Postgrex (database)
- Broadway & BroadwayRabbitMQ (message processing)
- Swoosh (email)
- Req (HTTP client)
- Jason (JSON)
- Bandit (server adapter)
- ElixirUUID

See `mix.exs` for the full list.

### 5. Project Guidelines

Please follow the coding and usage guidelines in [`AGENTS.md`](./AGENTS.md), including:

- Use the `:req` library for HTTP requests
- Phoenix v1.8 LiveView and component conventions
- Elixir and Mix best practices

## Production

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Phoenix Docs](https://hexdocs.pm/phoenix)
- [Elixir Forum](https://elixirforum.com/c/phoenix-forum)
- [Phoenix Source](https://github.com/phoenixframework/phoenix)
