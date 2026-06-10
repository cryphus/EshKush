FROM postgres:latest
# Credentials are provided at runtime via environment variables or docker-compose env_file.
# Do NOT set POSTGRES_PASSWORD here — it would be visible in image layers.
COPY init.sql /docker-entrypoint-initdb.d/
