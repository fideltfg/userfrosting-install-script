#!/bin/bash

# UserFrosting setup script for Ubuntu 24.04.1 or above.
# This script installs PHP 8.3, Composer, Node.js, NPM, MySQL, Nginx, and sets up the UF environment.
# Please read the  readme file @ https://github.com/fideltfg/userfrostinginstallscript for information about what this script does and how to use it.
#
# Run the following command from your home folder to download and run the newest version.
#
# cd ~ && wget https://github.com/fideltfg/userfrostinginstallscript/raw/refs/heads/main/UserfrostingInstallScript.sh -O UserfrostingInstallScript.sh && chmod +x UserfrostingInstallScript.sh && ./UserfrostingInstallScript.sh
#
# Do not run a root!
#
# MIT License

# Copyright (c) 2025 fideltfg

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e  # Exit on any error
RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"


if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${RED}Warning: No .env file found! Default setup values will be used. This is not recommended.${ENDCOLOR}"
    while true; do
        read -p "Do you wish to continue using the default settings (Y)es or (N)o ? " yn
        case $yn in
            [Yy]* ) 
                echo -e "${BLUE}OK...Continuing install with default settings....${ENDCOLOR}"; 
            
                break;;
            [Nn]* ) 
                echo -e "${BLUE}Canceling install.${ENDCOLOR} No changes were made to your system. Please read how to set up your .env file in the readme file @ https://github.com/fideltfg/userfrostinginstallscript";
                exit;;
            * ) echo "Please answer (Y)es or (N)o.";;
        esac
    done
fi

