# Docker Commands

docker-compose up -d

docker-commpose down -v

docker ps -a

docker logs <container_name>

docker inspect <container_name> --format '{{json .Config.Env}}' | jq .
