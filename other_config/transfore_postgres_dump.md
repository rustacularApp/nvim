# dump
docker exec -t <postgresContainerName> pg_dump -U postgres -d <yourDbName> -F c -b > mydb.dump

# restore
docker exec -i <postgresContainerName> pg_restore -U postgres -d <yourDbName> -v < mydb.dump
