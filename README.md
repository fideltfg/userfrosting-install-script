# UserFrosting Installation Script

> [!NOTE]
> PLEASE READ THE FULL README BELOW BEFORE YOU RUN THE SCRIPT!

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
Create a `.env` file in your home folder and populate ALL the values. See the example .env file [here](https://github.com/fideltfg/userfrostinginstallscript/blob/main/.env_example)
```ini
DOMAIN_NAME=yourdomain.com
EMAIL=admin@yourdomain.com
SITE_NAME=your-site-folder
GIT_REPO=userfrosting/UserFrosting
EXE_SQL=true
MYSQL_ROOT_PASSWORD=securepassword
DB_NAME=userfrosting
DB_USER=userfrosting
DB_PASSWORD=securepassword
......
```


> [!WARNING]
> The EXE_SQL parameter when set true will force the script to erase any database with the name set in DB_HOST.
>
> If the IMPORT_DUMP parameter is set true the script will attempt to import a file called dump.sql and execute the commands it contains on the named database. Ensure the file exists and that you know its contents are correct. The Userfrosting migration and seeding steps are also skipped.

> [!NOTE]
> If the repo being cloned is private, ensure you have your public ssh key added on [Github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh). Depending on how your key was generated you may be asked to enter your keys passphrase at that point in the script.


### 2. Run the Script
Run the followng command to install all needed packages, setup MySQL, NGINX Userfrosting. DO NOT RUN AS ROOT!
```bash
cd ~ && wget https://github.com/fideltfg/userfrosting-install-script/raw/refs/heads/main/UserfrostingInstallScript.sh -O UserfrostingInstallScript.sh && chmod +x UserfrostingInstallScript.sh && ./UserfrostingInstallScript.sh
```
This will pull the latest version of the install script, correct the permissions and excute it. 

#### User Input
While I tried to make the script run unattended, due to the way the Userfrosting Bakery does its thing, the script will ask you to enter passwords and make a few choices if required.

##### sudo password
The script will ask you a numberof times for you users sudo password. Once when it first starts and again after the composer install section.

##### Database Migrator
~~The Database Migrator will askyou to confirm that you want to run the listed migrations. Confirm yes.~~

##### Seeder
The Seeder will ask you to select which seads you want to run:
 
```bash
 Select seed(s) to run. Multiple seeds can be selected using comma separated values:
 [0] UserFrosting\Sprinkle\Account\Database\Seeds\DefaultGroups
 [1] UserFrosting\Sprinkle\Account\Database\Seeds\DefaultPermission
 [2] UserFrosting\Sprinkle\Account\Database\Seeds\DefaultRoles
 ....
 >
```
Type `0,1,2` and hit enter. Or if you cloned a differnt repo check that all the required seeds are listed and modify your input accodingly.

You will then be asked to confrim your entry with `Do you really wish to continue ? (yes/no) [no]:` Confirm yes.

Enter your sudo password.

### 3. Post-Installation
Once completed, you will see something like this 
```bash
==========================
UserFrosting installation complete.
Visit your site @: https://example.com
UF MODE: production
==========================
```

If you set the `UF_MODE` to anything other than production you will be given a more verbose final output.

> [!CAUTION]
> Running this script in debug mode and then again in production mode on the same OS instance will leave records of your config values in log files.
> Only run the script with UF_MODE set to production on a fresh clean server to avoid this. Dev &harr; Test &rarr; Wipe &rarr; Deploy

### Logs
The logs for Nginx, MySQL and PHP are in ther default locations for the distro you used.
If you encounter issues, check the Nginx logs with:
```bash
sudo tail -f /var/log/nginx/error.log
```
The MySQL logs with:
```bash
sudo tail -f /var/log/mysql/error.log
```
The  Userfrosting error log with:
```
tail -f ~/<YOURSITENAME>/app/logs/userfrosting.log
```

## Notes
- This script tries to load configuration values from an optional `.env` file located in the users home folder.
- MySQL authentication is set to `mysql_native_password`.
- Nginx is configured to serve UserFrosting from `/home/$USER/$SITE_NAME/public`.
- SSL certificates are obtained automatically using Let's Encrypt when UF_MODE="production" else this part is skipped.
- If the repo being cloned is private, ensure you have your public ssh key added on Github. Depending on how your key was generated you may be asked to enter your keys passphrase at that point in the script.
- Ensure that the values in the `config/default.php are all set the to the correct values for your site.

## Known Issues
- UF Bakery still needs some input to setup and seed the database.

## Work-Arounds
In order to prevent users from flooding Let's Encrypts servers when testing this script, the `--test-cert` flag is set for certbot by default. 

> [!IMPORTANT]  
> The `--test-cert` flag may cause Let's Encrypt to issue your site with an expired certificate. This in turn can cause issues with some antivirus softwear and will cause your browser to see the page as insecure.

The `--test-cert` flag needs to be removed for your site to be issued a valid certificate. Run `sudo certbot` and follow the wizzard to `Renew & replace the certificate` for your domain.  
