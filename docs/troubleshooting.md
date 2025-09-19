# Troubleshooting Guide

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with the Microvolts Emulator Docker setup.

## Quick Diagnosis

### System Status Check

```bash
# Check all services
docker-compose ps

# Check system resources
free -h && df -h

# Check Docker status
docker system info

# Quick log check
docker-compose logs --tail=20
```

### Common Symptoms and Solutions

| Symptom | Possible Cause | Quick Fix |
|---------|---------------|-----------|
| Services won't start | Port conflict | `netstat -tulpn \| grep :13000` |
| Database connection failed | Wrong password | `echo $MY_DB_PASSWORD` |
| High CPU usage | Resource limits | `docker stats` |
| Out of disk space | Log accumulation | `docker system prune` |
| Slow performance | Memory issues | `free -h` |

## Service Startup Issues

### Services Fail to Start

**Symptoms:**
- `docker-compose ps` shows services as "Exit" or "Restarting"
- Error messages in logs

**Diagnosis:**
```bash
# Check service logs
docker-compose logs auth-server

# Check system resources
docker system df
free -h

# Validate configuration
docker-compose config
```

**Common Solutions:**

1. **Port Conflicts:**
   ```bash
   # Find conflicting processes
   netstat -tulpn | grep -E "(13000|13005|13006|3305)"

   # Change ports in docker-compose.yml
   nano docker-compose.yml
   docker-compose up -d
   ```

2. **Resource Constraints:**
   ```bash
   # Check available memory
   free -h

   # Increase Docker memory limit
   # Edit /etc/docker/daemon.json
   {
     "memory": "4g"
   }
   sudo systemctl restart docker
   ```

3. **Configuration Errors:**
   ```bash
   # Validate syntax
   docker-compose config

   # Check environment variables
   echo $MY_DB_PASSWORD

   # Verify config.ini
   cat Setup/config.ini
   ```

### Database Won't Start

**Symptoms:**
- Database service shows "Exit 1"
- Connection refused errors

**Diagnosis:**
```bash
# Check database logs
docker-compose logs db

# Check data directory permissions
ls -la db_data/

# Test database connectivity
docker-compose exec db mysqladmin ping
```

**Solutions:**

1. **Data Directory Issues:**
   ```bash
   # Fix permissions
   sudo chown -R 999:999 db_data/

   # Reset database
   docker-compose down -v
   docker-compose up -d db
   ```

2. **Password Issues:**
   ```bash
   # Verify password is set
   echo $MY_DB_PASSWORD

   # Reset password
   unset MY_DB_PASSWORD
   export MY_DB_PASSWORD=new_password
   docker-compose up -d
   ```

3. **Port Conflicts:**
   ```bash
   # Check if port 3305 is in use
   netstat -tulpn | grep :3305

   # Change port in docker-compose.yml
   nano docker-compose.yml
   ```

## Connection Issues

### Database Connection Failed

**Symptoms:**
- Services log "Can't connect to MySQL server"
- Authentication errors

**Diagnosis:**
```bash
# Test database connectivity
docker-compose exec auth-server mysql -h db -u root -p$MY_DB_PASSWORD -e "SELECT 1;"

# Check database service status
docker-compose ps db

# Verify network connectivity
docker-compose exec auth-server ping -c 3 db
```

**Solutions:**

1. **Network Issues:**
   ```bash
   # Check Docker network
   docker network ls
   docker network inspect microvolts-emulator_microvolts-network

   # Restart network
   docker-compose down
   docker-compose up -d
   ```

2. **Password Mismatch:**
   ```bash
   # Verify password
   echo $MY_DB_PASSWORD

   # Update password in config
   ./setup.sh --db-password-env MY_DB_PASSWORD
   ```

3. **Database Not Ready:**
   ```bash
   # Wait for database to initialize
   docker-compose logs db | tail -20

   # Check database health
   docker-compose exec db mysqladmin ping
   ```

### Client Connection Issues

**Symptoms:**
- Game client can't connect to server
- "Connection refused" errors

