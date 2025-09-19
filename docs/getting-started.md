# Getting Started

Welcome to the Microvolts Emulator Docker setup! This guide will get you up and running in just a few minutes.

## Prerequisites

Before you begin, ensure you have:

- **Docker** (version 20.10 or later)
- **Docker Compose** (version 2.0 or later)
- **Linux environment** (Ubuntu/Debian recommended)
- **Git** for cloning repositories
- **4GB RAM** available

### Checking Prerequisites

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version

# Check available memory
free -h

# Check if Git is installed
git --version
```

## Quick Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/SoWeBegin/MicrovoltsEmulator.git
cd MicrovoltsEmulator
```

### Step 2: Configure Database

Run the setup script to configure your database connection:

```bash
# Basic setup (recommended for most users)
./setup.sh --db-password-env MY_DB_PASSWORD

# Advanced setup with custom database location
./setup.sh \
  --db-host your-db-server.com \
  --db-port 3306 \
  --db-name microvolts \
  --db-user gameuser \
  --db-password-env MY_DB_PASSWORD
```

### Step 3: Set Database Password

Set your database password as an environment variable:

```bash
export MY_DB_PASSWORD=your_secure_password_here
```

> **Important**: Choose a strong password and keep it secure. This password will be used for the MariaDB root user.

### Step 4: Launch Services

Start all services with Docker Compose:

```bash
docker-compose up --build -d
```

### Step 5: Verify Installation

Check that all services are running:

```bash
docker-compose ps
```

You should see output similar to:
```
     Name                   Command               State                    Ports
-------------------------------------------------------------------------------------
microvolts-auth    /app/Output/AuthServer.elf     Up      0.0.0.0:13000->13000/tcp
microvolts-cast    /app/Output/CastServer.elf     Up      0.0.0.0:13006->13006/tcp
microvolts-db      docker-entrypoint.sh mariadbd  Up      0.0.0.0:3305->3306/tcp
microvolts-main    /app/Output/MainServer.elf     Up      0.0.0.0:13005->13005/tcp
```

## First Run Experience

### Accessing the Services

Once running, your services will be available on these ports:

- **Database**: `localhost:3305`
- **Auth Server**: `localhost:13000`
- **Main Server**: `localhost:13005`
- **Cast Server**: `localhost:13006`

### Viewing Logs

Monitor your services with:

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f auth-server
docker-compose logs -f db
```

### Connecting a Game Client

To connect your Microvolts game client:

1. Configure your client to connect to your server's IP address
2. Use the default ports (13000 for auth, 13005 for main, 13006 for cast)
3. Ensure your firewall allows connections to these ports

## Post-Installation Tasks

### 1. Verify Database Setup

Check that the database was properly initialized:

```bash
docker-compose exec db mysql -u root -p microvolts-db -e "SHOW TABLES;"
```

### 2. Test Server Connectivity

You can test basic connectivity:

```bash
# Test database connection
docker-compose exec db mysql -u root -p microvolts-db -e "SELECT 1;"

# Check server processes
docker-compose exec auth-server ps aux
```

### 3. Configure Your Client

Update your game client configuration to point to your server:

```ini
[Server]
AuthServer=your-server-ip:13000
MainServer=your-server-ip:13005
CastServer=your-server-ip:13006
```

## Troubleshooting First Run

### Services Won't Start

If services fail to start:

```bash
# Check for errors
docker-compose logs

# Restart services
docker-compose restart

# Rebuild if needed
docker-compose up --build --no-cache
```

### Database Connection Issues

If you can't connect to the database:

```bash
# Check database status
docker-compose ps db

# View database logs
docker-compose logs db

# Verify password is set
echo $MY_DB_PASSWORD
```

### Port Conflicts

If ports are already in use:

```bash
# Check what's using the ports
netstat -tulpn | grep :3305
netstat -tulpn | grep :13000

# Edit docker-compose.yml to use different ports
nano docker-compose.yml
```

## Quick Commands Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View status
docker-compose ps

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart auth-server

# Edit configuration
./edit_config.sh

# Restart servers
./restart_servers.sh all