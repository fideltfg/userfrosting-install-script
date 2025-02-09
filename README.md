# UserFrosting Installation Script

## Overview
This script automates the installation and configuration of [UserFrosting](https://www.userfrosting.com/) on an Ubuntu 24.04.1+ server. It installs required dependencies, sets up a MySQL database, configures an Nginx web server, and enables SSL with Let's Encrypt.

## Features
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

## Usage
### 1. Update Script Variables
Before running the script, edit the following variables at the beginning of the file:
- `DOMAIN_NAME`: Set to your domain (e.g., `example.com`)
- `EMAIL`: Admin email for SSL certificate notifications
- `MYSQL_ROOT_PASSWORD`: Set a secure password for MySQL root user
- `DB_NAME`: Name of the database for UserFrosting
- `DB_USER`: Database username
- `DB_PASSWORD`: Database password

### 2. Run the Script
Give execution permission and run the script:
```bash
chmod +x UserfrostingInstallScript.sh
./UserfrostingInstallScript.sh
```

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
- This script assumes MySQL authentication is set to `mysql_native_password`.
- Nginx is configured to serve UserFrosting from `$USER_HOME/$SITE_FOLDER/public`.
- If a `dump.sql` file is found in the script directory, it will be imported into the database.
- The script is designed to be non-interactive until it reaches the UD bakery section. You will need to enter your UF database and admin user details manualy.
- The site is set in dev mode by defailt. You will need to add a .env file to the site folder and set ufmode="production". ( I will update this soon so that it defaults to production.

## License
This script is provided as-is, without warranty. Modify it to fit your deployment needs.

