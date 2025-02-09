# UserFrosting Installation Script

## Overview
This script automates the installation and configuration of [UserFrosting](https://www.userfrosting.com/) on an Ubuntu 24.04.1+ server. It installs required dependencies, sets up a MySQL database, configures an Nginx web server, and enables SSL with Let's Encrypt.

## Features
- Loads configuration from an optional `.env` file for easy customization
- Installs PHP 8.3 and necessary extensions
- Installs Composer, Node.js, and NPM
- Sets up MySQL and creates a database and user
- Installs and configures Nginx with a virtual host
- Downloads and installs UserFrosting
- Enables HTTPS using Let's Encrypt SSL certificate

## Prerequisites
- A fresh Ubuntu 24.04.1+ installation
- A registered domain name pointing to your server
- Sudo privileges on the server
- (Optional) A `.env` file in the same directory to override default values

## Usage
### 1. Configure Environment Variables (Recommended)
If you want to override default settings, create a `.env` file in your home folder.
```ini
DOMAIN_NAME=yourdomain.com
EMAIL=admin@yourdomain.com
SITE_NAME=your-site-folder
USERFROSTING_VERSION=^5.1
GIT_REPO=userfrosting/UserFrosting
EXE_SQL=true
MYSQL_ROOT_PASSWORD=securepassword
DB_NAME=userfrosting
DB_USER=userfrosting
DB_PASSWORD=securepassword
```

### 2. Run the Script
Run the followng commands to install all needed packages, setup MySQL, NGINX Userfrosting. DO NOT RUN AS ROOT!
```bash
cd ~
wget https://raw.githubusercontent.com/fideltfg/userfrostinginstallscript/refs/heads/main/UserfrostingInstallScript.sh -O UserfrostingInstallScript.sh
chmod +x UserfrostingInstallScript.sh
./UserfrostingInstallScript.sh
```
This will pull the latest version of the install script, correct the permissions and excute it. Simply follow any prompts given to complete the process.

### 3. Post-Installation
Once completed, you can access UserFrosting at:
```
https://yourdomain.com
```
If you encounter issues, check the logs:
```bash
sudo journalctl -u nginx --no-pager
sudo systemctl status mysql
```

## Notes
- This script loads configuration from an optional `.env` file.
- MySQL authentication is set to `mysql_native_password`.
- Nginx is configured to serve UserFrosting from `/home/$USER/$SITE_NAME/public`.
- If a `dump.sql` file is found in the script directory, it will be imported into the database.
- The script is designed to hands off as much as possible. UF Bakery still needs input to setup the database and the UF admin user account.
- SSL certificates are obtained automatically using Let's Encrypt.
