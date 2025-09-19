#!/bin/bash

# Script to restart Microvolts Emulator servers
# Usage: ./restart_servers.sh [server_name]
# Available servers: auth, main, cast, db, all

SERVICES=("auth-server" "main-server" "cast-server" "db")

show_usage() {
    echo "Usage: $0 [server_name]"
    echo "Available options:"
    echo "  auth    - Restart Auth Server"
    echo "  main    - Restart Main Server"
    echo "  cast    - Restart Cast Server"
    echo "  db      - Restart Database"
    echo "  all     - Restart all servers"
    echo ""
    echo "If no argument provided, shows this help."
}

if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

SERVER="$1"

case "$SERVER" in
    auth)
        echo "Restarting Auth Server..."
        docker-compose restart auth-server
        ;;
    main)
        echo "Restarting Main Server..."
        docker-compose restart main-server
        ;;
    cast)
        echo "Restarting Cast Server..."
        docker-compose restart cast-server
        ;;
    db)
        echo "Restarting Database..."
        docker-compose restart db
        ;;
    all)
        echo "Restarting all servers..."
        docker-compose restart
        ;;
    *)
        echo "Error: Unknown server '$SERVER'"
        show_usage
        exit 1
        ;;
esac

echo "Restart completed!"