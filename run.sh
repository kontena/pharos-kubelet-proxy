#!/bin/bash


nl=$'\n'


servers=()
IFS=',' read -ra ADDR <<< "$KUBE_MASTERS"
for i in "${ADDR[@]}"; do
  #echo "i:$i"
  servers+=("server $i:6443;$nl")
done

#servers=$(echo -p ${servers[*]})

cat >/etc/nginx/nginx.conf <<EOF
error_log stderr notice;

worker_processes auto;
events {
  multi_accept on;
  use epoll;
  worker_connections 1024;
}

stream {
        upstream kube_apiserver {
            least_conn;
            ${servers[*]}
        }

        server {
            listen        6443;
            proxy_pass    kube_apiserver;
            proxy_timeout 10m;
            proxy_connect_timeout 1s;

        }

}

EOF


# Start nginx
nginx -g 'daemon off;'
