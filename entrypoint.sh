#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/app/Setup/config.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: $CONFIG_FILE not found in container image." >&2
  exit 1
fi

# Defaults that work for docker-compose networking.
: "${MV_DB_HOST:=db}"
: "${MV_DB_PORT:=3306}"
: "${MV_DB_NAME:=microvolts-db}"
: "${MV_DB_USER:=microvolts}"
: "${MV_DB_PASSWORD_ENV:=MV_DB_PW}"

# Patch config.ini in-place based on env.
sed -i "s|^Ip = .*|Ip = ${MV_DB_HOST}|" "$CONFIG_FILE" || true
sed -i "s|^Port = .*|Port = ${MV_DB_PORT}|" "$CONFIG_FILE" || true
sed -i "s|^DatabaseName = .*|DatabaseName = ${MV_DB_NAME}|" "$CONFIG_FILE" || true
sed -i "s|^Username = .*|Username = ${MV_DB_USER}|" "$CONFIG_FILE" || true
sed -i "s|^PasswordEnvironmentName = .*|PasswordEnvironmentName = ${MV_DB_PASSWORD_ENV}|" "$CONFIG_FILE" || true

# If the password env var is not present, warn (DB may still start with defaults).
if [[ -z "${!MV_DB_PASSWORD_ENV:-}" ]]; then
  echo "Warning: environment variable '$MV_DB_PASSWORD_ENV' is not set." >&2
fi

exec "$@"