# Set user-defined variables
DOMAIN_NAME="${DOMAIN_NAME:-example.com}"
EMAIL="${EMAIL:-example@email.com}"
SITE_NAME="${SITE_NAME:-$DOMAIN_NAME}"
#USERFROSTING_VERSION="${USERFROSTING_VERSION:-^5.1}"
GIT_REPO="${GIT_REPO:-userfrosting/UserFrosting}"
EXE_SQL="${EXE_SQL:-true}"
IMPORT_DUMP="${IMPORT_DUMP:-false}"
DB_CONNECTION="${DB_CONNECTION:-mysql}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
MAIL_MAILER="${MAIL_MAILER:-smtp}"
SMTP_SERVER="${SMTP_SERVER:-smtp.example.com}"
SMTP_USER="${SMTP_USER:-your@email.com}"
SMTP_PASSWORD="${SMTP_PASSWORD:-password}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_AUTH="${SMTP_AUTH:-true}"
SMTP_SECURE="${SMTP_SECURE:-tls}"
MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-noreply@yourdomain.com}"
MAIL_FROM_NAME="${MAIL_FROM_NAME:-UserFrosting}"
UF_MODE="${UF_MODE:-debug}"
UF_ADMIN_USER="${UF_ADMIN_USER:-admin}"
UF_ADMIN_EMAIL="${UF_ADMIN_EMAIL:-example@email.com}"
UF_ADMIN_PASSWORD="${UF_ADMIN_PASSWORD:-password}"
UF_ADMIN_FIRST_NAME="${UF_ADMIN_FIRST_NAME:-Admin}"
UF_ADMIN_LAST_NAME="${UF_ADMIN_LAST_NAME:-User}"

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
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS \`$DB_NAME\`;
    DROP USER IF EXISTS '$DB_USER'@'localhost';
    CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, ALTER ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
    GRANT RELOAD ON *.* TO '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;
EOF

    if [[ "$IMPORT_DUMP" == true ]]; then
        echo -e "${YELLOW}Importing SQL dump file...${ENDCOLOR}"
        if [[ -f "dump.sql" ]]; then
            echo -e "${GREEN}Dump file found. ${ENDCOLOR}"
            sudo mysql -u $DB_USER -p"$DB_PASSWORD" "$DB_NAME" < dump.sql
        else
            echo -e "${YELLOW}No SQL dump file found. Skipping import.${ENDCOLOR}"
        fi
    fi
    
fi



# Install Nginx
echo -e "${YELLOW}Installing Nginx...${ENDCOLOR}"
sudo apt-get install -y nginx

# Install UserFrosting
echo -e "${YELLOW}About to start Userfrosting Compser install section. This portion has a timeout on user input."
read -n 1 -s -r -p "Press any key to continue..."
echo -e "${ENDCOLOR}"

echo -e "${YELLOW}Installing UserFrosting...${ENDCOLOR}"

git clone https://github.com/$GIT_REPO.git $SITE_NAME
cd $SITE_NAME

echo -e "${YELLOW}Creating and populating $USER_HOME/$SITE_NAME/app/.env file... ${ENDCOLOR}"
printf 'UF_MODE="%s"\nDB_CONNECTION="%s"\nDB_HOST="%s"\nDB_PORT="%s"\nDB_NAME="%s"\nDB_USER="%s"\nDB_PASSWORD="%s"\nMAIL_MAILER="%s"\nSMTP_SERVER="%s"\nSMTP_USER="%s"\nSMTP_PASSWORD="%s"\nSMTP_PORT="%s"\nSMTP_AUTH="%s"\nSMTP_SECURE="%s"\nMAIL_FROM_ADDRESS="%s"\nMAIL_FROM_NAME="%s"\n' \
"$UF_MODE" "$DB_CONNECTION" "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD" "$MAIL_MAILER" "$SMTP_SERVER" "$SMTP_USER" "$SMTP_PASSWORD" "$SMTP_PORT" "$SMTP_AUTH" "$SMTP_SECURE" "$MAIL_FROM_ADDRESS" "$MAIL_FROM_NAME" \
| sudo tee "$USER_HOME/$SITE_NAME/app/.env" > /dev/null
sudo chown -R $USER:$USER "$USER_HOME/$SITE_NAME/app/.env"

echo -e "${YELLOW}Running Composer install...${ENDCOLOR}"
composer install
if [[ "$IMPORT_BUMP" != true ]]; then
    echo -e "${YELLOW}Building Database...${ENDCOLOR}"
    php bakery setup:db --force --db_driver $DB_CONNECTION --db_name $DB_NAME --db_host $DB_HOST --db_port $DB_PORT --db_user $DB_USER --db_password $DB_PASSWORD
    
    php bakery migrate
    
    echo -e "${YELLOW}Creating admin user account...${ENDCOLOR}"
    php bakery create:admin-user --username="$UF_ADMIN_USER" --email="$UF_ADMIN_EMAIL" --password="$UF_ADMIN_PASSWORD" --firstName="$UF_ADMIN_FIRST_NAME" --lastName="$UF_ADMIN_LAST_NAME"

    echo -e "${YELLOW}Seeding Database...${ENDCOLOR}"
    php bakery seed 
    
    
else
    echo -e "${YELLOW}UF Database setup skipped.${ENDCOLOR}"
fi
echo -e "${GREEN}Completed!${ENDCOLOR}"

# Configure Nginx
echo -e "${YELLOW}Configuring Nginx...${ENDCOLOR}"

ROOT_DIR="$USER_HOME/$SITE_NAME/public"
DEFAULT_CONFIG="/etc/nginx/sites-available/default"
DEFAULT_ENABLED="/etc/nginx/sites-enabled/default"

sudo chmod +x "/home/$USER"
sudo chown -R $USER:www-data "/home/$USER/$SITE_NAME"
sudo chmod -R 755 "/home/$USER/$SITE_NAME"
sudo chmod -R 775 "$ROOT_DIR"

# Set Nginx configuration
sudo rm -f /etc/nginx/sites-enabled/*

sudo tee "$DEFAULT_CONFIG" > /dev/null <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root $ROOT_DIR;
    index index.php index.html;
    server_name _;

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;

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

# Deploy the config
sudo ln -s "$DEFAULT_CONFIG" "$DEFAULT_ENABLED"

# Restart Nginx to apply changes
sudo nginx -t && sudo systemctl restart nginx

if [[ "$UF_MODE" == "production" ]]; then
    # Obtain and configure SSL certificate
    echo -e "${BLUE}Setting up SSL with Let's Encrypt...${ENDCOLOR}"
    sudo apt-get install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --test-cert -m "$EMAIL"
    sudo systemctl reload nginx
else
    echo -e "${BLUE}UF Mode $UF_MODE. Skipping SSL setup. Please configure SSL manually if needed.${ENDCOLOR}"    

fi

#set UF required permissions
sudo usermod -a -G www-data $USER
sudo chown -R $USER:www-data "$USER_HOME/$SITE_NAME/app/logs"
sudo chmod -R 775 "$USER_HOME/$SITE_NAME/app/logs"
sudo chmod -R 775 "$USER_HOME/$SITE_NAME/app/cache"
sudo chmod -R 775 "$USER_HOME/$SITE_NAME/app/sessions"


echo -e "${YELLOW}Baking Assets${ENDCOLOR}"
php bakery assets:build
npx update-browserslist-db@latest
echo -e "${GREEN}==========================${ENDCOLOR}"
echo -e "${GREEN}UserFrosting installation complete.${ENDCOLOR}"
echo -e "Visit your site @: https://$DOMAIN_NAME"
echo -e "UF MODE: ${BLUE}$UF_MODE${ENDCOLOR}"
if [[ "$UF_MODE" != "production" ]]; then
    echo -e "UF admin user: $UF_ADMIN_USER"
    echo -e "First Name: $UF_ADMIN_FIRST_NAME"
    echo -e "Last Name: $UF_ADMIN_LAST_NAME"
    echo -e "Site Name: $SITE_NAME"
    echo -e "Domain Name: $DOMAIN_NAME"
    echo -e "Email: $UF_ADMIN_EMAIL"
    echo -e "Password : $UF_ADMIN_PASSWORD"
    echo -e "Document Root: $ROOT_DIR"
    echo -e "DB Connection: $DB_CONNECTION"
    echo -e "DB Name: $DB_NAME"
    echo -e "DB User: $DB_USER"
    echo -e "Password: $DB_PASSWORD"
    echo -e "MySQL Root Password: $MYSQL_ROOT_PASSWORD"
fi
echo -e "${GREEN}==========================${ENDCOLOR}"

# delete this script
rm -f "$USER_HOME/UserfrostingInstallScript.sh"
exit 0
