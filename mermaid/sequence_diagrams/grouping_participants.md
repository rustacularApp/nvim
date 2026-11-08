```mermaid
sequenceDiagram
    box DarkYellow Frontend Tier
        actor Client
        participant WebApp
    end

    box rgba(0, 150, 255, 0.15) Backend Tier
        participant API
        participant DB
    end

    Client->>WebApp: Click
    WebApp->>API: HTTP Request
    API->>DB: SQL Query
```
