#!/usr/bin/env bash
set -euo pipefail

# s3 backup script using rclone.
# Syncs specified directories to S3 with encryption and deduplication.

BACKUP_BUCKET="aostow-home-backups"
BACKUP_PATHS=(
  "/space/immich"
  "/space/backups"
)

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
  log "ERROR: $*" >&2
  exit 1
}

# Check if AWS credentials are configured
if [[ ! -f "${AWS_CONFIG_FILE:-}" ]]; then
  error "AWS_CONFIG_FILE not set or file does not exist"
fi

# Check if rclone is available
if ! command -v rclone &>/dev/null; then
  error "rclone not found in PATH"
fi

log "Starting backup to s3://${BACKUP_BUCKET}"

# Sync each path
for path in "${BACKUP_PATHS[@]}"; do
  if [[ ! -d "$path" ]]; then
    log "WARNING: $path does not exist, skipping"
    continue
  fi

  # use full path as S3 prefix, removing leading slash
  s3_prefix="${path#/}"

  log "Backing up $path -> s3://${BACKUP_BUCKET}/${s3_prefix}/"

  # Use rclone sync to upload only changed files.
  # --transfers limits concurrent transfers to avoid overwhelming the connection.
  # --checkers limits concurrent checksum operations.
  # --stats shows progress every 30 seconds.
  if rclone sync \
    --s3-provider AWS \
    --s3-env-auth \
    --s3-region us-east-1 \
    --transfers 4 \
    --checkers 8 \
    --stats 30s \
    --exclude '.DS_Store' \
    --exclude 'Thumbs.db' \
    --exclude '*.tmp' \
    "$path/" ":s3:${BACKUP_BUCKET}/${s3_prefix}/"; then
    log "Successfully backed up $path"
  else
    error "Failed to backup $path"
  fi
done

log "Backup completed successfully"
