# Instalación Servidor Wordpress con Nginx y filebeat

### A. Actualizar Ubuntu
empezamos actualizando la informacion de los paquetes:

    # apt-get update 
    # apt-get upgrade
### B. instalar NGINX
instalar nginx que será utilizado como proxy reverso y SQL

    sudo apt-get install -y nginx 
### C. instalar MariaDB

    sudo apt-get install mariadb-server 
    sudo systemctl enable mariadb.service

Configurar usuario root para mariaDB

    mysql -u root -p
    MariaDB [(none)]> use mysql;
    MariaDB [mysql]> update user SET PASSWORD=PASSWORD("Passw0rd!") WHERE USER='root';

### D. instalar PHP


    # apt-get install php7.2 php7.2-cli php7.2-fpm php7.2-mysql php7.2-json php7.2-opcache php7.2-mbstring php7.2-xml php7.2-gd php7.2-curl

Además de instalar php7.2, el comando apt-get anterior también instala algunos otros paquetes, como MySQL, XML, Curl y GD, y se asegura de que su sitio de WordPress pueda interactuar con la base de datos, soporte para XMLRPC y también para recortar y cambiar el tamaño de las imágenes automáticamente. Además, NGINX necesita el paquete php-fpm (Administrador de procesos rápido) para procesar las páginas PHP de su instalación de WordPress. Recuerde que el servicio FPM se ejecutará automáticamente una vez que finalice la instalación de PHP.    


### E. Crear WordPress Database

    $ mysql -u root -p
    Enter password:

    MariaDB [mysql]> CREATE DATABASE wordpress_db;
    Query OK, 1 row affected (0.00 sec)

    MariaDB [mysql]> GRANT ALL ON wordpress_db.* TO 'wpuser'@'localhost' IDENTIFIED BY  'Passw0rd!' WITH GRANT OPTION;
    Query OK, 0 rows affected (0.00 sec)

    MariaDB [mysql]> FLUSH PRIVILEGES;
    Query OK, 0 rows affected (0.00 sec)

    MariaDB [mysql]> exit

### F. Configurar NGINX para WordPress

Modificar el archivo de configuracion de nginx con un editor de texto y dejar el siguiente contenido

    sudo vim /etc/nginx/site-available/default 
```
server {
    listen 80;
    listen [::]:80;

    root /var/www/html/wordpress;

    index index.php index.html index.htm index.nginx-debian.html;

    server_name mysite.com;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;

        # With php-fpm (or other unix sockets):
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        # With php-cgi (or other tcp sockets):

    }

    location ~ /\.ht {
        deny all;
    }
}

```
cambiar permisos de las carpetas de logs    

    sudo find /var/log/nginx/ -type d -exec chmod 755 {} \;
    sudo find /var/log/nginx/ -type f -exec chmod 644 {} \;
    sudo find /var/log/mysql/ -type d -exec chmod 755 {} \;
    sudo find /var/log/mysql/ -type f -exec chmod 644 {} \;

cambiar usuarios y grupos de las siguientes carpetas

    sudo chown www-data:www-data -R /etc/nginx
    sudo chown www-data:www-data -R /var/log/nginx
    sudo chown www-data:www-data -R /var/www/html

Reiniciar y habilitar servicio de nginx

    sudo systemctl reload nginx
    sudo systemctl enable nginx

### G. Descargar y configurar WordPress

Nos ubicamos en la carpeta /var/www/html/, descargamos wordpress y luego lo descomprimimos

    sudo cd /var/www/html/
    sudo wget https://wordpress.org/latest.tar.gz
    sudo tar xzfv latest.tar.gz 1>/dev/null

nos ubicamos en la carpeta donde se encuentran los contenidos web 

    cd /var/www/html/wordpress/public_html
a

    sudo mv wp-config-sample.php wp-config.php
    vim wp-config.php
a

    define('DB_NAME', 'wordpress_db');
    define('DB_USER', 'wpuser');
    define('DB_PASSWORD', 'Passw0rd!');

Para proteger su sitio de WordPress, agregue la clave de seguridad en el archivo de configuración de WordPress anterior justo después de las opciones de configuración de la base de datos generándolo a través de  [este enlace](https://api.wordpress.org/secret-key/1.1/salt/).



### H. instalar WordPress

A continuacion se debe ingresar al sitio para instalar Wordpress



Instalar php, PHP es necesario para que WordPress se comunique con la base de datos MySQL y nginx  pueda servir el contenido de php.

    sudo apt-get install -y php php8.1 php8.1-fpm php8.1-gd php8.1-curl php8.1-http php8.1-xml php8.1-bcmath php8.1-mysql

instalacion de wordpress

    
    cd /var/www/html/
    wget https://wordpress.org/latest.tar.gz
    tar xzfv latest.tar.gz 1>/dev/null
    sudo mv wordpress/ $WP_PATH

### I. instalar filebeat

    wget -qO -https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add
    echo deb https://artifacts.elastic.co/packages/7.x/apt stable main | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
    sudo apt-get update && sudo apt-get install -y filebeat

    sudo filebeat modules enable nginx
    sudo filebeat modules enable mysql


