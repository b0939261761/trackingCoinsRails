#!/bin/bash

# Add to cron
# crontab -e
# 00 23 * * Sat /var/www/coins/certbot_renew.sh

# Set execute permission on your script
# chmod +x certbot_renew.sh

docker run --rm --name certbot -v "/var/www/coins/site/letsencrypt:/etc/letsencrypt" certbot/certbot renew
docker-compose --file /var/www/coins/docker-compose.yml restart nginx

