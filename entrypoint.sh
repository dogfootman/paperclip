#!/bin/sh
# Paperclip auto-config entrypoint
# Generates config.json and master.key from env vars on every startup

CONFIG_DIR=/paperclip/instances/default

mkdir -p "$CONFIG_DIR/secrets"
mkdir -p "$CONFIG_DIR/logs"
mkdir -p "$CONFIG_DIR/data/storage"

# Write master.key from env var (if set)
if [ -n "$PAPERCLIP_SECRETS_MASTER_KEY" ]; then
  printf '%s' "$PAPERCLIP_SECRETS_MASTER_KEY" > "$CONFIG_DIR/secrets/master.key"
fi

# Generate config.json from env vars
cat > "$CONFIG_DIR/config.json" << CONFIGEOF
{
  "$meta": { "version": 1, "updatedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)", "source": "onboard" },
  "database": {
    "mode": "postgres",
    "connectionString": "${DATABASE_URL}",
    "embeddedPostgresDataDir": "/paperclip/instances/default/db",
    "embeddedPostgresPort": 54329,
    "backup": { "enabled": false, "intervalMinutes": 60, "retentionDays": 30, "dir": "/paperclip/instances/default/data/backups" }
  },
  "logging": { "mode": "file", "logDir": "/paperclip/instances/default/logs" },
  "server": {
    "deploymentMode": "authenticated",
    "exposure": "public",
    "host": "0.0.0.0",
    "port": 3100,
    "allowedHostnames": [],
    "serveUi": true
  },
  "auth": {
    "baseUrlMode": "explicit",
    "publicBaseUrl": "${PAPERCLIP_PUBLIC_URL}",
    "disableSignUp": false
  },
  "storage": {
    "provider": "local_disk",
    "localDisk": { "baseDir": "/paperclip/instances/default/data/storage" },
    "s3": { "bucket": "paperclip", "region": "us-east-1", "prefix": "", "forcePathStyle": false }
  },
  "secrets": {
    "provider": "local_encrypted",
    "strictMode": false,
    "localEncrypted": { "keyFilePath": "/paperclip/instances/default/secrets/master.key" }
  }
}
CONFIGEOF

echo "[entrypoint] config.json generated at $CONFIG_DIR/config.json"
exec "$@"
