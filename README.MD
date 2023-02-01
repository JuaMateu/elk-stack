# Proyecto de instalaccion de stack ELK y servidor WordPress

Este proyecto se realizó en una infraestructura virtual montada con VirtualBox.     

El sistema operativo utilizado es Ubuntu  

## Paso 1: Montar maquinas virtuales con VBox

Generamos 2 maquinas virtuales conectadas a una red NAT de forma que puedan comunicarse entre si, a la misma se le dio un rango 192.168.2.0/24
      
### infra y networking:
Para el proyecto usamos 2 servidores con las siguientes ip estaticas (  [__paso a paso en este link__](./src/staticip.md) ) 

    192.168.2.30 - Wordpress
    192.168.2.8  - ELK STACK
       
Para poder acceder vía SSH a estos servers desde el Host configuramos port forwarding en la VBOX:

![port forwarding virtual Box](./src/1-portforwarding.JPG)

## A - Diagrama de la infraestructura implementada

![Infraestructura](./src/2-DiagramaInfra.jpg)  

## Paso 1 
## instalacion y configuracion del servidor Wordpress 

Ver [Documentacion para la instalacion y configuracion del Servidor Wordpress](./src/3-instalacionWP.md)

los pasos a seguir serán automatizados en un script de instalación y configuracion del servidor

# INSTALACION ELK

Ver [Documentacion para la instalacion y configuracion del Servidor con stack ELK](./src/3-instalacionWP.md)

los pasos a seguir serán automatizados en un script de instalación y configuracion del servidor


#!/bin/bash

#For Installation
ELK_GPG="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
ELK_REPO="deb https://artifacts.elastic.co/packages/7.x/apt stable main"


#For Config
ELASTIC_CFG_PATH="/etc/elasticsearch/elasticsearch.yml"
KIB_PSSWD="kibana_admin:password"
NGINX_VH_PATH="/etc/nginx/sites-available/kibana"
LOGSTASH_FB_PATH="/etc/logstash/conf.d/fb_logstash.conf"
KIB_CFG_PATH="/etc/kibana/kibana.yml"




function installPackages() {
    sudo apt-get install -y wget apt-transport-https
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list
    sudo apt update && sudo apt-get install -y elasticsearch kibana logstash nginx
}


function printCredentials() {
    echo -e " In your local machine. You will have to edit /etc/hosts\n Replace the IPs and paste them:\n"
    echo " IP-FROM-VM-WORDPRESS mysite.com"
    echo " IP-FROM-VM-ELK kibana.com"
    sleep 3
    echo -e "\n *Credentials (user:password)*"
    echo -e " kibana_admin:password <-- This is for autentication in your website 'kibana.com'\n"
    exit
}


function setUpConfig() {
    echo -e '\n# --> Elasticsearch'
    echo '#----Config----'
    
    sudo sed -i 's/#http.port: 9200/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml 2>/dev/null
    sudo grep 'indices.memory.index_buffer_size: 20%' /etc/elasticsearch/elasticsearch.yml 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo "indices.memory.index_buffer_size: 20%"| sudo tee -a /etc/elasticsearch/elasticsearch.yml
    fi

    echo -e '\n#----Service----'
    
    sudo systemctl enable elasticsearch
    sudo systemctl daemon-reload
    sudo systemctl start elasticsearch

    echo -e '\n# --> Kibana'
    echo '#----Config files----'
    sudo sed -i 's/#server.host:"localhost"/server.host:"localhost"/g' /etc/kibana/kibana.yml 2>/dev/null
    sudo sed -i 's/#server.port:5601/server.port:5601/g' /etc/kibana/kibana.yml 2>/dev/null
    echo 'Setting server.host to: "localhost" ...'
    echo 'Setting server.port to: 5601 ...'

    echo -e '\n#----Service----'
    
    sudo systemctl enable kibana
    sudo systemctl daemon-reload
    sudo systemctl start kibana
    
    echo -e '\n# --> Nginx'
    echo -e '#----Credentials----'

    grep "kibana_admin" /etc/nginx/htpasswd.users
    if [ $? -ne 0 ]; then
        echo "kibana_admin:`openssl passwd passwd1`"|sudo tee /etc/nginx/htpasswd.users
    fi

    echo -e '\n#----Reverse Proxy----'
    
    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/kibana
    sudo dd if=cfg/kibana of=/etc/nginx/sites-available/kibana
    sudo ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/ 2>/dev/null

    sudo find /var/log/nginx/ -type d -exec chmod 755 {} \;
    sudo find /etc/nginx/ -type d -exec chmod 755 {} \;
    sudo find /var/log/nginx/ -type f -exec chmod 644 {} \;
    sudo find /etc/nginx/ -type f -exec chmod 644 {} \;

    sudo chown www-data:www-data -R /etc/nginx
    sudo chown www-data:www-data -R /var/log/nginx

    grep 'kibana.com' /etc/hosts
    if [ $? -ne 0 ]; then
        echo "127.0.0.1     kibana.com" | sudo tee -a /etc/hosts
    fi

    echo -e '\n#----Firewall----'
    
    sudo ufw allow 'Nginx Full'

    echo -e '\n#----Service----'
    
    sudo nginx -s reload
    sudo systemctl enable nginx
    sudo systemctl daemon-reload
    sudo systemctl restart nginx

    echo -e '\n# --> Logstash'
    echo '#----Config----'
    echo 'Setting .conf file /etc/logstash/conf.d/fb_logstash.conf'
    sudo cp cfg/fb_logstash.conf /etc/logstash/conf.d/fb_logstash.conf
    
    echo -e '\n#----Service----'
    
    sudo systemctl enable logstash
    sudo systemctl daemon-reload
    sudo systemctl start logstash
    sudo systemctl restart logstash
    
    echo -e '\n # --> INFO'
    echo -e '\n All the network config is set to: "localhost".'
    echo -e ' All the logs are going to the same index in logstash.\n'
    sleep 3
}




function main() {
    installPackages
    setUpConfig
    printCredentials
}
main