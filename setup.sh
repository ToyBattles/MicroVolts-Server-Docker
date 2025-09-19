#!/bin/bash

# Setup script for Microvolts Emulator Docker
# Configures database settings and creates docker-compose override

CONFIG_FILE="./Setup/config.ini"
OVERRIDE_FILE="docker-compose.override.yml"

# Default values
DB_HOST="127.0.0.1"
DB_PORT="3305"
DB_NAME="microvolts-db"
DB_USER="root"
DB_PASSWORD_ENV="MV_DB_PASSWORD"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --db-host)
      DB_HOST="$2"
      shift 2
      ;;
    --db-port)
      DB_PORT="$2"
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
      echo "  --db-host HOST          Database host IP (default: 127.0.0.1)"
      echo "  --db-port PORT          Database port (default: 3305)"
      echo "  --db-name NAME          Database name (default: microvolts-db)"
      echo "  --db-user USER          Database user (default: root)"
      echo "  --db-password-env ENV   Environment variable name for password (default: MV_DB_PASSWORD)"
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

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

echo "Updating configuration with:"
echo "  DB Host: $DB_HOST"
echo "  DB Port: $DB_PORT"
echo "  DB Name: $DB_NAME"
echo "  DB User: $DB_USER"
echo "  DB Password Env: $DB_PASSWORD_ENV"
echo ""

# Update config.ini
sed -i "s|^Ip = .*|Ip = $DB_HOST|" "$CONFIG_FILE"
sed -i "s|^Port = .*|Port = $DB_PORT|" "$CONFIG_FILE"
sed -i "s|^DatabaseName = .*|DatabaseName = $DB_NAME|" "$CONFIG_FILE"
sed -i "s|^Username = .*|Username = $DB_USER|" "$CONFIG_FILE"
sed -i "s|^PasswordEnvironmentName = .*|PasswordEnvironmentName = $DB_PASSWORD_ENV|" "$CONFIG_FILE"

echo "Configuration updated successfully!"

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
      - "$DB_PORT:3306"

  auth-server:
    environment:
      - $DB_PASSWORD_ENV

  main-server:
    environment:
      - $DB_PASSWORD_ENV

  cast-server:
    environment:
      - $DB_PASSWORD_ENV
EOF

echo "Docker Compose override file created: $OVERRIDE_FILE"
echo ""
echo "Next steps:"
echo "1. Set your database password environment variable:"
echo "   export $DB_PASSWORD_ENV=your_actual_password"
echo "2. Run: docker-compose up --build -d"
echo ""
echo "Note: Make sure the password environment variable is set before running docker-compose."