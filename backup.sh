#!/bin/bash

# === Instellingen ===
BACKUP_DIR="/mnt/backup"
DATE=$(date +%F)
LOG_FILE="$BACKUP_DIR/backup-$DATE.log"
RETENTION_DAYS=30

# Mappen om te back-uppen
SOURCE_DIRS="/etc /var/www /home /root /usr/local/bin"

# Begin log
echo "Backup gestart op $(date)" > "$LOG_FILE"

# Maak submap voor deze datum
DEST="$BACKUP_DIR/daily-$DATE"
mkdir -p "$DEST"

# Uitvoeren van rsync
for DIR in $SOURCE_DIRS; do
    echo "Backuppen van $DIR..." | tee -a "$LOG_FILE"
    rsync -avh --delete "$DIR" "$DEST" >> "$LOG_FILE" 2>&1
done

# Oude backups opruimen
echo "Oude backups (ouder dan $RETENTION_DAYS dagen) worden verwijderd..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR" -maxdepth 1 -type d -name "daily-*" -mtime +$RETENTION_DAYS -exec rm -rf {} \; >> "$LOG_FILE" 2>&1

# Log afsluiten
echo "Backup voltooid op $(date)" | tee -a "$LOG_FILE"
