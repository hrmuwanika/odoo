#!/bin/bash

################################################################################
# Script for installing Odoo on Ubuntu 18.04 LTS (could be used for other version too)
# Author: Henry Robert Muwanika
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 18.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano install_odoo_ubuntu.sh
# Place this content in it and then make the file executable:
# sudo chmod +x install_odoo_ubuntu.sh
# Execute the script to install Odoo:
# ./install_odoo_ubuntu.sh
################################################################################

OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
# Choose the Odoo version which you want to install. For example: 14.0, 13.0, 12.0 or 11.0. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 14.0
OE_VERSION="14.0"
# Set this to True if you want to install the Odoo enterprise version!
IS_ENTERPRISE="False"
# Set this to True if you want to install Nginx!
INSTALL_NGINX="True"
# Set the superadmin password - if GENERATE_RANDOM_PASSWORD is set to "True" we will automatically generate a random password, otherwise we use this one
OE_SUPERADMIN="admin"
# Set to "True" to generate a random password, "False" to use the variable in OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="True"
OE_CONFIG="${OE_USER}-server"
# Set the website name
WEBSITE_NAME="_"
# Set the default Odoo longpolling port (you still have to use -c /etc/odoo-server.conf for example to use this.)
LONGPOLLING_PORT="8072"
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Provide Email to register ssl certificate
ADMIN_EMAIL="odoo@example.com"
##
#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============== Update Server ======================="
# universe package is for Ubuntu 18.x
sudo add-apt-repository universe

# libpng12-0 dependency for wkhtmltopdf
sudo add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ xenial main"

sudo apt update 
sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# UFW Firewall
#--------------------------------------------------
sudo apt install -y ufw 
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6010/tcp
sudo ufw allow 8069/tcp
sudo ufw allow 8072/tcp

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n================ Install PostgreSQL Server =========================="
sudo apt install postgresql -y
sudo systemctl enable postgresql

echo -e "\n=============== Creating the ODOO PostgreSQL User ========================="
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n=================== Installing Python 3 + pip3 ============================"
sudo apt install git build-essential python3 python3-pip python3-dev python3-pillow python3-lxml python3-dateutil python3-venv python3-wheel \
wget python3-setuptools libfreetype6-dev libpq-dev libxslt-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev libxslt1-dev node-less gdebi \
zlib1g-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev fail2ban libssl-dev \
libjpeg-dev libblas-dev libatlas-base-dev libffi-dev libatlas-base-dev libmysqlclient-dev -y

sudo -H pip3 install --upgrade pip
pip3 install Babel decorator docutils ebaysdk feedparser gevent greenlet html2text Jinja2 lxml Mako MarkupSafe mock num2words ofxparse \
passlib Pillow psutil psycogreen psycopg2 pydot pyparsing PyPDF2 pyserial python-dateutil python-openid pytz pyusb PyYAML qrcode reportlab \
requests six suds-jurko vatnumber vobject Werkzeug XlsxWriter xlwt xlrd polib

echo -e "\n================== Install python packages/requirements ============================"
wget https://raw.githubusercontent.com/odoo/odoo/${OE_VERSION}/requirements.txt
sudo -H pip3 install --upgrade pip
sudo pip3 install -r requirements.txt

echo -e "\n=========== Installing nodeJS NPM and rtlcss for LTR support =================="
sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install nodejs npm -y
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
###  WKHTMLTOPDF download links
## === Ubuntu Bionic x64  === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/13.0/setup/install.html#debian-ubuntu

sudo apt install software-properties-common -y
sudo apt install xfonts-75dpi -y
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb
sudo apt install ./wkhtmltox_0.12.6-1.bionic_amd64.deb -y
sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin

echo -e "\n============== Create ODOO system user ========================"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n=========== Create Log directory ================"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n========== Installing ODOO Server ==============="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n============ Create symlink for node ==============="
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "\n============== WARNING ====================="
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "\n============================================="
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n========= Added Enterprise code under $OE_HOME/enterprise/addons ========="
    echo -e "\n============= Installing Enterprise specific libraries ============"
    sudo -H pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n========= Create custom module directory ============"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n======= Setting permissions on home folder =========="
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "\n========== Create server config file ============="

