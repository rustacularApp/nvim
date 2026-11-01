docker exec -t <postgresContainerName> pg_dump -U postgres -d <yourDbName> -F c -b > mydb.dump
