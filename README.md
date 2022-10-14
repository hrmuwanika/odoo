# Installation Script for Odoo Open Source

This script will also give you the ability to define an xmlrpc_port in the .conf file that is generated under /etc/
This script can be safely used in a multi-odoo code base server because the default Odoo port is changed BEFORE the Odoo is started.

## Installing Nginx
If you set the parameter ```INSTALL_NGINX``` to ```True``` you should also configure workers. Without workers you will probably get connection loss issues. Look at [the deployment guide from Odoo](https://www.odoo.com/documentation/14.0/setup/deploy.html) on how to configure workers.

## Installation procedure

##### 1. Download the script:
```
wget https://raw.githubusercontent.com/hrmuwanika/odoo/15.0/install_odoo_ubuntu.sh
```
##### 2. Modify the parameters as you wish.
There are a few things you can configure, this is the most used list:<br/>
```OE_USER``` will be the username for the system user.<br/>
```GENERATE_RANDOM_PASSWORD``` if this is set to ```True``` the script will generate a random password, if set to ```False```we'll set the password that is configured in ```OE_SUPERADMIN```. By default the value is ```True``` and the script will generate a random and secure password.<br/>
```OE_PORT``` is the port where Odoo should run on, for example 8069.<br/>
```OE_VERSION``` is the Odoo version to install, for example ```15.0``` for Odoo V14.<br/>
```IS_ENTERPRISE``` will install the Enterprise version on top of ```15.0``` if you set it to ```True```, set it to ```False``` if you want the community version of Odoo 15.<br/>
```OE_SUPERADMIN``` is the master password for this Odoo installation.<br/>
```INSTALL_NGINX``` is set to ```True``` by default. Set this to ```False``` if you don't want to install Nginx.<br/>
```WEBSITE_NAME``` Set the website name here for nginx configuration<br/>
```ENABLE_SSL``` Set this to ```True``` to install [certbot](https://certbot.eff.org/lets-encrypt/ubuntufocal-nginx) and configure nginx with https using a free Let's Encrypted certificate<br/>
```ADMIN_EMAIL``` Email is needed to register for Let's Encrypt registration. Replace the default placeholder with an email of your organisation.<br/>
```INSTALL_NGINX``` and ```ENABLE_SSL``` must be set to ```True``` and the placeholder in ```ADMIN_EMAIL``` must be replaced with a valid email address for certbot installation<br/>
  _By enabling SSL though Let's Encrypt you agree to the following [policies](https://www.eff.org/code/privacy/policy)_ <br/>

#### 3. Make the script executable
```
sudo chmod +x install_odoo_ubuntu.sh
```
##### 4. Execute the script:
```
sudo ./install_odoo_ubuntu.sh
```

The installation should take about 10 minutes to complete and then you will be able to access it from
anywhere in the world by entering its ipaddress.

For more information on hosting, upgrading to odoo enterprise, and changing your domain, contact me hrmuwanika@gmail.com
