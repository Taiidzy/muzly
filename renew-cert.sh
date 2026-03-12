#!/bin/bash

# Renew SSL certificates for Muzly
# Run this periodically (e.g., via cron) to keep certificates valid

set -e

echo "Renewing SSL certificates..."

docker compose run --rm certbot renew

echo "Restarting nginx to apply new certificates..."
docker compose restart nginx

echo "Done!"
