# User Queuing Process - RaffleAPI

## Overview

This document describes the user enrollment queuing process in RaffleAPI, including the RabbitMQ queue system, automatic retry, and Dead Letter Queue (DLQ).

## System Architecture

```mermaid
graph TB
    subgraph "Client/API"
        API[REST API<br/>/api/v1/users]
    end

    subgraph "Publisher"
        PUB[Users.Publisher<br/>GenServer]
    end

    subgraph "RabbitMQ Exchanges"
        MAIN_EX[raffle_exchange<br/>Direct]
        RETRY_EX[raffle_retry_exchange<br/>Direct]
        DLX_EX[raffle_dlx<br/>Direct]
    end

    subgraph "RabbitMQ Queues"
        MAIN_Q[raffle_queue<br/>Main Queue]
        RETRY_Q[raffle_retry_10s<br/>TTL: 10s]
        DLQ_Q[raffle_dlq<br/>Dead Letter]
    end

    subgraph "Consumers Broadway"
        CONSUMER[Users.Consumer<br/>Broadway Pipeline]
        DLQ_CONSUMER[DLQConsumer<br/>Broadway Pipeline]
    end

    subgraph "Database"
        DB[(PostgreSQL<br/>users table)]
    end

    API --> PUB
    PUB --> MAIN_EX
    PUB --> RETRY_EX

    MAIN_EX --> MAIN_Q
    RETRY_EX --> RETRY_Q
    DLX_EX --> DLQ_Q

    MAIN_Q --> CONSUMER
    DLQ_Q --> DLQ_CONSUMER

    CONSUMER --> DB
    DLQ_CONSUMER --> DB

    %% Dead Letter routing
    MAIN_Q -.->|DLX on reject| DLX_EX
    RETRY_Q -.->|TTL expired| MAIN_EX
```

## Detailed Process Flow

```mermaid
sequenceDiagram
    participant Client
    participant API as UserController
    participant Pub as Publisher
    participant RMQ as RabbitMQ
    participant Con as Consumer
    participant DB as Database
    participant DLQ as DLQConsumer

    Note over Client, DLQ: 1. User Creation

    Client->>API: POST /users {name, email}
    API->>API: Generate UUID
    API->>Pub: publish_user(data)
    Pub->>RMQ: Publish to raffle_queue
    API->>Client: 200 {id: uuid}

    Note over Client, DLQ: 2. Normal Processing

    RMQ->>Con: Consume message
    Con->>Con: Validate JSON
    Con->>Con: Group into batch
    Con->>DB: INSERT user batch

    alt Success
        DB->>Con: OK
        Con->>RMQ: ACK message
    else DB Error (attempts < 3)
        DB->>Con: Error
        Con->>Con: Increment x-retries
        Con->>Pub: publish_retry(data, attempt+1)
        Pub->>RMQ: Publish to retry_queue
        Con->>RMQ: ACK original message

        Note over RMQ: 10s TTL expires
        RMQ->>RMQ: Move retry -> raffle_queue

        Note over Client, DLQ: Process repeats

    else DB Error (attempts >= 3)
        DB->>Con: Error
        Con->>RMQ: REJECT message
        RMQ->>RMQ: Move to DLQ via DLX

        Note over Client, DLQ: 3. DLQ Processing

        RMQ->>DLQ: Consume from raffle_dlq
        DLQ->>DLQ: Validate JSON
        DLQ->>DLQ: Group into batch
        DLQ->>DB: INSERT batch (manual)

        alt Success
            DB->>DLQ: OK
            DLQ->>RMQ: ACK message
        else Failure
            DLQ->>RMQ: REJECT and REQUEUE
        end
    end
```

## Queue Configuration

### Main Queue (raffle_queue)
```mermaid
graph LR
    subgraph "raffle_queue"
        A[User messages]
        B[x-dead-letter-exchange: raffle_dlx]
        C[x-dead-letter-routing-key: raffle_dlq]
    end
```

### Retry Queue (raffle_retry_10s)
```mermaid
graph LR
    subgraph "raffle_retry_10s"
        A[Failed messages]
        B[x-message-ttl: 10000ms]
        C[x-dead-letter-exchange: raffle_exchange]
        D[x-dead-letter-routing-key: raffle_queue]
    end
```

### Dead Letter Queue (raffle_dlq)
```mermaid
graph LR
    subgraph "raffle_dlq"
        A[Exhausted messages]
        B[Manual processing]
        C[Reject + Requeue on failure]
    end
```

## Message States

```mermaid
stateDiagram-v2
    [*] --> Published: API publishes
    Published --> Processing: Consumer picks up
    Processing --> Success: DB OK
    Processing --> Retry: DB Error (attempt < 3)
    Processing --> DLQ: DB Error (attempt >= 3)
    Processing --> DLQ: Invalid JSON

    Retry --> Waiting: TTL active (10s)
    Waiting --> Processing: TTL expires

    DLQ --> DLQProcessing: DLQ Consumer
    DLQProcessing --> Success: DB OK
    DLQProcessing --> DLQRequeue: DB Error
    DLQRequeue --> DLQProcessing: Manual retry

    Success --> [*]
```

## Control Headers

### Original Message
```json
{
  "id": "uuid-v4",
  "name": "John Silva",
  "email": "john@email.com"
}
```

### Message with Retry
```json
Headers: {
  "x-retries": 1,
  "x-retry-reason": "db_error: connection timeout"
}
Body: {
  "id": "uuid-v4",
  "name": "John Silva",
  "email": "john@email.com"
}
```

## Environment Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `RETRY_TTL_MS` | 10000 | Retry queue TTL in ms |
| `MAX_RETRIES` | 3 | Maximum attempts before DLQ |
| `USERS_BATCH_SIZE` | 1000 | Batch size for insertion |
| `USERS_BATCH_TIMEOUT_MS` | 1000 | Batch timeout in ms |
| `USERS_PROC_CONCURRENCY` | 8 | Processor concurrency |
| `USERS_BATCH_CONCURRENCY` | 2 | Batcher concurrency |

## Monitoring and Observability

### Important Logs

1. **Publisher**: Connection and publication failures
2. **Consumer**: Processing errors and retries
3. **DLQConsumer**: Manual processing of failed messages

### Suggested Metrics

- Main consumer success rate
- Number of messages in retry queue
- Number of messages in DLQ
- Processing latency
- Error rate by type

## Failure Scenarios

### 1. Temporary Database Failure
- **Action**: Automatic retry with backoff (TTL)
- **Limit**: 3 attempts
- **Recovery**: Automatic when DB comes back

### 2. Persistent Database Failure
- **Action**: Message goes to DLQ
- **Recovery**: Manual processing via DLQConsumer

### 3. Malformed JSON
- **Action**: Direct reject to DLQ
- **Recovery**: Error log, message discarded

### 4. RabbitMQ Failure
- **Action**: Publisher returns error to API
- **Recovery**: Client can retry

## Performance Considerations

- **Batching**: Reduces DB transaction overhead
- **Concurrency**: Configurable per environment
- **Persistence**: Messages survive restarts
- **Durability**: Queues and exchanges are durable

## Generating Diagram Images

To generate images from Mermaid diagrams, you can use:

1. **Mermaid CLI**:
```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Generate images (run from project root)
mmdc -i docs/user_queue_process.md -o docs/images/ -t dark
```

2. **Online**: Copy diagrams to [Mermaid Live Editor](https://mermaid.live/) and export images.

3. **VS Code**: Use "Mermaid Preview" extension to visualize and export.
