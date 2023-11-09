#!/bin/bash
export HOME=/home/ec2-user
export EMAIL="test@gmail.com"
export SCRIPT_INPUT=$HOME/LAMP-Project
export EC2_PUBLIC_IP=$(curl http://checkip.amazonaws.com)

# Update system packages
sudo dnf update -y

# Loops over $packages, if rpm - q $package -> true package installed, then (false) installs package
packages=("httpd" "wget" "php8.2-fpm-8.2.9-1.amzn2023.0.3.x86_64" "php8.2-mysqlnd-8.2.9-1.amzn2023.0.3.x86_64" "php8.2-common-8.2.9-1.amzn2023.0.3.x86_64" "php8.2-8.2.9-1.amzn2023.0.3.x86_64" "php8.2-devel-8.2.9-1.amzn2023.0.3.x86_64" "mariadb105-server" "git" "expect" "php8.2-mbstring-8.2.9-1.amzn2023.0.3.x86_64" "php8.2-xml-8.2.9-1.amzn2023.0.3.x86_64" "python3" "augeas-libs" "mod_ssl")

for package in "${packages[@]}"; do
    if rpm -q "$package" &>/dev/null; then
        echo "$package it's already installed."
    else
        echo "Installing $package..."
        sudo dnf install -y "$package"
    fi
done

# Loops over $services, and starts/enables services.
services=("httpd" "mariadb" "php-fpm")

for service in ${services[*]}; do
    if ! systemctl is-active --quiet $service && ! systemctl is-enabled --quiet $service; then
       echo "Starting $service and enabling it at system boot."
       sudo systemctl start $service
       sudo systemctl enable $service
    else
       echo "$service is already running and enabled."
    fi
done

permissions_fun () {
    # Add ec2-user to the 'apache' group
    sudo usermod -a -G apache ec2-user
    # Change '/var/www' ownership to ec2-user and apache group
    sudo chown -R ec2-user:apache /var/www
    # add group write permissions and to set the group ID on future subdirectories, change the directory permissions of /var/www and its subdirectories.
    sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
    # add group write permissions, recursively change the file permissions of /var/www and its subdirectories
    find /var/www -type f -exec sudo chmod 0664 {} \;
} 

permissions_fun

# MYSQL Secure installation
cat <<EOT > mysql_secure_install.sh
#!/usr/bin/expect

set password "asd123"

spawn sudo mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication"
send "n\r"
expect "Change the root password?"
send "y\r"
expect "New password:"
send "\$password\r"
expect "Re-enter new password:"
send "\$password\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "n\r"
expect "Remove test database and access to it?"
send "n\r"
expect "Reload privilege tables now?"
send "y\r"
EOT
chmod +x mysql_secure_install.sh
expect mysql_secure_install.sh

# DevopsTravel DB Creation
cat <<EOT > devopstravel.sql
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;
EOT
mysql -u root < devopstravel.sql

# Webpage & Database tables Installation
if [ -d $HOME/bootcamp-devops-2023 ]; 
then
    echo "Repository alredy exists."
else
    git clone -b clase2-linux-bash --single-branch https://github.com/roxsross/bootcamp-devops-2023.git $HOME/bootcamp-devops-2023/
    cp -r $HOME/bootcamp-devops-2023/app-295devops-travel/* /var/www/html/
    mysql -u root < /home/ec2-user/bootcamp-devops-2023/app-295devops-travel/database/devopstravel.sql
    rm -r -f $HOME/bootcamp-devops-2023/
    sed -i 's/""/"codepass"/g' /var/www/html/config.php
    sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php/g' /etc/httpd/conf/httpd.conf
fi

# Install PhpMyAdmin
if [ -f $HOME/phpMyAdmin-latest-all-languages.tar.gz ];
then
    echo "phpMyAdmin already installed."
else
    wget -P $HOME https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
    mkdir /var/www/html/phpMyAdmin
    tar -xvzf $HOME/phpMyAdmin-latest-all-languages.tar.gz -C /var/www/html/phpMyAdmin --strip-components 1
    rm -f $HOME/phpMyAdmin-latest-all-languages.tar.gz
fi

#Restart services
sudo systemctl restart httpd
sudo systemctl restart mariadb

# Certbot & SSL Configuration 
# REQUIRES A DOMAIN. If the domain utilized is not created, certbot will fail.

#sudo python3 -m venv /opt/certbot/
#sudo /opt/certbot/bin/pip install --upgrade pip
#sudo /opt/certbot/bin/pip install certbot certbot-apache
#sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
#cat <<EOT > /etc/httpd/conf.d/devops-travel.bernatei.com.conf
#<VirtualHost *:80>
#    ServerName devops-travel.bernatei.com
#    DocumentRoot /var/www/html
#</VirtualHost>
#EOT
#certbot --apache -d devops-travel.bernatei.com -m asdasd123asd@gmail.com  --agree-tos -n


## DISCORD.SH Script Execution
git clone https://github.com/bertei/LAMP-Project.git /home/ec2-user/LAMP-Project

sleep 200

cat << EOF > discord.sh
#!/bin/bash
DISCORD="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"
REPO_DIR="/home/ec2-user/LAMP-Project/"

if [ \$# -ne 2 ]; then
  echo "Error al ejecutar \$0, porfavor proporcione dos argumentos: <ruta_del_repositorio> <ec2_public_ip>"
  exit 1
fi

cd "\$1"
pwd

# Obtiene el nombre del repositorio
REPO_NAME=\$(basename \$(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=\$(git remote get-url origin)
WEB_URL="\$2"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=\$(curl -Is "\$WEB_URL" | head -n 1)

echo \$REPO_NAME
echo \$REPO_URL
echo \$WEB_URL
echo \$HTTP_STATUS

git config --global --add safe.directory \$REPO_DIR

if [[ "\$HTTP_STATUS" == *"200 OK"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio \$REPO_NAME: "
    DEPLOYMENT_INFO="La página web \$WEB_URL está en línea."
    COMMIT="Commit: \$(git rev-parse --short HEAD)"
    AUTHOR="Autor: \$(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: \$(git log -1 --pretty=format:'%s')"
else
  DEPLOYMENT_INFO="La página web \$WEB_URL no está en línea."
fi

echo \$DEPLOYMENT_INFO2
echo \$DEPLOYMENT_INFO
echo \$COMMIT
echo \$AUTHOR
echo \$DESCRIPTION

# Construye el mensaje
MESSAGE="\$DEPLOYMENT_INFO2\n\$DEPLOYMENT_INFO\n\$COMMIT\n\$AUTHOR\n\$REPO_URL\n\$DESCRIPTION"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"\${MESSAGE}"'"
     }' "\$DISCORD"
EOF

chmod +x discord.sh
sh discord.sh $SCRIPT_INPUT $EC2_PUBLIC_IP