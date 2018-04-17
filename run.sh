#!/bin/bash


nl=$'\n'


servers=()
IFS=',' read -ra ADDR <<< "$KUBE_MASTERS"
for i in "${ADDR[@]}"; do
  servers+=("server $i:6443;$nl")
done


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

if [[ $(uname -m) == 'aarch64' ]]; then
  # For some reason on multiarch alpine the pid location does not exist after apk add
  mkdir -p /run/nginx/
  # stream module is also dynamic, need to load it explicitly
  echo 'load_module /usr/lib/nginx/modules/ngx_stream_module.so;' | cat - /etc/nginx/nginx.conf > /tmp/nginx.conf && mv /tmp/nginx.conf /etc/nginx/nginx.conf
fi


# Start nginx
exec nginx -g 'daemon off;'
