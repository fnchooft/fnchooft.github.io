# Use the official PostgreSQL image
FROM postgres:latest

# The postgres image will automatically run scripts in this directory on first startup.
# The scripts are run in alphabetical order.
COPY sql/ /docker-entrypoint-initdb.d/

