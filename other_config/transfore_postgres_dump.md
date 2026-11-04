# dump
docker exec <sourceContainer> pg_dump -U <sourceUser> -F c -f /tmp/backup.dump news_template

docker cp <sourceContainer>:/tmp/backup.dump ./news_template.dump

# restore
docker cp Downloads/news_template.dump db:/tmp/news_template.dump

docker exec -it <sourceContainer> pg_restore -U <sourceUser> -d news_template -v /tmp/news_template.dump
