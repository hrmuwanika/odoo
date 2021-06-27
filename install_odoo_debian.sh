#!/bin/bash

################################################################################
# Script for installing Odoo on Debian 10.0 (could be used for other version too)
# Authors: Henry Robert Muwanika
#-------------------------------------------------------------------------------
# This script will install Odoo on your Debian 10.0 server. It can install multiple Odoo instances
# in one Debian because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo_install_debian.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo_install_debian.sh
# Execute the script to install Odoo:
# ./odoo_install_debian.sh
################################################################################

OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"
# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
# Choose the Odoo version which you want to install. For example: 14.0, 13.0 or 12.0. When using 'master' the master version will be installed.
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
WEBSITE_NAME="example.com"
# Set the default Odoo longpolling port (you still have to use -c /etc/odoo-server.conf for example to use this.)
LONGPOLLING_PORT="8072"
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Provide Email to register ssl certificate
ADMIN_EMAIL="odoo@example.com"
##

###
#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#Port 22/Port 578/' /etc/ssh/sshd_config
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

#--------------------------------------------------
# UFW Firewall
#--------------------------------------------------
sudo apt install -y ufw 
sudo ufw allow 578/tcp
sudo ufw allow 80,443,6010,5432,8069,8072/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6010/tcp
sudo ufw allow 5432//tcp
sudo ufw allow 8069/tcp
sudo ufw allow 8072/tcp
sudo ufw enable -y

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

sudo apt install -y vim
#### disable vim visual mode in debian Buster ####
sudo echo "set mouse-=a" >> ~/.vimrc

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
sudo apt -y install gnupg2
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install -y postgresql-12 postgresql-client-12
sudo systemctl start postgresql && sudo systemctl enable postgresql

echo -e "\n=========== Creating the ODOO PostgreSQL User ================="
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n=================== Installing Python 3 + pip3 ============================"
sudo apt install git build-essential python3 python3-pip python3-dev python3-pil python3-lxml python3-dateutil python3-venv python3-wheel \
wget python3-setuptools libfreetype6-dev libpq-dev libxslt-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev libxslt1-dev node-less gdebi \
zlib1g-dev libtiff5-dev libjpeg62-turbo-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev fail2ban libssl-dev \
libjpeg-dev libblas-dev libatlas-base-dev libffi-dev libatlas-base-dev default-libmysqlclient-dev software-properties-common xfonts-75dpi -y

echo -e "\n================== Install python packages/requirements ============================"
wget https://raw.githubusercontent.com/odoo/odoo/${OE_VERSION}/requirements.txt
sudo -H pip3 install --upgrade pip
sudo pip3 install setuptools wheel
sudo pip3 install -r requirements.txt

echo -e "\n=========== Installing nodeJS NPM and rtlcss for LTR support =================="
sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install nodejs -y
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less-plugin-clean-css
sudo npm install -g rtlcss

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for Odoo 14 ----"
###  WKHTMLTOPDF download links
## === Debian Buster x64 === (for other distributions please replace this link,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/14.0/setup/install.html#debian-ubuntu

wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb
sudo apt install ./wkhtmltox_0.12.6-1.buster_amd64.deb -y
sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

echo -e "\n======== Create ODOO system user =========="
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n=========== Create Log directory ====================="
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install Odoo from source
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n========== Create symlink for node ===================="
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "\n====================== WARNING ============================="
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "\n==========================================================="
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n======== Added Enterprise code under $OE_HOME/enterprise/addons ==========="
    echo -e "\n========== Installing Enterprise specific libraries ==============="
    sudo pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n======== Create custom module directory ================"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n======= Setting permissions on home folder ============="
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "\n============== Create server config file ================="

sudo touch /etc/${OE_CONFIG}.conf
echo -e "\n=========== Creating server config file =================="
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generating random admin password"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
if [ $OE_VERSION >= "12.0" ]; then
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

#--------------------------------------------------
# Adding ODOO as a deamon (Systemd)
#--------------------------------------------------

echo -e "\n================= Create Odoo systemd file ======================="
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

sudo chmod 755 /lib/systemd/system/odoo.service
sudo chown root: /lib/systemd/system/odoo.service

