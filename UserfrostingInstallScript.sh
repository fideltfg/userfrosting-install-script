#!/bin/bash

# UserFrosting setup script for Ubuntu 24.04.1+
# This script installs PHP 8.3, Composer, Node.js, NPM, MySQL, Nginx, and sets up the UF environment.

set -e  # Exit on any error

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Warning: No .env file was found! Default setup values will be used. This is not recommended."
    while true; do
        read -p "Do you wish to continue using the default setting (Y)es or (N)o ?" yn
        case $yn in
            [Yy]* ) 
                echo "OK...Continuing install with default settings...."; 
            
                break;;
            [Nn]* ) 
                echo "Canceling install. No changes were made to your system. Please read how to set up your .env file in the readme file @ https://github.com/fideltfg/userfrostinginstallscript/blob/main/README.md";
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
echo "Updating installed packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install PHP and required extensions
echo "Installing PHP 8.3 and required extensions..."
sudo apt-get install -y php8.3 php8.3-{cli,bz2,curl,mbstring,intl,fpm,pdo-mysql,mysql,gd,dom,zip,sqlite3}

# Install Composer
echo "Installing Composer..."
sudo apt-get install -y composer || (wget -qO composer-setup.php https://getcomposer.org/installer && sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php)

# Install Node.js and NPM
echo "Installing Node.js and NPM..."
sudo apt-get install -y nodejs npm

# Install MySQL and configure database if enabled
if [[ "$EXE_SQL" == true ]]; then
    echo "Setting up MySQL database and user..."
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
        echo "Importing SQL dump file..."
        sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$DB_NAME" < dump.sql
    else
        echo "No SQL dump file found. Skipping import."
    fi
fi

# Install and configure Nginx
echo "Installing and configuring Nginx..."
sudo apt-get install -y nginx
NGINX_CONF="/etc/nginx/sites-available/$SITE_NAME"
DEFAULT_CONF="/etc/nginx/sites-available/default"

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
if [[ -f "$DEFAULT_CONF" ]]; then
    sudo rm "$DEFAULT_CONF"
fi

# Enable Nginx site and restart service
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

# Install UserFrosting
echo "Installing UserFrosting..."
composer create-project "$GIT_REPO" "$SITE_NAME" "$USERFROSTING_VERSION"

# Set UF to production mode
echo "UF_MODE=production" | sudo tee -a "$USER_HOME/$SITE_NAME/app/.env" > /dev/null

# Obtain and configure SSL certificate
echo "Setting up SSL with Let's Encrypt..."
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
sudo systemctl reload nginx

echo "UserFrosting installation complete. Visit: https://$DOMAIN_NAME"
