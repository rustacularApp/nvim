# dump
docker exec <source_container> pg_dump -U <source_user> -F c -f /tmp/backup.dump news_template

docker cp <source_container>:/tmp/backup.dump ./news_template.dump

# restore
docker cp Downloads/news_template.dump db:/tmp/news_template.dump

docker exec -it db pg_restore -U sohailmd123 -d news_template -v /tmp/news_template.dump
