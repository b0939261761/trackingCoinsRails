# For Docker

## Other

```bahs
# Change credentials
docker-compose run app bundle exec rails credentials:edit
```

## Docker clean

```bash
# Stop all containers
docker stop $(docker ps -a -q)
# Delete all containers
docker rm $(docker ps -a -q)
# Delete all network
docker network rm $(docker network ls --quiet)
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

## Create service file

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
WorkingDirectory=/var/www/coins
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
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
sudo systemctl daemon-reload
sudo systemctl enable coins
sudo systemctl start coins
sudo systemctl status coins
sudo systemctl restart coins
```

## Docker certbot

Add certificate

```bash
sudo docker run --rm --name certbot -v "/var/www/coins/site/letsencrypt:/etc/letsencrypt" certbot/certbot certonly --webroot --agree-tos --manual-public-ip-logging-ok --domains domain.name --email example@example.com --webroot-path /etc/letsencrypt
```

Update certificate

```bash
sudo docker run --rm --name certbot -v "/var/www/coins/site/letsencrypt:/etc/letsencrypt" certbot/certbot renew
```

## nginx.conf

```txt
# disable when not https
ssl_certificate ssl/coins/live/realitycoins.cf/fullchain.pem;
ssl_certificate_key ssl/coins/live/realitycoins.cf/privkey.pem;

server {
  listen 80;
  listen [::]:80; #Added IPv6 here too

  # for certbot
  location ^~ /.well-known/acme-challenge/ {
    root /var/www/coins/letsencrypt;
  }

  # disable when not https
  return 301 https://realitycoins.cf$request_uri;
}

server {
  listen 8090 ssl;
  listen [::]:8090 ssl;

  # for telegram bot
  listen 8443 ssl;


  location / {
    proxy_pass http://app:8080;
  }
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;

  root /var/www/coins;

  # for SPA
  location / {
    try_files $uri $uri/ /index.html;
  }
}


```

## Add to cron *certbot_renew.sh*. Readme inside file

## Telegram bot

For more information, see:
<https://www.rubydoc.info/gems/telegram-bot/0.4.2>
<https://github.com/telegram-bot-rb/telegram-bot>

### Add row in /config/environments/production.rb

```ruby
routes.default_url_options = { host: ENV['TELEGRAM_BOT_HOST_PORT'], protocol: :https }
```

### Add file /config/initializers/telegram_bot.rb

```ruby
Telegram.bots_config = { default: ENV['TELEGRAM_BOT_TOKEN'] }
```

### Setup webhooks, check after setup <https://api.telegram.org/bot[TOKEN]/getWebhookInfo>

```bash
docker-compose run app bundle exec rake telegram:bot:set_webhook RAILS_ENV=production
```

### Run bot for test - poller-mode

```bash
docker-compose run app bundle exec rake telegram:bot:poller
``
