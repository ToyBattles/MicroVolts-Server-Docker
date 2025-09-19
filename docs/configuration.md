# Configuration Guide

This guide covers all configuration options for the Microvolts Emulator Docker setup, from basic database settings to advanced server configurations.

## Database Configuration

### Using the Setup Script

The recommended way to configure the database:

```bash
# Basic configuration
./setup.sh --db-password-env MY_DB_PASSWORD

# Full configuration
./setup.sh \
  --db-host database.example.com \
  --db-port 3306 \
  --db-name microvolts_production \
  --db-user microvolts_user \
  --db-password-env MY_DB_PASSWORD
```

### Manual Database Configuration

Edit `Setup/config.ini`:

```ini
[Database]
LocalIp = 127.0.0.1
Ip = database.example.com
Port = 3306
DatabaseName = microvolts_production
Username = microvolts_user
PasswordEnvironmentName = MY_DB_PASSWORD
```

### Environment Variables

Set the database password:

```bash
export MY_DB_PASSWORD=your_secure_password
```

### Docker Compose Override

The setup script creates `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  db:
    environment:
      MYSQL_ROOT_PASSWORD: ${MY_DB_PASSWORD}
      MYSQL_DATABASE: microvolts_production
      MYSQL_USER: microvolts_user
      MYSQL_PASSWORD: ${MY_DB_PASSWORD}
    ports:
      - "3306:3306"

  auth-server:
    environment:
      - MY_DB_PASSWORD

  main-server:
    environment:
      - MY_DB_PASSWORD

  cast-server:
    environment:
      - MY_DB_PASSWORD
```

## Server Configuration

### Authentication Server

Configure the auth server in `Setup/config.ini`:

```ini
[AuthServer]
LocalIp = 127.0.0.1
Ip = your-server-ip
Port = 13000
```

### Main Server

Configure the main server:

```ini
[MainServer_1]
LocalIp = 127.0.0.1
Ip = your-server-ip
Port = 13005
IpcPort = 14005
IsPublic = true
```

### Cast Server

Configure the cast server:

```ini
[CastServer_1]
LocalIp = 127.0.0.1
Ip = your-server-ip
Port = 13006
IpcPort = 14006
```

### Multiple Servers

Add additional servers:

```ini
[MainServer_2]
LocalIp = 127.0.0.1
Ip = your-server-ip
Port = 13015
IpcPort = 14015
IsPublic = true

[CastServer_2]
LocalIp = 127.0.0.1
Ip = your-server-ip
Port = 13016
IpcPort = 14016
```

## Client Configuration

### Version Settings

Configure client version requirements:

```ini
[Client]
ClientVersion = 1.1.1
```

### Website Integration

Configure website API endpoints:

```ini
[Website]
Ip = your-website-ip
Port = 8080
```

## Advanced Configuration

### Custom Ports

Modify `docker-compose.yml` for custom ports:

```yaml
services:
  db:
    ports:
      - "3307:3306"  # Host:Container

  auth-server:
    ports:
      - "13001:13000"

  main-server:
    ports:
      - "13006:13005"
      - "14006:14005"

  cast-server:
    ports:
      - "13007:13006"
      - "14007:14006"
```

### Environment Variables

Override configuration with environment variables:

```bash
# Database settings
export DB_HOST=database.example.com
export DB_PORT=3306
export DB_NAME=microvolts_db
export DB_USER=microvolts
export DB_PASSWORD_ENV=MY_DB_PASSWORD

# Server settings
export AUTH_PORT=13000
export MAIN_PORT=13005
export CAST_PORT=13006

# Client settings
export CLIENT_VERSION=1.1.1
```

### Docker Compose Environment File

Create a `.env` file for sensitive data:

```bash
# .env file
MY_DB_PASSWORD=super_secret_password
DB_HOST=localhost
DB_PORT=3305
```

Then reference it in `docker-compose.yml`:

```yaml
services:
  db:
    env_file:
      - .env
```

## Network Configuration

### Internal Networking

Services communicate internally using Docker networks:

```yaml
networks:
  microvolts-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### External Access

Configure external access:

```yaml
services:
  auth-server:
    ports:
      - "0.0.0.0:13000:13000"  # Bind to all interfaces
    networks:
      - microvolts-network
```

### Firewall Rules

```bash
# Allow emulator ports
sudo ufw allow 3305/tcp  # Database
sudo ufw allow 13000/tcp # Auth
sudo ufw allow 13005/tcp # Main
sudo ufw allow 13006/tcp # Cast

