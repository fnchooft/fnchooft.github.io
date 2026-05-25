#!/bin/bash

# Usage: ./remove-loss.sh <container_name> (e.g., db-primary)

if [ -z "$1" ]; then
  echo "Usage: $0 <container_name>"
  exit 1
fi

CONTAINER="$1"

docker exec "$CONTAINER" tc qdisc del dev eth0 root || true

echo "Removed packet loss from $CONTAINER"