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
