# Instalación Servidor con stack ELK

### requisitos previos

Se probó la configuracion en Ubuntu 20.04 LTS


## Pasos a seguir para la instalación y configuracion del servidor ELK

1. [Instalar y configurar Elasticsearch](#paso-1)
2. [Instalar y configurar el panel de Kibana](#paso-2)
3. [Instalar y configurar Logstash](#paso-3)
4. [Instalar y configurar Filebeat](#paso-4)
5. [Explorar los paneles de Kibana](#paso-5)


## Paso 1: 
### Instalar y configurar Elasticsearch

Los componentes de Elastic Stack no están disponibles en los repositorios de paquetes predeterminados de Ubuntu. Sin embargo, pueden instalarse con APT una vez que agregue la lista de fuentes de paquetes de Elastic.

Para comenzar, ejecute el siguiente comando a fin de importar la clave de GPG pública de Elasticsearch en APT:

    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

    echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

    sudo apt update
    sudo apt update

A continuación, inicie el servicio de Elasticsearch con systemctl:

    sudo systemctl start elasticsearch
Luego, ejecute el siguiente comando para permitir que Elasticsearch se cargue cada vez que su servidor se inicie:

    sudo systemctl enable elasticsearch

### Paso 2: 
##  Instalar y configurar el panel de Kibana

Puede instalar los componentes restantes de Elastic Stack usando apt:

    sudo apt install kibana
A continuación, habilite e inicie el servicio de Kibana:

    sudo systemctl enable kibana
    sudo systemctl start kibana


Con el siguiente comando se crearán el usuario y la contraseña administrativa de Kibana, y se almacenarán en el archivo htpasswd.users. Configurará Nginx para que requiera este nombre de usuario y contraseña, y lea este archivo de manera momentánea:

    echo "kibanaadmin:`openssl passwd -apr1`" | sudo tee -a /etc/nginx/htpasswd.users

Introduzca y confirme una contraseña cuando se le solicite. Recuerde este dato de inicio de sesión o tome nota de él, ya que lo necesitará para acceder a la interfaz web de Kibana.

    sudo nano /etc/nginx/sites-available/example.com

Añada el siguiente bloque de código al archivo y asegúrese de actualizar example.com para que coincida con el FQDN o la dirección IP pública de su servidor. Con este código, se configura Nginx para dirigir el tráfico HTTP de su servidor a la aplicación de Kibana, que escucha en localhost:5601. También se configura Nginx para leer el archivo htpasswd.users y requerir la autenticación básica.

/etc/nginx/sites-available/example.com

```
server {
    listen 80;

    server_name example.com;

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
```

Cuando termine, guarde y cierre el archivo.

A continuación, habilite la nueva configuración creando un enlace simbólico al directorio sites-enabled. Si ya creó un archivo de bloque de servidor con el mismo nombre en el requisito previo de Nginx, no necesitará ejecutar este comando:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com
A continuación, compruebe que no haya errores de sintaxis en la configuración:

    sudo nginx -t
Una vez que vea syntax is ok en el resultado, reinicie el servicio de Nginx:

    sudo systemctl restart nginx

    sudo ufw allow 'Nginx Full'

    sudo ufw delete allow 'Nginx HTTP'

Ahora que el panel de Kibana está configurado, instalaremos el siguiente componente: Logstash.

## Paso 3:
### Instalar y configurar Logstash


Instale Logstash con este comando:

    sudo apt install logstash

Cree un archivo de configuración llamado 
02-beats-input.conf en el que establecerá su entrada de Filebeat:

    sudo nano /etc/logstash/conf.d/02-beats-input.conf

Introduzca la siguiente configuración de input. Con esto, se especifica una entrada de beats que escuchará en el puerto TCP 5044.

```
/etc/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
  }
}
```

Por último, cree un archivo de configuración llamado 30-elasticsearch-output.conf:

    sudo nano /etc/logstash/conf.d/30-elasticsearch-output.conf

Introduzca la siguiente configuración de output. 

```
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    manage_template => false
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
```
Guarde y cierre el archivo.

Si desea añadir filtros para otras aplicaciones que utilizan la entrada de Filebeat, asegúrese de dar nombres a los archivos de modo que estén ordenados entre la configuración de entrada y salida, lo que significa que los nombres de archivo deben comenzar con un número de dos dígitos entre 02 y 30.

Pruebe su configuración de Logstash con el siguiente comando:

    sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t

Si no hay errores de sintaxis, en su resultado verá Configuration OK después de unos segundos.

Si su prueba de configuración tiene éxito, inicie y habilite Logstash para implementar los cambios de configuración:

    sudo systemctl start logstash
    sudo systemctl enable logstash

## Paso 4: 
### Instalar y configurar Filebeat

Instale Filebeat usando apt:

    sudo apt install filebeat
A continuación, configure Filebeat para establecer conexión con Logstash. Aquí, modificaremos el archivo de configuración de ejemplo que viene con Filebeat.

Abra el archivo de configuración de Filebeat:

    sudo nano /etc/filebeat/filebeat.yml

 Para hacerlo, encuentre la sección output.elasticsearch y comente las siguientes líneas anteponiéndoles “#”:

    /etc/filebeat/filebeat.yml
```
#output.elasticsearch:
  # Array of hosts to connect to.
  #hosts: ["localhost:9200"]
```
A continuación, configure la sección output.logstash. :

    /etc/filebeat/filebeat.yml
```
output.logstash:
  # The Logstash hosts
  hosts: ["localhost:5044"]
```
Guarde y cierre el archivo.


    sudo filebeat modules enable system

Para cargar la plantilla en ElasticSearch, utilice el siguiente comando:

    sudo filebeat setup --template -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'

Ahora podrá iniciar y habilitar Filebeat:

sudo systemctl start filebeat
sudo systemctl enable filebeat  

## Paso 5: 
### Explorar los paneles de Kibana

Ya solo queda ingresar a Kibana y configurar los paneles a través de la consola para ver los logs recibidos.

En este punto deberíamos ver logs recibidos desde nuestro servidor de Wordpress y desde el mismo systema donde tenemos instalado el ELK stack