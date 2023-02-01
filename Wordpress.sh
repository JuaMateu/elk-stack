#!bin/bash
function updateUbuntu() {
    sudo apt-get update 
    sudo apt-get upgrade
}
function installNgnix() {
    sudo apt-get install -y nginx 
}
function installMariaDB() {
    sudo apt-get install mariadb-server 
    sudo systemctl enable mariadb.service

    #! configurar usuario root!!!!!!!!!
}
function installPHP() {
    sudo apt-get install php7.2 php7.2-cli php7.2-fpm php7.2-mysql php7.2-json php7.2-opcache php7.2-mbstring php7.2-xml php7.2-gd php7.2-curl
}

function WPDatabase() {

	echo "Enter database name!"
	read dbname
    
	echo "Creating new MySQL database..."
	mysql -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	echo "Database successfully created!"
	
	echo "Enter database user!"
	read username
    
	echo "Enter the PASSWORD for database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
    
	echo "Creating new user..."
	mysql -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"

	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
	
# If /root/.my.cnf doesn't exist then it'll ask for root password	
else
	echo "Please enter root user MySQL password!"
	echo "Note: password will be hidden when typing"
	read -s rootpasswd
    
	echo "Enter database name!"
	read dbname
    
	echo "Creating new MySQL database..."
	mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	echo "Database successfully created!"
    
	echo "Enter database user!"
	read username
    
	echo "Enter the PASSWORD for database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
    
	echo "Creating new user..."
	mysql -uroot -p${rootpasswd} -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"
	
	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
fi

}

function ConfigNginx() {
    sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/wordpress
    sudo dd if=./cfg/WPNginx of=/etc/nginx/sites-available/wordpress
    sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/ 2>/dev/null

    
}

function installWP(){

    sudo tar xzfv /var/www/html/latest.tar.gz 1>/dev/null

    sudo cd /var/www/html/wordpress/public_html
    sudo mv /var/www/html/wordpress/public_html/wp-config-sample.php /var/www/html/wordpress/public_html/wp-config.php

    define('DB_NAME', 'wordpress_db');
    define('DB_USER', 'wpuser');
    define('DB_PASSWORD', 'Passw0rd!');
}

function policys() {
    sudo find /var/log/nginx/ -type d -exec chmod 755 {} \;
    sudo find /var/log/nginx/ -type f -exec chmod 644 {} \;
    sudo find /var/log/mysql/ -type d -exec chmod 755 {} \;
    sudo find /var/log/mysql/ -type f -exec chmod 644 {} \;
    sudo chown www-data:www-data -R /etc/nginx
    sudo chown www-data:www-data -R /var/log/nginx
    sudo chown www-data:www-data -R /var/www/html
    
    sudo systemctl enable nginx
    sudo systemctl reload nginx

    
}

function installFilebeat() {
    
    wget -qO -https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add
    echo deb https://artifacts.elastic.co/packages/7.x/apt stable main | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
    sudo apt-get update && sudo apt-get install -y filebeat

    sudo filebeat modules enable nginx
    sudo filebeat modules enable mysql

    sudo dd if=cfg/filebeat.yml of=/etc/filebeat/filebeat.yml

    sudo systemctl enable filebeat
    sudo systemctl start filebeat
}

function main() {
    updateUbuntu
    installNgnix
    installMariaDB
    installPHP

    WPDatabase
    ConfigNginx
    installWP
    policys
    installFilebeat
}
main
