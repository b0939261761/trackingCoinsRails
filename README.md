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
docker-compose up --detach
docker-compose down
docker-compose run app bash
```

Create file

```bash
vim /lib/systemd/system/coins.service
```

```txt
[Unit]
Description=Docker compose for services
After=docker.service
Conflicts=shutdown.target reboot.target halt.target

[Service]
Restart=always
RestartSec=10
ExecStart=/usr/local/bin/docker-compose  -f /var/www/coins/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose  -f /var/www/coins/docker-compose.yml down
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=10
TimeoutStopSec=30
StartLimitBurst=3
StartLimitInterval=60s
NotifyAccess=all

[Install]
WantedBy=multi-user.target
```

Run docker

```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker
```

Run docker-compose project

```bash
sudo systemctl enable coins
sudo systemctl start coins
sudo systemctl status coins
```
