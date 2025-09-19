# Microvolts Emulator Docker Setup

This Docker setup allows you to easily install, configure, build, and run the Microvolts Emulator servers on Linux.

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available
- Linux environment (Ubuntu/Debian recommended)

## Quick Start

1. **Clone the repository** (if not already done):
   ```bash
   git clone https://github.com/SoWeBegin/MicrovoltsEmulator .
   ```

2. **Configure database settings**:
   ```bash
   ./setup.sh --db-password-env MY_DB_PASSWORD
   # Or with custom settings:
   ./setup.sh --db-host 192.168.1.100 --db-port 3306 --db-name mydb --db-user admin --db-password-env MY_DB_PASSWORD
   ```

3. **Set the database password environment variable**:
   ```bash
   export MY_DB_PASSWORD=your_secure_password_here
   ```

4. **Build and start the services**:
   ```bash
   docker-compose up --build -d
   ```

5. **Check that services are running**:
   ```bash
   docker-compose ps
   ```

## Services

- **db**: MariaDB database (port configurable via setup)
- **auth-server**: Authentication server (port 13000)
- **main-server**: Main game server (ports 13005, 14005)
- **cast-server**: Gameplay server (ports 13006, 14006)

## Setup Script

The `setup.sh` script configures database connection details and generates a `docker-compose.override.yml` file with the appropriate environment variables.

Usage:
```bash
./setup.sh [options]
```

This script:
- Updates `Setup/config.ini` with your database settings
- Creates `docker-compose.override.yml` with environment variable configurations
- Provides instructions for setting the password environment variable

Run `./setup.sh --help` for all available options.

## Configuration

### Database Configuration

Use the setup script to configure database settings:

```bash
./setup.sh --db-password-env MY_DB_PASSWORD --db-host 192.168.1.100 --db-port 3306
```

Available options:
- `--db-host`: Database server IP address
- `--db-port`: Database server port
- `--db-name`: Database name
- `--db-user`: Database username
- `--db-password-env`: Name of environment variable containing the password

After configuration, set the password environment variable:
```bash
export MY_DB_PASSWORD=your_actual_password
```

### Edit Configuration

Use the provided script to edit the configuration:

```bash
./edit_config.sh
```

This will open the `Setup/config.ini` file in nano. After editing, the servers will be automatically restarted.

### Manual Configuration

Edit `Setup/config.ini` directly. The file is mounted as a volume, so changes are reflected immediately.

Key settings:
- Database connection (uses the configured password environment variable)
- Server IPs and ports
- Client version

## Management Commands

### Restart Specific Servers

```bash
./restart_servers.sh auth    # Restart Auth Server
./restart_servers.sh main    # Restart Main Server
./restart_servers.sh cast    # Restart Cast Server
./restart_servers.sh db      # Restart Database
./restart_servers.sh all     # Restart all servers
```

### View Logs

```bash
docker-compose logs -f [service_name]
# Examples:
docker-compose logs -f auth-server
docker-compose logs -f db
```

### Stop Services

```bash
docker-compose down
```

### Rebuild After Code Changes

If you modify the source code:

```bash
docker-compose down
docker-compose up --build -d
```

## Database

The database is automatically initialized with the `microvolts-db.sql` file on first run.

- Database name: Configurable via setup script (default: `microvolts-db`)
- User: Configurable via setup script (default: `root`)
- Root password: From the configured password environment variable

## Ports

- 3305: MariaDB
- 13000: Auth Server
- 13005: Main Server (game)
- 13006: Cast Server (gameplay)
- 14005: Main Server IPC
- 14006: Cast Server IPC

## Troubleshooting

### Build Issues

If the build fails, try:
```bash
docker system prune -a
docker-compose up --build --no-cache
```

### Database Connection Issues

1. Ensure the password environment variable is set:
   ```bash
   echo $MY_DB_PASSWORD
   ```
2. Check that the setup script configured the correct environment variable name
3. Verify the docker-compose.override.yml was created correctly
4. Check database logs: `docker-compose logs db`