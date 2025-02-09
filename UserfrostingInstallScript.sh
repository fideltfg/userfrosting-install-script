#!/bin/bash

# UserFrosting setup script for Ubuntu 24.04.1+
# This script installs PHP 8.3, Composer, Node.js, NPM, MySQL, Nginx, and sets up the UF environment.

set -e  # Exit on any error
RED="\e[31m"
YELLOW="\e[33m"
Green="\e[33m"
ENDCOLOR="\e[0m"


if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${YELLOW}Warning: No .env file found! Default setup values will be used. This is not recommended.${ENDCOLOR}"
    while true; do
        read -p "Do you wish to continue using the default settings (Y)es or (N)o ? " yn
        case $yn in
            [Yy]* ) 
                echo "${YELLOW}OK...Continuing install with default settings....${ENDCOLOR}"; 
            
                break;;
            [Nn]* ) 
                echo "Canceling install. No changes were made to your system. Please read how to set up your .env file in the readme file @ https://github.com/fideltfg/userfrostinginstallscript/raw/refs/heads/main/README.md";
                exit;;
            * ) echo "Please answer (Y)es or (N)o.";;
        esac
    done
fi

# Set user-defined variables
DOMAIN_NAME="${DOMAIN_NAME:-example.com}"
EMAIL="${EMAIL:-example@email.com}"
SITE_NAME="${SITE_NAME:-$DOMAIN_NAME}"
USERFROSTING_VERSION="${USERFROSTING_VERSION:-^5.1}"
GIT_REPO="${GIT_REPO:-userfrosting/UserFrosting}"
EXE_SQL="${EXE_SQL:-true}"

# MySQL settings
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-userfrosting}"
DB_NAME="${DB_NAME:-userfrosting}"
DB_USER="${DB_USER:-userfrosting}"
DB_PASSWORD="${DB_PASSWORD:-userfrosting}"

# DO NOT CHANGE THESE
USER_NAME="$USER"
USER_HOME="/home/$USER"

# Update system packages
echo -e "${YELLOW}Updating installed packages...${ENDCOLOR}"
sudo apt-get update -y && sudo apt-get upgrade -y

# Install PHP and required extensions
echo -e "${YELLOW}Installing PHP 8.3 and required extensions...${ENDCOLOR}"
sudo apt-get install -y php8.3 php8.3-{cli,bz2,curl,mbstring,intl,fpm,pdo-mysql,mysql,gd,dom,zip,sqlite3}

# Install Composer
echo -e "${YELLOW}Installing Composer...${ENDCOLOR}"
sudo apt-get install -y composer || (wget -qO composer-setup.php https://getcomposer.org/installer && sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php)

# Install Node.js and NPM
echo -e "${YELLOW}Installing Node.js and NPM...${ENDCOLOR}"
sudo apt-get install -y nodejs npm

# Install MySQL and configure database if enabled
if [[ "$EXE_SQL" == true ]]; then
    echo -e "${YELLOW}Setting up MySQL database and user...${ENDCOLOR}"
    sudo apt-get install -y mysql-server
    sudo systemctl start mysql
    sudo systemctl enable mysql
    
    sudo mysql --defaults-file=/etc/mysql/debian.cnf <<EOF
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
    CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
    GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;
EOF
    
    if [[ -f "dump.sql" ]]; then
        echo -e "${YELLOW}Importing SQL dump file...${ENDCOLOR}"
        sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$DB_NAME" < dump.sql
    else
        echo -e "${YELLOW}No SQL dump file found. Skipping import."
    fi
fi

# Install and configure Nginx
echo -e "${YELLOW}Installing and configuring Nginx...${ENDCOLOR}"
sudo apt-get install -y nginx
NGINX_CONF="/etc/nginx/sites-available/$SITE_NAME"

sudo tee "$NGINX_CONF" > /dev/null <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root $USER_HOME/$SITE_NAME/public;
    index index.php index.html;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~ /\.ht {
        deny all;
    }
}
EOL

# Remove default Nginx configuration
if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
    sudo rm -f /etc/nginx/sites-enabled/default
fi

# Enable Nginx site and restart service
echo -e "${YELLOW}Enabling Nginx site and restarting service.....${ENDCOLOR}"
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/$SITE_NAME
sudo nginx -t && sudo systemctl restart nginx

# Install UserFrosting
echo -e "${YELLOW}About to start Userfrosting Compser install section. This portion has a timeout on user input."
read -n 1 -s -r -p "${YELLOW}Press any key to continue...${ENDCOLOR}"
echo -e "${ENDCOLOR}"

echo -e "${YELLOW}Installing UserFrosting...${ENDCOLOR}"
composer create-project "$GIT_REPO" "$SITE_NAME" "$USERFROSTING_VERSION"

# Set UF to production mode
echo -e "${YELLOW}Settung Userfrosting to Production Mode${ENDCOLOR}"
echo "UF_MODE=production" | sudo tee -a "$USER_HOME/$SITE_NAME/app/.env" > /dev/null
echo -e "${GREEN}Completed!${ENDCOLOR}"

# Obtain and configure SSL certificate
echo -e "${YELLOW}Setting up SSL with Let's Encrypt...${ENDCOLOR}"
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
sudo systemctl reload nginx

echo -e "${GREEN}==========================${ENDCOLOR}"
echo -e "${GREEN}UserFrosting installation complete. Visit: https://$DOMAIN_NAME${ENDCOLOR}"
echo -e "${GREEN}==========================${ENDCOLOR}"
