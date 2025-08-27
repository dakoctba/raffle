
# RaffleApi

RaffleApi is a web application built with the [Phoenix Framework](https://www.phoenixframework.org/) and Elixir. It provides a robust backend for managing raffles, users, and message queues using RabbitMQ and PostgreSQL.

## Prerequisites

Before running this project, make sure you have the following tools installed:

### Required Tools

1. **asdf** - Version manager for Erlang/Elixir
   ```bash
   git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
   echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
   echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.zshrc
   source ~/.zshrc
   ```

2. **Docker & Docker Compose** - For running PostgreSQL and RabbitMQ
   - [Install Docker Desktop for Mac](https://docs.docker.com/docker-for-mac/install/)

3. **direnv** - For automatic environment variable loading
   ```bash
   brew install direnv
   echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
   source ~/.zshrc
   ```

## Setup Instructions

### 1. Clone and Navigate to Project

```bash
git clone <repository-url>
cd raffle_api
```

### 2. Install Language Versions with asdf

```bash
# Add Erlang and Elixir plugins
asdf plugin add erlang
asdf plugin add elixir

# Install versions specified in .tool-versions
asdf install

# Verify installations
asdf current
```

The project uses:
- **Erlang**: 27.3.1
- **Elixir**: 1.18.3-otp-27

### 3. Environment Variables Setup

Create a `.envrc` file in the project root with the following variables:

```bash
# Create .envrc file
cat > .envrc << 'EOF'
export RABBITMQ_HOST=localhost
export RABBITMQ_USER=guest
export RABBITMQ_PASS=guest

export USERS_QUEUE=raffle_queue
export MAX_RETRIES=3
export USERS_BATCH_SIZE=1000
export USERS_BATCH_TIMEOUT_MS=1000
export USERS_PROC_CONCURRENCY=8
export USERS_BATCH_CONCURRENCY=2

export USERS_DLQ=raffle_dlq
export DLQ_BATCH_SIZE=500
export DLQ_BATCH_TIMEOUT_MS=1000
export DLQ_PROC_CONCURRENCY=1
export DLQ_BATCH_CONCURRENCY=1

export RETRY_TTL_MS=10000
EOF

# Allow direnv to load the file
direnv allow
```

### 4. Start Services with Docker Compose

```bash
# Start PostgreSQL and RabbitMQ services
docker-compose up -d

# Verify services are running
docker-compose ps
```

This will start:
- **PostgreSQL** (port 5433, password: `postgres`)
- **RabbitMQ** (ports 5672, 15672 for management UI)

### 5. Install Dependencies and Setup Database

```bash
# Install Elixir dependencies
mix deps.get

# Setup database
mix ecto.setup

# Or alternatively run each step:
# mix ecto.create
# mix ecto.migrate
# mix run priv/repo/seeds.exs
```

### 6. Start the Application

```bash
# Start Phoenix server
mix phx.server

# Or start with IEx for interactive development
iex -S mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Architecture & Services

### Core Technologies

- **Phoenix Framework**: Web framework and API endpoints
- **Ecto**: Database abstraction layer
- **Broadway**: Message processing pipelines
- **RabbitMQ**: Message queue system
- **PostgreSQL**: Primary database

### Service URLs

When running locally:
- **Application**: http://localhost:4000
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)
- **PostgreSQL**: localhost:5433 (postgres/postgres)

## API Usage

The API is available at `http://localhost:4000/api/v1`. Here are the available endpoints with curl examples:

### Users

#### Create User
```bash
curl -X POST http://localhost:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john.doe@example.com"
  }'
```

### Raffles

#### Create Raffle
```bash
curl -X POST http://localhost:4000/api/v1/raffles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Celta Preto"
  }'
```

#### Join Raffle
```bash
# Replace {raffle_id} and {user_id} with actual UUIDs
curl -X POST http://localhost:4000/api/v1/raffles/{raffle_id}/join \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "{user_id}"
  }'

# Example with sample UUIDs:
curl -X POST http://localhost:4000/api/v1/raffles/ad43b63c-e3d6-48e9-9d66-bc5583992297/join \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "d6beaa2a-f6aa-476d-a0ce-11c9bfde3cf8"
  }'
```

### Testing the API

You can test the API endpoints using the provided Bruno collection in the `docs/` directory, or use the curl commands above.

## Development

### Available Mix Tasks

```bash
# Setup project (install deps + database)
mix setup

# Run tests
mix test

# Check code formatting
mix format --check-formatted

# Run static analysis
mix credo

# Database operations
mix ecto.create
mix ecto.migrate
mix ecto.rollback
mix ecto.reset
```

### Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart a service
docker-compose restart raffle-db
docker-compose restart raffle-rabbitmq
```

### Troubleshooting

#### Common Issues

1. **Port conflicts**: If ports 4000, 5433, or 5672 are in use, modify the ports in `docker-compose.yml`

2. **asdf not loading**: Ensure your shell profile is updated:
   ```bash
   echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **direnv not working**: Check if direnv is hooked:
   ```bash
   echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
   source ~/.zshrc
   direnv allow
   ```

4. **Database connection issues**: Ensure PostgreSQL is running:
   ```bash
   docker-compose ps
   docker-compose logs raffle-db
   ```

5. **RabbitMQ connection issues**: Check RabbitMQ status:
   ```bash
   docker-compose logs raffle-rabbitmq
   ```

#### Environment Verification

```bash
# Check asdf versions
asdf current

# Check if environment variables are loaded
env | grep RABBITMQ
env | grep USERS

# Test database connection
mix ecto.migrate

# Test RabbitMQ connection (if applicable)
# Check application logs when starting
```

## Dependencies

Key dependencies (see `mix.exs`):

- **Phoenix** ~> 1.8 - Web framework
- **Ecto & Postgrex** - Database abstraction and PostgreSQL adapter
- **Broadway & BroadwayRabbitMQ** - Message processing pipelines
- **Swoosh** - Email delivery
- **Req** - HTTP client
- **Jason** - JSON encoding/decoding
- **Bandit** - HTTP server adapter
- **ElixirUUID** - UUID generation
- **Oban** - Background job processing

See `mix.exs` for the complete list of dependencies.

## Project Guidelines

Please follow the coding and usage guidelines:

- Use the `:req` library for HTTP requests
- Follow Phoenix v1.8 LiveView and component conventions
- Apply Elixir and Mix best practices
- Use Broadway for message processing
- Follow conventional commit messages

## Production Deployment

For production deployment:

1. **Environment Variables**: Set all required environment variables
2. **Database**: Ensure PostgreSQL is properly configured
3. **RabbitMQ**: Configure RabbitMQ cluster for high availability
4. **Security**: Update default passwords and credentials
5. **Monitoring**: Set up application and infrastructure monitoring

Ready to run in production? Please [check the Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn More

### Phoenix & Elixir Resources
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Phoenix Docs](https://hexdocs.pm/phoenix)
- [Elixir Forum](https://elixirforum.com/c/phoenix-forum)
- [Phoenix Source](https://github.com/phoenixframework/phoenix)

### Project Dependencies Documentation
- [Broadway](https://hexdocs.pm/broadway/Broadway.html) - Message processing
- [Ecto](https://hexdocs.pm/ecto/Ecto.html) - Database toolkit
- [Oban](https://hexdocs.pm/oban/Oban.html) - Background job processing
- [Swoosh](https://hexdocs.pm/swoosh/Swoosh.html) - Email delivery

## Contributing

1. Follow the setup instructions above
2. Create a feature branch from `master`
3. Make your changes with tests
4. Run the full test suite: `mix test`
5. Check code formatting: `mix format --check-formatted`
6. Submit a pull request

## License

This project is licensed under [LICENSE_TYPE] - see the LICENSE file for details.
