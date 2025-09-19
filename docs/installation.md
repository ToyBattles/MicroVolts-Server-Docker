# Installation Guide

This guide provides detailed instructions for installing and setting up the Microvolts Emulator Docker environment.

## System Requirements

### Minimum Requirements

- **Operating System**: Linux (Ubuntu 20.04+, Debian 10+, CentOS 8+)
- **CPU**: 2-core processor (4+ cores recommended)
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 10GB free space
- **Network**: Stable internet connection

### Software Requirements

- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **Git**: Version 2.25 or later

## Installing Prerequisites

### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install Docker
sudo apt install -y docker.io docker-compose

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (optional, avoids using sudo)
sudo usermod -aG docker $USER

# Install Git
sudo apt install -y git

# Verify installations
docker --version
docker-compose --version
git --version
```

### CentOS/RHEL/Fedora

```bash
# Install Docker
sudo dnf install -y docker docker-compose

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Install Git
sudo dnf install -y git

# Verify installations
docker --version
docker-compose --version
git --version
```

### Arch Linux

```bash
# Install Docker and Docker Compose
sudo pacman -S docker docker-compose

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Install Git
sudo pacman -S git

# Verify installations
docker --version
docker-compose --version
git --version
```

## Docker Post-Installation Steps

### Configure Docker Daemon (Optional)

Create or edit `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

Restart Docker:
```bash
sudo systemctl restart docker
```

### Test Docker Installation

```bash
# Test Docker
docker run hello-world

# Test Docker Compose
docker-compose --version
```

## Downloading the Emulator

### Clone Repository

```bash
# Clone the repository
git clone https://github.com/SoWeBegin/MicrovoltsEmulator.git

# Navigate to directory
cd MicrovoltsEmulator

# Verify contents
ls -la
```

### Repository Structure

After cloning, you should see:

```
.
├── Dockerfile
├── docker-compose.yml
├── setup.sh
├── edit_config.sh
├── restart_servers.sh
├── Setup/
│   └── config.ini
├── microvolts-db.sql
├── docs/
└── [source code directories]
```

## Database Configuration

### Using the Setup Script

The easiest way to configure the database is using the provided setup script:

```bash
# Make scripts executable
chmod +x setup.sh edit_config.sh restart_servers.sh

# Run basic setup
./setup.sh --db-password-env MY_DB_PASSWORD

# Or run advanced setup
./setup.sh \
  --db-host localhost \
  --db-port 3305 \
  --db-name microvolts-db \
  --db-user root \
  --db-password-env MY_DB_PASSWORD
```

### Manual Configuration

If you prefer manual configuration:

1. Edit the configuration file:
   ```bash
   nano Setup/config.ini
   ```

2. Update the database section:
   ```ini
   [Database]
   LocalIp = 127.0.0.1
   Ip = 127.0.0.1
   Port = 3305
   DatabaseName = microvolts-db
   Username = root
   PasswordEnvironmentName = MY_DB_PASSWORD
   ```

3. Create Docker Compose override:
   ```bash
   cat > docker-compose.override.yml << EOF
   version: '3.8'

   services:
     db:
       environment:
         MYSQL_ROOT_PASSWORD: \${MY_DB_PASSWORD}
         MYSQL_DATABASE: microvolts-db
         MYSQL_USER: root
         MYSQL_PASSWORD: \${MY_DB_PASSWORD}
       ports:
         - "3305:3306"

     auth-server:
       environment:
         - MY_DB_PASSWORD

     main-server:
       environment:
         - MY_DB_PASSWORD

     cast-server:
       environment:
         - MY_DB_PASSWORD
   EOF
   ```

## Environment Setup

### Setting Database Password

```bash
# Set your database password
export MY_DB_PASSWORD=your_secure_password_here

# Make it permanent (optional)
echo 'export MY_DB_PASSWORD=your_secure_password_here' >> ~/.bashrc
source ~/.bashrc
```

