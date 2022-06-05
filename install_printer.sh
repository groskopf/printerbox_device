#!/bin/bash
set -x

read -p "WARNING: Connect and turn on printer before coninueing. Hit enter!"

docker_image_name=printerbox_cupsd
docker_image_version=v2
docker_image=$docker_image_name:$docker_image_version
docker_container=printerbox_cupsd_install

docker create --name $docker_container --rm=false --privileged -v printer_labels:${pwd}/labels -v /dev:/dev -v /var/run/dbus:/var/run/dbus -v $(pwd):$(pwd) -w $(pwd) -i $docker_image bash
docker start $docker_container
docker exec $docker_container /scripts/create_cups_admin.sh
docker exec $docker_container /scripts/install_printer.sh
docker exec $docker_container /scripts/install_labels.sh
docker commit $docker_container $docker_image
docker stop $docker_container 
docker rm $docker_container 
