#!/bin/bash

#### upgrade odoo community to enterprise edition ####

# Odoo 11: https://www.soladrive.com/downloads/enterprise-11.0.tar.gz
# Odoo 12: https://www.soladrive.com/downloads/enterprise-12.0.tar.gz
# Odoo 13: https://www.soladrive.com/downloads/enterprise-13.0.tar.gz
# Odoo 14: https://www.soladrive.com/downloads/enterprise-14.0.tar.gz

 systemctl stop odoo

 mkdir /odoo/enterprise
 mkdir /odoo/enterprise/addons
 wget https://www.soladrive.com/downloads/enterprise-14.0.tar.gz
 tar -zxvf enterprise-14.0.tar.gz
 cp -rf 14.0/* /odoo/enterprise/addons

# vim /etc/odoo-server.conf
#    addons_path = /odoo/enterprise/addons,/odoo/odoo-server/addons

 systemctl start odoo
