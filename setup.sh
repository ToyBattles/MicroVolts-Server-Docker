#!/bin/bash

# Setup script for Microvolts Emulator Docker
# Generates docker-compose override to configure DB + server containers via env.

OVERRIDE_FILE="docker-compose.override.yml"

# Default values (for docker compose internal networking)
DB_HOST="db"

# Host-exposed DB port (internal MariaDB port is always 3306)
DB_HOST_PORT="3305"

DB_NAME="microvolts-db"
DB_USER="microvolts"

# Name of the environment variable that will hold the DB password value.
# This repo defaults to MV_DB_PW (see docker-compose.yml).
DB_PASSWORD_ENV="MV_DB_PW"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --db-host)
      DB_HOST="$2"
      shift 2
      ;;
    --db-port)
      DB_HOST_PORT="$2"
      shift 2
      ;;
    --db-name)
      DB_NAME="$2"
      shift 2
      ;;
    --db-user)
      DB_USER="$2"
      shift 2
      ;;
    --db-password-env)
      DB_PASSWORD_ENV="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --db-host HOST          Database host (default: db)"
      echo "  --db-port PORT          Database host-exposed port (default: 3305)"
      echo "  --db-name NAME          Database name (default: microvolts-db)"
      echo "  --db-user USER          Database user (default: microvolts)"
      echo "  --db-password-env ENV   Environment variable name for password (default: MV_DB_PW)"
      echo "  --help                  Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage"
      exit 1
      ;;
  esac
done

echo "Updating configuration with:"
echo "  DB Host: $DB_HOST"
echo "  DB Host Port: $DB_HOST_PORT"
echo "  DB Name: $DB_NAME"
echo "  DB User: $DB_USER"
echo "  DB Password Env: $DB_PASSWORD_ENV"
echo ""

# Create docker-compose.override.yml
cat > "$OVERRIDE_FILE" << EOF
version: '3.8'

services:
  db:
    environment:
      MYSQL_ROOT_PASSWORD: \${$DB_PASSWORD_ENV}
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: \${$DB_PASSWORD_ENV}
    ports:
      - "$DB_HOST_PORT:3306"

  auth-server:
    environment:
      - $DB_PASSWORD_ENV
      - MV_DB_PASSWORD_ENV=$DB_PASSWORD_ENV
      - MV_DB_HOST=$DB_HOST
      - MV_DB_PORT=3306
      - MV_DB_NAME=$DB_NAME
      - MV_DB_USER=$DB_USER

  main-server:
    environment:
      - $DB_PASSWORD_ENV
      - MV_DB_PASSWORD_ENV=$DB_PASSWORD_ENV
      - MV_DB_HOST=$DB_HOST
      - MV_DB_PORT=3306
      - MV_DB_NAME=$DB_NAME
      - MV_DB_USER=$DB_USER

  cast-server:
    environment:
      - $DB_PASSWORD_ENV
      - MV_DB_PASSWORD_ENV=$DB_PASSWORD_ENV
      - MV_DB_HOST=$DB_HOST
      - MV_DB_PORT=3306
      - MV_DB_NAME=$DB_NAME
      - MV_DB_USER=$DB_USER
EOF

echo "Docker Compose override file created: $OVERRIDE_FILE"
echo ""
echo "Next steps:"
echo "1. Set your database password environment variable:"
echo "   export $DB_PASSWORD_ENV=your_actual_password"
echo "2. Run: docker compose up --build -d"
echo ""
echo "Note: Make sure the password environment variable is set before running docker compose."
