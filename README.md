# Microvolts Emulator - Docker Setup

A complete Docker-based setup for running the Microvolts Emulator servers on Linux. This setup includes authentication, main game, and gameplay servers with automatic database initialization.

## 🚀 Quick Start

Get the Microvolts Emulator running in minutes:

```bash
git clone https://github.com/SoWeBegin/MicrovoltsEmulator.git
cd MicrovoltsEmulator

./setup.sh --db-password-env MY_DB_PASSWORD

export MY_DB_PASSWORD=your_secure_password_here

docker-compose up --build -d

docker-compose ps
```

That's it! Your Microvolts Emulator is now running with:
- ✅ MariaDB database (port 3305)
- ✅ Authentication server (port 13000)
- ✅ Main game server (ports 13005, 14005)
- ✅ Gameplay server (ports 13006, 14006)

## 📋 Requirements

- **Docker** 20.10+ and **Docker Compose** 2.0+
- **Linux** environment (Ubuntu/Debian recommended)
- **4GB+ RAM** available
- **Git** for repository access

## 🆘 Support & Community

- 📖 **[Full Documentation](docs/)** - Complete guides and references
- 🐛 [Discord Server](https://discord.gg/y6yjRKmE6Y) - Bug reports and feature requests
---