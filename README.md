## Postgresql create database
-- Create the database
CREATE DATABASE techgearhub;

-- Create user with password
CREATE USER techhub WITH PASSWORD '!@#123Abc';

-- Grant all privileges on the database to the user
GRANT ALL PRIVILEGES ON DATABASE techgearhub TO techhub;

-- Connect to the new database
\c techgearhub

-- Grant privileges on the public schema (important for PostgreSQL 15+)
GRANT ALL ON SCHEMA public TO techhub;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO techhub;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO techhub;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO techhub;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO techhub;

-- Exit PostgreSQL
\q


## Push app to DockerHub
docker build -t niroth36/simpleeshop:latest .
docker push niroth36/simpleeshop:latest



# SimpleEshop - Docker Setup

A complete e-commerce application with Node.js, PostgreSQL, and Redis.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- No other setup required!

### Run the Application

1. **Download the files:**
   ```bash
   # Clone the repository
   git clone https://github.com/Niroth36/SimpleEshop.git
   cd SimpleEshop
   ```

2. **Start the application:**
   ```bash
   # Start all services (database, redis, web app)
   docker compose up -d
   ```

3. **Access the application:**
   - **Web App**: http://localhost:3000
   - **Database**: PostgreSQL on port 5432 (if needed)
   - **Redis**: Redis on port 6379 (if needed)

### 🔍 Check if Everything is Running

```bash
# Check container status
docker ps

# Check logs
docker compose logs app

# Test the application
curl http://localhost:3000
```

### 🛑 Stop the Application

```bash
# Stop all services
docker compose down

# Stop and remove data (complete cleanup)
docker compose down -v
```

## 🎯 Features

- ✅ **Complete PostgreSQL database** with sample products
- ✅ **Redis session storage**
- ✅ **User authentication** (register/login)
- ✅ **Shopping cart functionality**
- ✅ **Checkout process**
- ✅ **Automatic database initialization**

## 🐛 Troubleshooting

### Application won't start
```bash
# Check logs
docker compose logs

# Restart services
docker compose restart
```

### Database connection issues
```bash
# Check database is healthy
docker compose ps
docker compose logs postgres
```

### Port conflicts
If you get port conflicts, edit `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Change 3000 to 3001 for the app
  - "5433:5432"  # Change 5432 to 5433 for database
```

## 📊 Default Data

The application starts with sample products:
- CPUs (Intel, AMD)
- RAM modules
- Storage devices
- Graphics cards

You can register a new account and start shopping immediately!

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Web App   │◄──►│ PostgreSQL  │    │    Redis    │
│  (Node.js)  │    │ (Database)  │    │ (Sessions)  │
│  Port 3000  │    │  Port 5432  │    │  Port 6379  │
└─────────────┘    └─────────────┘    └─────────────┘
```

All services run in isolated Docker containers with persistent data storage.
