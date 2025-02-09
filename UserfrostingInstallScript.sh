#!/bin/bash

# UserFrosting setup script for Ubuntu 24.04.1+
# This script installs PHP 8.3, Composer, Node.js, NPM, MySQL, Nginx, and sets up the UF environment.

set -e  # Exit on any error

# Set user-defined variables
DOMAIN_NAME="nqview.com"
EMAIL="admin@$DOMAIN_NAME"
SITE_FOLDER="NQView"
USER_NAME="$USER"
USER_HOME="/home/$USER"
USERFROSTING_VERSION="^5.1"
GIT_REPO="userfrosting/UserFrosting"
EXE_SQL=true

# MySQL settings
MYSQL_ROOT_PASSWORD="CHANGE_ME"
DB_NAME="CHANGE_ME"
DB_USER="CHANGE_ME"
DB_PASSWORD="CHANGE_ME"

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
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME"
sudo tee "$NGINX_CONF" > /dev/null <<EOL
server {
    listen 80;
    root $USER_HOME/$SITE_FOLDER/public;
    index index.php index.html;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
    location ~ /\.ht {
        deny all;
    }
}
EOL

# Enable Nginx site and restart service
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Install UserFrosting
echo "Installing UserFrosting..."
composer create-project "$GIT_REPO" "$SITE_FOLDER" "$USERFROSTING_VERSION"

# set UF yo production mode
echo "UF_MODE=production" | sudo tee -a "$USER_HOME/$SITE_FOLDER/app/.env" > /dev/null

# Obtain and configure SSL certificate
echo "Setting up SSL with Let's Encrypt..."
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
sudo systemctl reload nginx

echo "UserFrosting installation complete. Visit: https://$DOMAIN_NAME"