**Diagnosis:**
```bash
# Check service ports
netstat -tulpn | grep -E "(13000|13005|13006)"

# Test external connectivity
telnet localhost 13000

# Check firewall
sudo ufw status
```

**Solutions:**

1. **Firewall Blocking:**
   ```bash
   # Allow emulator ports
   sudo ufw allow 13000/tcp
   sudo ufw allow 13005/tcp
   sudo ufw allow 13006/tcp

   # Or disable firewall temporarily
   sudo ufw disable
   ```

2. **Port Binding Issues:**
   ```bash
   # Check Docker port mapping
   docker-compose ps

   # Verify configuration
   cat Setup/config.ini
   ```

3. **Network Configuration:**
   ```bash
   # Check if services are bound to correct interface
   docker-compose exec auth-server netstat -tulpn

   # Update IP in config
   ./edit_config.sh
   ```

## Performance Issues

### High CPU Usage

**Symptoms:**
- Services consuming excessive CPU
- Slow response times

**Diagnosis:**
```bash
# Monitor resource usage
docker stats

# Check system load
top

# Analyze service logs
docker-compose logs --tail=50 | grep -i error
```

**Solutions:**

1. **Resource Limits:**
   ```bash
   # Add resource limits to docker-compose.yml
   services:
     main-server:
       deploy:
         resources:
           limits:
             cpus: '2.0'
             memory: 2G
   ```

2. **Database Optimization:**
   ```bash
   # Optimize database tables
   docker-compose exec db mysql -u root -p$MY_DB_PASSWORD microvolts-db -e "OPTIMIZE TABLE players, items;"

   # Check slow queries
   docker-compose exec db mysql -u root -p$MY_DB_PASSWORD -e "SHOW PROCESSLIST;"
   ```

3. **Service Scaling:**
   ```bash
   # Scale services
   docker-compose up -d --scale main-server=2
   ```

### High Memory Usage

**Symptoms:**
- Services consuming excessive memory
- Out of memory errors

**Diagnosis:**
```bash
# Check memory usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Check system memory
free -h

# Check Docker memory limits
docker system info | grep -i memory
```

**Solutions:**

1. **Memory Limits:**
   ```yaml
   services:
     main-server:
       deploy:
         resources:
           limits:
             memory: 2G
           reservations:
             memory: 1G
   ```

2. **Database Tuning:**
   ```bash
   # Adjust MariaDB memory settings
   docker-compose exec db mysql -u root -p$MY_DB_PASSWORD -e "SET GLOBAL innodb_buffer_pool_size = 536870912;"
   ```

3. **Memory Cleanup:**
   ```bash
   # Clear Docker cache
   docker system prune -f

   # Restart services
   docker-compose restart
   ```

### Slow Database Queries

**Symptoms:**
- Slow response times
- Database timeouts

**Diagnosis:**
```bash
# Check running queries
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD -e "SHOW PROCESSLIST;"

# Analyze slow queries
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD -e "SHOW ENGINE INNODB STATUS\G" | grep -A 20 "TRANSACTIONS"

# Check table indexes
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD microvolts-db -e "SHOW INDEX FROM players;"
```

**Solutions:**

1. **Add Indexes:**
   ```sql
   -- Connect to database
   docker-compose exec db mysql -u root -p$MY_DB_PASSWORD microvolts-db

   -- Add performance indexes
   ALTER TABLE players ADD INDEX idx_name (name);
   ALTER TABLE items ADD INDEX idx_player_id (player_id);
   ```

2. **Query Optimization:**
   ```sql
   -- Analyze query performance
   EXPLAIN SELECT * FROM players WHERE name = 'testuser';

   -- Optimize table
   OPTIMIZE TABLE players;
   ```

3. **Database Configuration:**
   ```yaml
   services:
     db:
       command:
         - --innodb-buffer-pool-size=1G
         - --max-connections=100
         - --query-cache-size=256M
   ```

## Build Issues

### Docker Build Failures