### Verifying Environment

```bash
# Check if password is set
echo $MY_DB_PASSWORD

# Verify it's not empty
if [ -z "$MY_DB_PASSWORD" ]; then
    echo "Error: MY_DB_PASSWORD is not set"
    exit 1
fi
```

## Building and Running

### First Build

```bash
# Build and start all services
docker-compose up --build -d

# This will:
# 1. Download and build the emulator from source
# 2. Set up MariaDB with the provided configuration
# 3. Start all three server components
# 4. Initialize the database schema
```

### Build Process Details

The build process includes:

1. **Base Image Setup**: Ubuntu 22.04 with build tools
2. **Dependency Installation**: GCC 13, CMake, vcpkg
3. **Source Download**: Clone MicrovoltsEmulator from GitHub
4. **Compilation**: Build all server components
5. **Runtime Image**: Create optimized runtime container

### Expected Build Time

- **First build**: 15-30 minutes (downloads dependencies)
- **Subsequent builds**: 5-10 minutes
- **Network dependent**: Faster with better internet

## Verification

### Check Service Status

```bash
# View all services
docker-compose ps

# Expected output:
#     Name                   Command               State                    Ports
# -------------------------------------------------------------------------------------
# microvolts-auth    /app/Output/AuthServer.elf     Up      0.0.0.0:13000->13000/tcp
# microvolts-cast    /app/Output/CastServer.elf     Up      0.0.0.0:13006->13006/tcp
# microvolts-db      docker-entrypoint.sh mariadbd  Up      0.0.0.0:3305->3306/tcp
# microvolts-main    /app/Output/MainServer.elf     Up      0.0.0.0:13005->13005/tcp
```

### Verify Database

```bash
# Connect to database
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD microvolts-db -e "SHOW TABLES;"

# Check database size
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD -e "SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema = 'microvolts-db';"
```

### Test Server Connectivity

```bash
# Check if servers are listening
netstat -tulpn | grep :13000
netstat -tulpn | grep :13005
netstat -tulpn | grep :13006

# Test database connectivity from container
docker-compose exec auth-server nc -zv db 3306
```

## Post-Installation Configuration

### Firewall Configuration

Allow necessary ports through firewall:

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 3305/tcp
sudo ufw allow 13000/tcp
sudo ufw allow 13005/tcp
sudo ufw allow 13006/tcp

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=3305/tcp
sudo firewall-cmd --permanent --add-port=13000/tcp
sudo firewall-cmd --permanent --add-port=13005/tcp
sudo firewall-cmd --permanent --add-port=13006/tcp
sudo firewall-cmd --reload
```

### Systemd Service (Optional)

Create a systemd service for automatic startup:

```bash
# Create service file
sudo tee /etc/systemd/system/microvolts-emulator.service > /dev/null << EOF
[Unit]
Description=Microvolts Emulator Docker Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/MicrovoltsEmulator
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
ExecReload=/usr/bin/docker-compose restart

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable microvolts-emulator
sudo systemctl start microvolts-emulator
```

## Troubleshooting Installation

### Build Failures

```bash
# Clear Docker cache
docker system prune -f

# Rebuild without cache
docker-compose build --no-cache

# Check build logs
docker-compose build --progress plain
```

### Permission Issues

```bash
# Fix script permissions
chmod +x setup.sh edit_config.sh restart_servers.sh

# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker
```

### Memory Issues

If builds fail due to memory:

```bash
# Check available memory
free -h

# Increase Docker memory limit
# Edit /etc/docker/daemon.json and add:
# {
#   "memory": "4g",
#   "memory-swap": "8g"
# }
```

### Network Issues

```bash
# Check internet connectivity
ping google.com

# Configure Docker DNS
# Edit /etc/docker/daemon.json and add:
# {
#   "dns": ["8.8.8.8", "8.8.4.4"]
# }
```