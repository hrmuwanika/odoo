#!/bin/bash

# Setting Up Automatic Backup for Odoo Instance
# mkdir -p /opt/script && cd /opt/script
# wget https://raw.githubusercontent.com/hrmuwanika/odoo/master/backup_odoo.sh 
# sudo chmod +x backup_odoo.sh

# To backup every 4 hours
# sudo crontab -e
# 0 */4 * * * /opt/script/backup_odoo.sh  

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

