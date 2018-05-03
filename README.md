# For Docker

## Docker clean

```bash
# Stop all containers
docker stop $(docker ps -a -q)
# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)
# Remove all system volumes
docker volume rm $(docker volume ls -q)
```

## First step

```bash
docker-compose build
docker-compose run app bash -c 'bundle check || bundle install --clean'
docker-compose run app bundle exec rails db:create db:migrate db:seed
```

## Additional command

```bash
docker-compose up --build
docker-compose down
docker-compose run app bash
```
