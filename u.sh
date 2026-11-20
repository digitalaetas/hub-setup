#!/usr/bin/env bash
set -euo pipefail
cd /opt/hub
git fetch -q origin main
git reset -q --hard origin/main
docker compose -f docker-compose.prod.yml up -d --build
echo '* * * * * root flock -n /tmp/hub-update.lock /opt/hub/deploy/autoupdate.sh >> /var/log/hub-update.log 2>&1' > /etc/cron.d/hub-update
echo GOTOVO
