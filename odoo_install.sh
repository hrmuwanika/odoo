#!/bin/bash

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
echo -e "\n---- Update Server ----"
sudo add-apt-repository universe
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# Create Odoo system user
#--------------------------------------------------
echo -e "\n---- Create Odoo system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'ODOO' --group odoo
sudo adduser odoo sudo

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql-9.6 -y
sudo systemctl start postgresql
sudo systemctl enable postgresql

#--------------------------------------------------
# Create odoo user for postgreSQL
#--------------------------------------------------
echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s odoo" 2> /dev/null || true

#-------------------------------------------------
# Install Wkhtmltopdf
#--------------------------------------------------
sudo apt install software-properties-common -y
sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo apt -f install -y
sudo cp /usr/local/bin/wkhtmltopdf /usr/bin/
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin/

#--------------------------------------------------
# Install Python Dependencies
#-------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt install git python3-pip build-essential wget python3-dev python3-venv python3-wheel libxslt-dev \
libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less -y

echo -e "\n---- Installing nodeJS NPM and rtlcss for LTR support ----"
sudo apt install nodejs npm -y
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g rtlcss less less-plugin-clean-css

#--------------------------------------------------
# Install Python PIP Dependencies
#--------------------------------------------------
sudo pip3 install Babel decorator docutils ebaysdk feedparser gevent greenlet html2text Jinja2 lxml \
Mako MarkupSafe mock num2words ofxparse passlib Pillow psutil psycogreen psycopg2 pydot pyparsing PyPDF2 \
pyserial python-dateutil python-openid pytz pyusb PyYAML qrcode reportlab requests six suds-jurko \
vatnumber vobject Werkzeug XlsxWriter xlwt xlrd

sudo python3 -m pip install libsass

#-------------------------------------------------
# Create Log directory
#-------------------------------------------------
echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/odoo 
sudo chown odoo:odoo /var/log/odoo

#------------------------------------------------
# Install Odoo
#-------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
git clone https://www.github.com/odoo/odoo --depth 1 --branch 12.0 /opt/odoo/odoo

