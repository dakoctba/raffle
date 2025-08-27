# Processo de Enfileiramento de Usuários - RaffleAPI

## Visão Geral

Este documento descreve o processo de enfileiramento de novos usuários na RaffleAPI, incluindo o sistema de filas RabbitMQ, retry automático e Dead Letter Queue (DLQ).

## Arquitetura do Sistema

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
        MAIN_Q[raffle_queue<br/>Principal]
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

## Fluxo Detalhado do Processo

```mermaid
sequenceDiagram
    participant Client
    participant API as UserController
    participant Pub as Publisher
    participant RMQ as RabbitMQ
    participant Con as Consumer
    participant DB as Database
    participant DLQ as DLQConsumer

    Note over Client, DLQ: 1. Criação de Usuário

    Client->>API: POST /users {name, email}
    API->>API: Gera UUID
    API->>Pub: publish_user(data)
    Pub->>RMQ: Publica na raffle_queue
    API->>Client: 200 {id: uuid}

    Note over Client, DLQ: 2. Processamento Normal

    RMQ->>Con: Consome mensagem
    Con->>Con: Valida JSON
    Con->>Con: Agrupa em batch
    Con->>DB: INSERT batch de usuários

    alt Sucesso
        DB->>Con: OK
        Con->>RMQ: ACK mensagem
    else Erro de DB (tentativas < 3)
        DB->>Con: Erro
        Con->>Con: Incrementa x-retries
        Con->>Pub: publish_retry(data, attempt+1)
        Pub->>RMQ: Publica na retry_queue
        Con->>RMQ: ACK mensagem original

        Note over RMQ: TTL de 10s expira
        RMQ->>RMQ: Move retry -> raffle_queue

        Note over Client, DLQ: Processo se repete

    else Erro de DB (tentativas >= 3)
        DB->>Con: Erro
        Con->>RMQ: REJECT mensagem
        RMQ->>RMQ: Move para DLQ via DLX

        Note over Client, DLQ: 3. Processamento DLQ

        RMQ->>DLQ: Consome da raffle_dlq
        DLQ->>DLQ: Valida JSON
        DLQ->>DLQ: Agrupa em batch
        DLQ->>DB: INSERT batch (manual)

        alt Sucesso
            DB->>DLQ: OK
            DLQ->>RMQ: ACK mensagem
        else Falha
            DLQ->>RMQ: REJECT and REQUEUE
        end
    end
```

## Configuração das Filas

### Fila Principal (raffle_queue)
```mermaid
graph LR
    subgraph "raffle_queue"
        A[Mensagens dos usuários]
        B[x-dead-letter-exchange: raffle_dlx]
        C[x-dead-letter-routing-key: raffle_dlq]
    end
```

### Fila de Retry (raffle_retry_10s)
```mermaid
graph LR
    subgraph "raffle_retry_10s"
        A[Mensagens com falha]
        B[x-message-ttl: 10000ms]
        C[x-dead-letter-exchange: raffle_exchange]
        D[x-dead-letter-routing-key: raffle_queue]
    end
```

### Dead Letter Queue (raffle_dlq)
```mermaid
graph LR
    subgraph "raffle_dlq"
        A[Mensagens esgotadas]
        B[Processamento manual]
        C[Reject + Requeue em falha]
    end
```

## Estados das Mensagens

```mermaid
stateDiagram-v2
    [*] --> Published: API publica
    Published --> Processing: Consumer pega
    Processing --> Success: DB OK
    Processing --> Retry: DB Error (attempt < 3)
    Processing --> DLQ: DB Error (attempt >= 3)
    Processing --> DLQ: JSON inválido

    Retry --> Waiting: TTL ativo (10s)
    Waiting --> Processing: TTL expira

    DLQ --> DLQProcessing: DLQ Consumer
    DLQProcessing --> Success: DB OK
    DLQProcessing --> DLQRequeue: DB Error
    DLQRequeue --> DLQProcessing: Retry manual

    Success --> [*]
```

## Headers de Controle

### Mensagem Original
```json
{
  "id": "uuid-v4",
  "name": "João Silva",
  "email": "joao@email.com"
}
```

### Mensagem com Retry
```json
Headers: {
  "x-retries": 1,
  "x-retry-reason": "db_error: connection timeout"
}
Body: {
  "id": "uuid-v4",
  "name": "João Silva",
  "email": "joao@email.com"
}
```

## Configurações de Environment

| Variável | Padrão | Descrição |
|----------|---------|-----------|
| `RETRY_TTL_MS` | 10000 | TTL da fila de retry em ms |
| `MAX_RETRIES` | 3 | Máximo de tentativas antes do DLQ |
| `USERS_BATCH_SIZE` | 1000 | Tamanho do batch para inserção |
| `USERS_BATCH_TIMEOUT_MS` | 1000 | Timeout do batch em ms |
| `USERS_PROC_CONCURRENCY` | 8 | Concorrência dos processors |
| `USERS_BATCH_CONCURRENCY` | 2 | Concorrência dos batchers |

## Monitoramento e Observabilidade

### Logs Importantes

1. **Publisher**: Falhas de conexão e publicação
2. **Consumer**: Erros de processamento e retry
3. **DLQConsumer**: Processamento manual de mensagens falhas

### Métricas Sugeridas

- Taxa de sucesso do consumer principal
- Número de mensagens na fila de retry
- Número de mensagens no DLQ
- Latência de processamento
- Taxa de erro por tipo

## Cenários de Falha

### 1. Falha Temporária de Banco
- **Ação**: Retry automático com backoff (TTL)
- **Limite**: 3 tentativas
- **Recovery**: Automático quando DB volta

### 2. Falha Persistente de Banco
- **Ação**: Mensagem vai para DLQ
- **Recovery**: Processamento manual via DLQConsumer

### 3. JSON Malformado
- **Ação**: Reject direto para DLQ
- **Recovery**: Log de erro, mensagem descartada

### 4. Falha do RabbitMQ
- **Ação**: Publisher retorna erro para API
- **Recovery**: Cliente pode tentar novamente

## Considerações de Performance

- **Batching**: Reduz overhead de transações DB
- **Concorrência**: Configurável por ambiente
- **Persistência**: Mensagens sobrevivem a restarts
- **Durabilidade**: Filas e exchanges são duráveis

## Gerando Imagens dos Diagramas

Para gerar as imagens dos diagramas Mermaid, você pode usar:

1. **Mermaid CLI**:
```bash
# Instalar mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Gerar imagens (executar na raiz do projeto)
mmdc -i docs/user_queue_process.md -o docs/images/ -t dark
```

2. **Online**: Copie os diagramas para [Mermaid Live Editor](https://mermaid.live/) e exporte as imagens.

3. **VS Code**: Use a extensão "Mermaid Preview" para visualizar e exportar.
