#!/bin/bash

# Scenario 3: 20% packet loss from client1 towards proxy (adapt for client2/client3 by changing CONTAINER)

CONTAINER="client1"
TARGET_CONTAINER="proxy"
LOSS_PERCENT="20%"
MAX_RETRIES=5
RETRY_INTERVAL=2

# Check if proxy container is running
if ! docker ps --filter "name=$TARGET_CONTAINER" --format '{{.Names}}' | grep -q "^$TARGET_CONTAINER$"; then
  echo "Error: $TARGET_CONTAINER is not running"
  exit 1
fi

# Get target IP with retries
TARGET_IP=""
for ((i=1; i<=MAX_RETRIES; i++)); do
  TARGET_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$TARGET_CONTAINER")
  if [ -n "$TARGET_IP" ]; then
    break
  fi
  echo "Attempt $i/$MAX_RETRIES: Could not retrieve IP for $TARGET_CONTAINER, retrying in $RETRY_INTERVAL seconds..."
  sleep $RETRY_INTERVAL
done

if [ -z "$TARGET_IP" ]; then
  echo "Error: Could not retrieve IP for $TARGET_CONTAINER after $MAX_RETRIES attempts"
  exit 1
fi

# Verify tc is available
docker exec "$CONTAINER" which tc > /dev/null 2>&1 || {
  echo "Error: tc command not found in $CONTAINER"
  exit 1
}

# Apply tc rules
docker exec "$CONTAINER" tc qdisc del dev eth0 root 2>/dev/null || true
docker exec "$CONTAINER" tc qdisc add dev eth0 root handle 1: htb default 10 || {
  echo "Error: Failed to add root qdisc"
  exit 1
}
docker exec "$CONTAINER" tc class add dev eth0 parent 1: classid 1:10 htb rate 1000mbit || {
  echo "Error: Failed to add default class"
  exit 1
}
docker exec "$CONTAINER" tc class add dev eth0 parent 1: classid 1:20 htb rate 1000mbit || {
  echo "Error: Failed to add loss class"
  exit 1
}
docker exec "$CONTAINER" tc qdisc add dev eth0 parent 1:20 netem loss "$LOSS_PERCENT" || {
  echo "Error: Failed to add netem qdisc"
  exit 1
}
docker exec "$CONTAINER" tc filter add dev eth0 protocol ip prio 1 u32 match ip dst "$TARGET_IP" flowid 1:20 || {
  echo "Error: Failed to add filter for $TARGET_IP"
  exit 1
}

echo "Applied $LOSS_PERCENT packet loss from $CONTAINER to $TARGET_CONTAINER ($TARGET_IP)"