#!/bin/bash
function is_dns_working_in_container()
{
  docker container exec printerbox_device_sortkaffe_1 nslookup google.com  > /dev/null 2>&1
  return $?
}

function is_network_running()
{
  ping google.com > /dev/null 2>&1
}

while true; do
  sleep 10

  if ! is_network_running; then
    continue;
  fi

  if is_dns_working_in_container ; then
    continue;
  fi

  dnslookup -debug google.com

  docker-compose down
  systemctl restart docker
  docker-compose up -d
done

