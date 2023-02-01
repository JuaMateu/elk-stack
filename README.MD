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

## Paso 2
## Instalación host del stack ELK

Ver [Documentacion para la instalacion y configuracion del Servidor con stack ELK](./src/4-instalacionELK.md)

los pasos a seguir serán automatizados en un script de instalación y configuracion del servidor


- Script para la automatización de la instalación, aplicando de los conceptos
explicados en la teoría, como independencia de filesystems para la ubicación de los datos de Elasticsearch o la BBDD, uso de LVM, uso del gestor de paquetes.
- Evidencias de la obtención de eventos registrados en los logs de la aplicación en Kibana
- Análisis de rendimiento de los servidores con herramientas de CLI y/o Vector. ¿Alguno necesita más recursos o está sobredimensionado?
- Propuestas para mejorar la escalabilidad y disponibilidad (HA)