#-------------------------------------------------
# Setting permissions on home folder
#-------------------------------------------------
sudo chown -R odoo:odoo /opt/odoo/*

#-------------------------------------------------
# Create server config file
#-------------------------------------------------
sudo cat <<EOF > /etc/odoo-server.conf
[options]
; This is the password that allows database operations:
; admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = odoo
db_password = admin
logfile = /var/log/odoo/odoo-server.log
addons_path = /opt/odoo/odoo/addons
EOF

sudo chown odoo:odoo /etc/odoo-server.conf
sudo chmod 640 /etc/odoo-server.conf

#--------------------------------------------------
# Adding Odoo as a deamon (initscript)
#--------------------------------------------------
cat <<EOF > /etc/init.d/odoo-server
#!/bin/sh

### BEGIN INIT INFO
# Provides: odoo-server
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Should-Start: $network
# Should-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: Odoo Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
NAME=odoo-server
DESC=ODOO-SERVER
# Specify the daemon path for Odoo server.
# (Default for ODOO >=10: /opt/odoo/odoo-bin)
# (Default for ODOO <=9: /opt/odoo/openerp-server)
DAEMON=/opt/odoo/odoo/odoo-bin
CONFIGFILE="/etc/odoo-server.conf" # Specify the Odoo Configuration file path.

USER=odoo # Specify the user name (Default: odoo).

PIDFILE=/var/run/$NAME.pid # pidfile

# Additional options that are passed to the Daemon.
DAEMON_ARGS="-c $CONFIGFILE"

display() {
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
col=$(tput cols)
case "$#" in
1)
if [ $1 -eq 0 ] ; then
printf '%s%*s%s' "$GREEN" $col "[ OK ] " "$NORMAL"
else
printf '%s%*s%s' "$RED" $col "[FAIL] " "$NORMAL"
fi
;;
2)
if [ $1 -eq 0 ] ; then
echo "$GREEN* $2$NORMAL"
else
echo "$RED* $2$NORMAL"
fi
;;
*)
echo "Invalid arguments"
exit 1
;;
esac
}

if ! [ -x $DAEMON ] ; then
echo "Error in ODOO Daemon file: $DAEMON" 
echo "Possible error(s):"
display 1 "Daemon File doesn't exists." 
display 1 "Daemon File is not set to executable." 
exit 0;
fi
if ! [ -r $CONFIGFILE ] ; then
echo "Error in ODOO Config file: $CONFIGFILE" 
echo "Possible error(s):" 
display 1 "Config File doesn't exists." 
display 1 "Config File is not set to readable." 
exit 0;
fi
if ! [ -w $PIDFILE ] ; then
touch $PIDFILE || echo "Permission issue: $PIDFILE" && exit 1
chown $USER: $PIDFILE
fi

# Function that starts the daemon/service
do_start() {
echo $1
check_status
procs=$?
if [ $procs -eq 0 ] ; then
start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
--chuid ${USER} --background --make-pidfile \
--exec ${DAEMON} -- ${DAEMON_ARGS}
return $?
else
detailed_info "${DESC} is already Running !!!" $procs
exit 1
fi
}

# Function that stops the daemon/service
do_stop() {
echo $1
check_status
if [ $? -ne 0 ] ; then
start-stop-daemon --stop --quiet --pidfile ${PIDFILE}
return $?
else
display 0 "${DESC} is already Stopped. You may try: $0 force-restart"
exit 1
fi
}

get_pids(){
pids=$(ps -Ao pid,cmd | grep $DAEMON | grep -v grep | awk '{print $1}')
return $pids
}

# Function that checks the status of daemon/service
check_status() {
echo $1
# start-stop-daemon --status --pidfile ${PIDFILE}
status=$(ps -Ao pid,cmd | grep $DAEMON | grep -v grep | awk '{print $1}' | wc -l)
return $status
}

# Function that forcely-stops all running daemon/service
force_stop() {
echo $1
pids=$(ps -Ao pid,cmd | grep $DAEMON | grep -v grep | awk '{print $1}')
if [ ! -z "$pids" ] ; then
kill -9 $pids
fi
return $?
}

detailed_info() {
procs=$2
if [ $procs -eq 1 ] ; then
display 0 "$1"
echo "FINE, ${procs} ${DESC} is Running."
echo "Details :"
pid=`cat $PIDFILE`
echo "Start Time : $(ps -p $pid -wo lstart=)"
echo "Total UpTime: $(ps -p $pid -wo etime=)"
echo "Process ID : ${pid}"
echo ""
else
display 1 "WARNING !!!"
display 1 "${procs} ${DESC}s are Running !!!"
pids=$(ps -Ao pid,cmd | grep $DAEMON | grep -v grep | awk '{print $1}')
echo "Details :"
echo -n "Process IDs : "
echo $pids
# echo $pids | tr ' ' ,
echo "In order to fix, Hit command: $0 force-restart"
echo ""
fi
}
case "$1" in
start)
do_start "Starting ${DESC} "
display $?
;;
stop)
do_stop "Stopping ${DESC} "
display $?
;;
status)
check_status "Current Status of ${DESC}:"
procs=$?
if [ $procs -eq 1 ] ; then
detailed_info "RUNNING" $procs
elif [ $procs -eq 0 ] ; then
display 1 "STOPPED"
else
detailed_info "" $procs
fi
;;
restart|reload)
do_stop "Stopping ${DESC} "
display $?
sleep 1
do_start "Starting ${DESC} "
display $?
;;
force-restart)
force_stop "Forcely Restarting ${DESC} "
sleep 1
do_start "Starting ${DESC} "
display $?
;;
force-stop)
force_stop "Forcely Stopping all running ${DESC} "
display $?
;;
cs)
ps -Ao pid,cmd | grep $DAEMON | grep -v grep | awk '{print $1}' | wc -l
;;
*)
display 1 "Usage: $0 {start|stop|restart/reload|status|force-restart|force-stop}"
exit 1
;;
esac

exit 0
EOF

#----------------------------------------------------------------
# Now set the ownership and permission of the configuration file
#----------------------------------------------------------------
sudo chmod 755 /etc/init.d/odoo-server
sudo chown root: /etc/init.d/odoo-server

#----------------------------------------------------------------
# Now, if you want to add this service to begin on boot up
#----------------------------------------------------------------
echo -e "* Start Odoo on Startup"
update-rc.d odoo-server defaults

#----------------------------------------------------------------
# To start the Odoo server
#----------------------------------------------------------------
echo -e "* Starting Odoo Service"
sudo /etc/init.d/odoo-server start

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running."
echo "Your odoo instance is up and running"
echo "Access the odoo server on http://domain_or_Ip.com:8069"
echo "-----------------------------------------------------------"