echo -e "\n========= Odoo startup File ===================="
sudo systemctl daemon-reload
sudo systemctl enable odoo.service
sudo systemctl start odoo.service

# echo -e "\n======== Adding Enterprise or custom modules ============="
if [ $IS_ENTERPRISE = "True" ]; then
  echo -e "\n======== Adding some enterprise modules ============="
  wget https://raw.githubusercontent.com/hrmuwanika/odoo/master/odoo_ee.sh
  sudo chmod +x odoo_ee.sh
  sudo ./odoo_ee.sh
else
  echo -e "\n======== Adding some custom modules ============="
  sudo mkdir /odoo/custom
  sudo mkdir /odoo/custom/addons
  git clone https://github.com/hrmuwanika/odoo-custom-addons.git
  sudo cp -rf odoo-custom-addons/* /odoo/custom/addons
fi

#--------------------------------------------------
# Install Nginx if needed
#--------------------------------------------------
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n======== Installing and setting up Nginx ========="
  sudo apt install -y nginx
  sudo systemctl enable nginx
  sudo systemctl start nginx
  
  cat <<EOF > /etc/nginx/sites-available/odoo

# odoo server
upstream odoo {
 server 127.0.0.1:8069;
}

upstream odoochat {
 server 127.0.0.1:8072;
}

server {
    listen 80;
    server_name $WEBSITE_NAME;

   # Specifies the maximum accepted body size of a client request,
   # as indicated by the request header Content-Length.
   client_max_body_size 300m;

   # log
   access_log /var/log/nginx/$OE_USER-access.log;
   error_log /var/log/nginx/$OE_USER-error.log;

   # add ssl specific settings
   keepalive_timeout    90;

   # increase proxy buffer to handle some Odoo web requests
   proxy_buffers 16 64k;
   proxy_buffer_size 128k;

   # general proxy settings
   proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

   # set headers
   proxy_set_header Host \$host;
   proxy_set_header X-Real-IP \$remote_addr;
   proxy_set_header X-Forward-For \$proxy_add_x_forwarded_for;
   proxy_set_header Host \$http_x_forwarded_host;

   # Let the Odoo web service know that we’re using HTTPS, otherwise
   # it will generate URL using http:// and not https://
   proxy_set_header X-Forwarded-Proto http;
   proxy_set_header X-Forwarded-Host \$host;
   proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
 
   # by default, do not forward anything
   proxy_redirect off;
   proxy_buffering off;

   # Redirect requests to odoo backend server
   location / {
     proxy_pass http://odoo;
   }

   # Redirect longpoll requests to odoo longpolling port
   location /longpolling {
       proxy_pass http://odoochat;
   }

   # cache some static data in memory for 90mins
   # under heavy load this should relieve stress on the Odoo web interface a bit.
   location ~* /web/static/ {
       proxy_cache_valid 200 90m;
       proxy_buffering    on;
       expires 864000;
       proxy_pass http://odoo;
  }

  # common gzip
    gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
    gzip on;
}
    
EOF

  sudo mv ~/odoo /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
  sudo rm /etc/nginx/sites-enabled/default
  sudo rm /etc/nginx/sites-available/default
  
  sudo systemctl reload nginx
  sudo su root -c "printf 'proxy_mode = True\n' >> /etc/${OE_CONFIG}.conf"
  echo "Done! The Nginx server is up and running. Configuration can be found at /etc/nginx/sites-available/odoo"
else
  echo "Nginx isn't installed due to choice of the user!"
fi

#--------------------------------------------------
# Enable ssl with certbot
#--------------------------------------------------

if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "odoo@example.com" ]  && [ $WEBSITE_NAME != "example.com" ];then
  sudo apt install snapd -y
  sudo apt-get remove certbot
  
  sudo snap install core
  sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  sudo certbot --nginx -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect
  sudo systemctl reload nginx
  
  echo "\n============ SSL/HTTPS is enabled! ========================"
else
  echo "\n==== SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration! ======"
fi

echo -e "\n=========== Starting Odoo Service =============="
sudo systemctl status $OE_USER
echo "\n===================================================================="
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
echo "\n====================================================================="

