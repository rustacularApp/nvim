
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
