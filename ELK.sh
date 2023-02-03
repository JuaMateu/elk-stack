#!/bin/bash

function updateUbuntu() {
    sudo apt-get update 
    sudo apt-get upgrade
}
function installNgnix() {
    sudo apt-get install -y nginx 
}
function InstallElasticsearch(){

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

    echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

    sudo apt update
    sudo apt update
    sudo systemctl start elasticsearch
    sudo systemctl enable elasticsearch
}
InstallKibana(){
    sudo apt install kibana
    sudo systemctl enable kibana
    sudo systemctl start kibana
    echo "kibanaadmin:`openssl passwd -apr1`" | sudo tee -a /etc/nginx/htpasswd.users
    printf "\033[32m ---- Configuring Kibana ---- \033[0m\n"
    admpwd="password"
    #touch /etc/nginx/htpasswd.users
    echo "---- configuring password for kibana nginx  for basic security ----\n"
    echo "admin:$(openssl passwd -apr1 $admpwd)" | tee -a /etc/nginx/.htpasswd.users
    touch /etc/nginx/sites-available/kibana
    echo "Isert server name for kibana"
    read $HOSTNAME
    echo "Isert ip of this server for kibana"
    read $HOSTNAME
    cat > /etc/nginx/sites-available/kibana <<\EOF
    server {
    listen 80;

    server_name $HOSTNAME;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF
    ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/
    mv /etc/nginx/sites-avaliable/default /tmp
    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com
    sudo systemctl restart nginx

    sudo ufw allow 'Nginx Full'

}

function installLogstash(){
    sudo apt install logstash
    sudo touch /etc/logstash/conf.d/02-beats-input.conf
    sudo cat > /etc/logstash/conf.d/02-beats-input.conf <<\EOF
input {
    beats {
        port => 5044
    }
}
EOF
    sudo touch /etc/logstash/conf.d/30-elasticsearch-output.conf
    sudo cat > /etc/logstash/conf.d/30-elasticsearch-output.conf <<\EOF
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    manage_template => false
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
EOF
    sudo systemctl start logstash
    sudo systemctl enable logstash
}


function main (){
updateUbuntu
installNgnix
InstallElasticsearch
InstallKibana
installLogstash
}
main