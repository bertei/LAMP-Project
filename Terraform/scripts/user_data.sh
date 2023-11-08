#!/bin/bash
export HOME=/home/ec2-user
export EMAIL="test@gmail.com"
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


#Restart services
sudo systemctl restart httpd
sudo systemctl restart mariadb