# Allow IPC ports (internal only)
sudo ufw allow from 172.20.0.0/16 to any port 14005
sudo ufw allow from 172.20.0.0/16 to any port 14006
```

## Performance Tuning

### Database Optimization

Configure MariaDB performance:

```yaml
services:
  db:
    environment:
      MYSQL_INNODB_BUFFER_POOL_SIZE: 1G
      MYSQL_INNODB_LOG_FILE_SIZE: 256M
      MYSQL_MAX_CONNECTIONS: 100
    command:
      - --innodb-buffer-pool-size=1G
      - --innodb-log-file-size=256M
      - --max-connections=100
```

### Server Resources

Allocate resources to services:

```yaml
services:
  main-server:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

  cast-server:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
```

### Docker Daemon Tuning

Optimize Docker performance:

```json
// /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10
}
```

## Security Configuration

### Database Security

```yaml
services:
  db:
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_USER: microvolts
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    command:
      - --skip-name-resolve
      - --bind-address=0.0.0.0
```

### Network Security

```yaml
services:
  db:
    networks:
      - internal
  auth-server:
    networks:
      - internal
      - external
  main-server:
    networks:
      - internal
      - external
  cast-server:
    networks:
      - internal
      - external

networks:
  internal:
    internal: true
  external:
    driver: bridge
```

### SSL/TLS Configuration

For production deployments:

```yaml
services:
  db:
    volumes:
      - ./ssl:/etc/mysql/ssl
    environment:
      MYSQL_SSL_CA: /etc/mysql/ssl/ca.pem
      MYSQL_SSL_CERT: /etc/mysql/ssl/server-cert.pem
      MYSQL_SSL_KEY: /etc/mysql/ssl/server-key.pem
    command:
      - --ssl-ca=/etc/mysql/ssl/ca.pem
      - --ssl-cert=/etc/mysql/ssl/server-cert.pem
      - --ssl-key=/etc/mysql/ssl/server-key.pem
```

## Monitoring Configuration

### Health Checks

```yaml
services:
  db:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 30s

  auth-server:
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "13000"]
      timeout: 10s
      retries: 3
      interval: 30s
```

### Logging Configuration

```yaml
services:
  auth-server:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    command: ["/app/Output/AuthServer.elf", "--log-level=info"]
```

## Backup Configuration

### Database Backup

```yaml
services:
  backup:
    image: mariadb:10.11
    volumes:
      - db_data:/var/lib/mysql:ro
      - ./backups:/backups
    command: >
      bash -c "
      mysqldump -h db -u root -p${MYSQL_ROOT_PASSWORD} microvolts-db > /backups/backup-$(date +%Y%m%d-%H%M%S).sql
      "
    depends_on:
      - db
```

### Automated Backups

Create a backup script:

```bash
#!/bin/bash
# backup.sh
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

docker-compose exec db mysqldump -u root -p$MYSQL_ROOT_PASSWORD microvolts-db > "$BACKUP_DIR/backup_$DATE.sql"

# Keep only last 7 backups
cd "$BACKUP_DIR"
ls -t backup_*.sql | tail -n +8 | xargs -r rm
```

## Troubleshooting Configuration

### Configuration Validation

```bash
# Check configuration syntax
docker-compose config

# Validate config.ini
python3 -c "
import configparser
config = configparser.ConfigParser()
config.read('Setup/config.ini')
print('Configuration loaded successfully')
for section in config.sections():
    print(f'Section: {section}')
    for key, value in config.items(section):
        print(f'  {key} = {value}')
"
```

### Environment Variable Debugging

```bash
# Check all environment variables
docker-compose exec auth-server env | grep -E "(MY_DB_PASSWORD|DB_)" | sort

# Test database connection
docker-compose exec auth-server mysql -h db -u root -p$MY_DB_PASSWORD -e "SELECT 1;"
```

### Network Debugging

```bash
# Check network connectivity
docker-compose exec auth-server ping -c 3 db

# Inspect networks
docker network ls
docker network inspect microvolts-emulator_microvolts-network

# Check port bindings
docker-compose ps
netstat -tulpn | grep -E "(3305|13000|13005|13006)"
```

## Configuration Examples

### Development Setup

```yaml
# docker-compose.override.yml
version: '3.8'

services:
  db:
    environment:
      MYSQL_ROOT_PASSWORD: dev_password
    ports:
      - "3305:3306"
    volumes:
      - ./dev-data:/var/lib/mysql

  auth-server:
    environment:
      - MYSQL_ROOT_PASSWORD=dev_password
    ports:
      - "13000:13000"
```

### Production Setup

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  db:
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - db_data:/var/lib/mysql
      - ./ssl:/etc/mysql/ssl
    command:
      - --ssl-ca=/etc/mysql/ssl/ca.pem
      - --ssl-cert=/etc/mysql/ssl/server-cert.pem
      - --ssl-key=/etc/mysql/ssl/server-key.pem
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

secrets:
  db_password:
    file: ./secrets/db_password.txt
```