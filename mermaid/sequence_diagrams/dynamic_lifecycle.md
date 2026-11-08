```mermaid
sequenceDiagram
    Alice->>Bob: Hello
    create participant Worker
    Bob->>Worker: Spawn thread
    Worker-->>Bob: Work done
    destroy Worker
    Bob-xWorker: Terminate process
```
