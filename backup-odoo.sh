#!/bin/bash

# Setting Up Automatic Backup for Odoo Instance

# vars
BACKUP_DIR=~/odoo_backups
ODOO_DATABASE=odoodb1
ADMIN_PASSWORD=superadmin_passwd

# create a backup directory
mkdir -p ${BACKUP_DIR}

# create a backup
curl -X POST \
    -F "master_pwd=${ADMIN_PASSWORD}" \
    -F "name=${ODOO_DATABASE}" \
    -F "backup_format=zip"  \
    -o ${BACKUP_DIR}/${ODOO_DATABASE}.$(date +%F-%H-%M).zip  \
    http://localhost:8069/web/database/backup

# delete old backups if older than 30 days
find ${BACKUP_DIR} -type f -mtime +30 -name "${ODOO_DATABASE}.*.zip" -delete