sudo touch /etc/${OE_CONFIG}.conf
echo -e "\n============= Creating server config file ==========="
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "\n========= Generating random admin password ==========="
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
if [ $OE_VERSION > "11.0" ];then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"

if [ $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

echo -e "=============== Create startup file ========================="
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (Systemd)
#--------------------------------------------------

echo -e "\n========== Create Odoo systemd file ==============="
cat <<EOF > /lib/systemd/system/odoo.service

[Unit]
Description=Odoo Open Source ERP and CRM
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
PermissionsStartOnly=true
SyslogIdentifier=odoo-server
User=$OE_USER
Group=$OE_USER
ExecStart=$OE_HOME_EXT/odoo-bin --config /etc/${OE_CONFIG}.conf  --logfile /var/log/${OE_USER}/${OE_CONFIG}.log
KillMode=mixed
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n======== Odoo startup File ============="
sudo systemctl daemon-reload
sudo systemctl enable odoo.service
sudo systemctl start odoo.service

# echo -e "\n======== Convert odoo CE to EE ============="
# wget https://raw.githubusercontent.com/hrmuwanika/odoo/master/odoo_ee.sh
# chmod +x odoo_ee.sh
# ./odoo_ee.sh

echo -e "\n======== Adding some custom modules ============="
git clone https://github.com/hrmuwanika/odoo-custom-addons.git
cd odoo-custom-addons
cp -rf * /odoo/custom/addons

#--------------------------------------------------
# Install Nginx if needed
#--------------------------------------------------
echo -e "\n======== Installing nginx ============="
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n---- Installing and setting up Nginx ----"
  sudo apt install -y nginx
  sudo systemctl enable nginx
  
cat <<EOF > /etc/nginx/sites-available/odoo

# http to https redirection
server {
    listen 80;
    server_name $WEBSITE_NAME;
   
    # Proxy settings
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
   
    # Add Headers for odoo proxy mode
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    proxy_set_header X-Client-IP \$remote_addr;
    proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;
   
    # log
    access_log /var/log/nginx/$OE_USER-access.log;
    error_log /var/log/nginx/$OE_USER-error.log;
    
    # Redirect longpoll requests to odoo longpolling port
      location /longpolling {
                 proxy_pass 127.0.0.1:$LONGPOLLING_PORT;
    }
    
    # Redirect requests to odoo backend server
     location / {
                proxy_redirect off;
                proxy_pass 127.0.0.1:$OE_PORT;
    }
   
    # cache some static data in memory for 60mins
    location ~* /[0-9a-zA-Z_]*/static/ {
                proxy_cache_valid 200 302 60m;
                proxy_cache_valid 404      1m;
                proxy_buffering on;
                expires 864000;
                proxy_pass 127.0.0.1:$OE_PORT;
    }
   
    # common gzip
    gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
    gzip on;
    }

EOF

  sudo mv ~/odoo /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
  sudo rm /etc/nginx/sites-enabled/default
  
  sudo systemctl reload nginx
  sudo su root -c "printf 'proxy_mode = True\n' >> /etc/${OE_CONFIG}.conf"
  echo "Done! The Nginx server is up and running. Configuration can be found at /etc/nginx/sites-available/odoo"
else
  echo "\n===== Nginx isn't installed due to choice of the user! ========"
fi

#--------------------------------------------------
# Enable ssl with certbot
#--------------------------------------------------

if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "odoo@example.com" ]  && [ $WEBSITE_NAME != "_" ];then
  sudo snap install core 
  sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  sudo certbot --nginx --agree-tos --redirect --uir --hsts --staple-ocsp --must-staple --noninteractive -d $WEBSITE_NAME --email $ADMIN_EMAIL
  
  sudo systemctl reload nginx
  echo "\n============ SSL/HTTPS is enabled! ========================"
else
  echo "\n==== SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration! ======"
fi

echo -e "\n================== Starting Odoo Service ============================="
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "\n========================================================================="
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Password superadmin (database): $OE_SUPERADMIN"
echo "Start Odoo service: sudo systemctl start $OE_CONFIG"
echo "Stop Odoo service: sudo systemctl stop $OE_CONFIG"
echo "Restart Odoo service: sudo systemctl restart $OE_CONFIG"
if [ $INSTALL_NGINX = "True" ]; then
  echo "Nginx configuration file: /etc/nginx/sites-available/odoo"
fi
echo -e "\n========================================================================="