**Symptoms:**
- Build process fails
- Dependency installation errors

**Diagnosis:**
```bash
# Check build logs
docker-compose build --progress plain

# Check available disk space
df -h

# Verify internet connectivity
ping google.com
```

**Solutions:**

1. **Clean Build:**
   ```bash
   # Clear build cache
   docker system prune -a

   # Rebuild without cache
   docker-compose build --no-cache
   ```

2. **Network Issues:**
   ```bash
   # Configure DNS
   sudo tee /etc/docker/daemon.json > /dev/null <<EOF
   {
     "dns": ["8.8.8.8", "8.8.4.4"]
   }
   EOF
   sudo systemctl restart docker
   ```

3. **Resource Issues:**
   ```bash
   # Increase Docker resources
   # Edit Docker Desktop settings or daemon.json
   {
     "memory": "4g",
     "cpus": 2
   }
   ```

### Compilation Errors

**Symptoms:**
- C++ compilation fails
- Missing dependencies

**Diagnosis:**
```bash
# Check compiler version
docker-compose exec builder gcc --version

# Check available libraries
docker-compose exec builder ldconfig -p | grep -i boost

# View compilation logs
docker-compose logs builder
```

**Solutions:**

1. **Update Base Image:**
   ```dockerfile
   FROM ubuntu:22.04
   ```

2. **Install Missing Dependencies:**
   ```bash
   # Update package lists
   docker-compose exec builder apt update

   # Install missing packages
   docker-compose exec builder apt install -y libssl-dev
   ```

3. **Clear Build Cache:**
   ```bash
   docker-compose down
   docker rmi $(docker images -q)
   docker-compose up --build
   ```

## Network Issues

### Service Communication Problems

**Symptoms:**
- Services can't communicate with each other
- IPC connection failures

**Diagnosis:**
```bash
# Check Docker network
docker network inspect microvolts-emulator_microvolts-network

# Test inter-service connectivity
docker-compose exec auth-server ping -c 3 main-server

# Check service discovery
docker-compose exec auth-server nslookup db
```

**Solutions:**

1. **Network Recreation:**
   ```bash
   # Recreate network
   docker-compose down
   docker network rm microvolts-emulator_microvolts-network
   docker-compose up -d
   ```

2. **DNS Issues:**
   ```bash
   # Check DNS resolution
   docker-compose exec auth-server cat /etc/resolv.conf

   # Update DNS settings
   sudo tee /etc/docker/daemon.json > /dev/null <<EOF
   {
     "dns": ["8.8.8.8"]
   }
   EOF
   ```

3. **Port Conflicts:**
   ```bash
   # Check IPC ports
   netstat -tulpn | grep -E "(14005|14006)"
   ```

### External Connectivity Issues

**Symptoms:**
- Can't connect from external machines
- Firewall blocking connections

**Diagnosis:**
```bash
# Check external IP
curl ifconfig.me

# Test external connectivity
telnet your-server-ip 13000

# Check routing
traceroute your-server-ip
```

**Solutions:**

1. **Port Forwarding:**
   ```bash
   # Router port forwarding
   # Forward external ports to server IP
   # 13000 → server-ip:13000
   # 13005 → server-ip:13005
   # 13006 → server-ip:13006
   ```

2. **Firewall Configuration:**
   ```bash
   # Allow ports in firewall
   sudo ufw allow from any to any port 13000 proto tcp
   sudo ufw allow from any to any port 13005 proto tcp
   sudo ufw allow from any to any port 13006 proto tcp
   ```

3. **Network Interface:**
   ```bash
   # Bind to all interfaces
   nano docker-compose.yml
   # Change "127.0.0.1:13000:13000" to "0.0.0.0:13000:13000"
   ```

## Data Issues

### Database Corruption

**Symptoms:**
- Database errors
- Table corruption messages

**Diagnosis:**
```bash
# Check database logs
docker-compose logs db

# Test table integrity
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD microvolts-db -e "CHECK TABLE players;"

# Check error logs
docker-compose exec db tail -50 /var/log/mysql/error.log
```

