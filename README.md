# 💤 LazyVim


A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started



# Architecture Flow

```mermaid
graph TD
    Client[Web Client] -->|API Request| Gateway[API Gateway]
    Gateway --> Auth[Auth Service]
    Gateway --> Backend[Rust Backend]
    Backend --> Database[(PostgreSQL)]
```

```d2
direction: right
frontend: Web App
backend: Axum Server
db: Postgres

frontend -> backend: REST API
backend -> db: SQL Queries
```


```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Frontend
    participant Backend as Rust Server
    participant DB as Postgres

    User->>Frontend: Click "Login"
    Frontend->>Backend: POST /auth/login
    Backend->>DB: SELECT * FROM users WHERE email = ?
    DB-->>Backend: User row + password_hash
    Backend-->>Frontend: 200 OK (JWT Token)
    Frontend-->>User: Redirect to Dashboard
```




```mermaid
sequenceDiagram
    actor Client
    participant API as Rust Server

    Client ->>+ API: POST /orders
    Note over API: API is busy processing here
    API -->>- Client: 201 Created





```


```mermaid
sequenceDiagram
    actor User
    participant API

    User->>API: POST /auth
    alt Valid Password
        API-->>User: 200 OK + JWT
    else Invalid Password
        API-->>User: 401 Unauthorized
    end
```
```



```mermaid
sequenceDiagram
    participant API
    participant Metric as Prometheus
    opt Metrics Enabled
        API->> Metric: Increment request_counter
    end

```
