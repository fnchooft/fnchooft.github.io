# Makefile for Postgres Network Simulation Example

.PHONY: all build start stop cleanup clean logs clean-logs

all: build start

build:
	docker build -t postgres-iproute2:16 .

start:
	docker-compose up -d --remove-orphans
	@echo "Services started. Wait ~1-2 minutes for replication setup (check 'docker logs db-secondary' for 'streaming WAL')."

stop:
	docker-compose stop
	@echo "Services stopped."

cleanup:
	docker-compose down -v --remove-orphans
	@echo "Services stopped and resources (containers, networks, volumes, orphans) removed."

clean:
	docker-compose down -v --remove-orphans --rmi all
	@echo "All resources (containers, networks, volumes, images, orphans) removed."

logs:
	@echo "Dumping logs for all services..."
	@for service in db-primary db-secondary proxy client1 client2 client3; do \
		echo "=== $$service Logs ==="; \
		docker logs $$service; \
	done

clean-logs:
	@echo "Cleaning logs for all services..."
	@for service in db-primary db-secondary proxy client1 client2 client3; do \
		docker logs $$service --no-log > /dev/null 2>&1 || true; \
	done
	@echo "Logs cleaned."


NETWORK_NAME=app-net

ips:
	@echo "Inspecting container IPs on the '$(NETWORK_NAME)' network..."
	@docker-compose ps -q | xargs -r docker inspect -f \
		'{{printf "%-25s %s" (slice .Name 1) (index .NetworkSettings.Networks "$(NETWORK_NAME)").IPAddress}}'