**Solutions:**

1. **Table Repair:**
   ```bash
   # Repair corrupted tables
   docker-compose exec db mysql -u root -p$MY_DB_PASSWORD microvolts-db -e "REPAIR TABLE players;"
   ```

2. **Database Recovery:**
   ```bash
   # Stop services
   docker-compose down

   # Remove corrupted data
   sudo rm -rf db_data/

   # Restore from backup
   docker-compose up -d db
   gunzip < backup.sql.gz | docker-compose exec -T db mysql -u root -p$MY_DB_PASSWORD microvolts-db
   ```

3. **Fresh Installation:**
   ```bash
   # Complete reset
   docker-compose down -v
   docker-compose up --build -d
   ```

### Configuration Errors

**Symptoms:**
- Services fail to start with config errors
- Invalid configuration messages

**Diagnosis:**
```bash
# Validate configuration
docker-compose config

# Check config.ini syntax
cat Setup/config.ini

# Test configuration parsing
python3 -c "
import configparser
config = configparser.ConfigParser()
config.read('Setup/config.ini')
print('Configuration valid')
"
```

**Solutions:**

1. **Fix Configuration:**
   ```bash
   # Edit configuration
   ./edit_config.sh

   # Or manual edit
   nano Setup/config.ini
   ```

2. **Reset to Defaults:**
   ```bash
   # Backup current config
   cp Setup/config.ini Setup/config.ini.backup

   # Reset configuration
   ./setup.sh --db-password-env MY_DB_PASSWORD
   ```

3. **Validate Changes:**
   ```bash
   # Test configuration
   docker-compose config
   docker-compose up -d --scale auth-server=0
   docker-compose up -d --scale auth-server=1
   ```

## Advanced Troubleshooting

### Debug Mode

```bash
# Enable debug logging
export DOCKER_DEBUG=1

# Run with verbose output
docker-compose up --verbose

# Debug specific service
docker-compose exec auth-server /bin/bash
```

### System Diagnostics

```bash
# System information
uname -a
lsb_release -a

# Docker information
docker version
docker info

# Hardware information
lscpu
lsmem
```

### Log Analysis

```bash
# Search for patterns
docker-compose logs | grep -i "error\|warn\|fail"

# Count occurrences
docker-compose logs | grep -c ERROR

# Time-based analysis
docker-compose logs --since "1 hour ago"

# Export for external analysis
docker-compose logs > full_logs.txt
```

### Performance Profiling

```bash
# Profile container performance
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"

# Database profiling
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD -e "SHOW ENGINE INNODB STATUS\G"

# Network profiling
docker-compose exec auth-server netstat -i
```

## Emergency Procedures

### Complete System Reset

```bash
# Emergency reset (WARNING: destroys all data)
docker-compose down -v
docker system prune -a
docker volume prune -f

# Fresh installation
git clone https://github.com/SoWeBegin/MicrovoltsEmulator.git
cd MicrovoltsEmulator
./setup.sh --db-password-env MY_DB_PASSWORD
export MY_DB_PASSWORD=new_password
docker-compose up --build -d
```

### Data Recovery

```bash
# Find latest backup
ls -la backups/

# Restore database
LATEST_BACKUP=$(ls -t backups/db_backup_*.sql.gz | head -1)
gunzip < "$LATEST_BACKUP" | docker-compose exec -T db mysql -u root -p$MY_DB_PASSWORD microvolts-db

# Restore configuration
tar -xzf backups/config_backup_*.tar.gz
```

## Prevention

### Regular Maintenance

```bash
# Weekly maintenance script
#!/bin/bash
echo "=== Weekly Maintenance ==="

# Check service status
docker-compose ps

# Monitor disk usage
df -h

# Clean old logs
docker-compose logs --since 7 days | wc -l

# Database optimization
docker-compose exec db mysql -u root -p$MY_DB_PASSWORD microvolts-db -e "OPTIMIZE TABLE players;"

echo "Maintenance completed"
```