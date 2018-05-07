#!/bin/bash

# Add to cron
# crontab -e
# 00 23 * * Sat /var/www/coins/certbot_renew.sh

# Watch crom lon
# tail /var/log/cron

# Set execute permission on your script
# chmod +x certbot_renew.sh

# Program path
# type docker-compose

docker run --rm --name certbot -v "/var/www/coins/site/letsencrypt:/etc/letsencrypt" certbot/certbot renew
 /usr/local/bin/docker-compose docker-compose --file /var/www/coins/docker-compose.yml restart nginx

