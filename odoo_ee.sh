#!/bin/bash

#### upgrade odoo community to enterprise edition ####
# Odoo 13: https://www.soladrive.com/downloads/enterprise-13.0.tar.gz
# Odoo 14: https://www.soladrive.com/downloads/enterprise-14.0.tar.gz
cd /usr/src
systemctl stop odoo

mkdir /odoo/enterprise
mkdir /odoo/enterprise/addons
wget https://www.soladrive.com/downloads/enterprise-14.0.tar.gz
tar -zxvf enterprise-14.0.tar.gz
cp -rf odoo-14.0*/odoo/addons/* /odoo/enterprise/addons
rm enterprise-14.0.tar.gz
# vim /etc/odoo-server.conf
#    addons_path = /odoo/enterprise/addons,/odoo/odoo-server/addons

systemctl start odoo
