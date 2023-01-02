#!/bin/bash

DOMAIN="$1"
NAME="$2"
PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PORT="443" # caddy uses port 443 for SSL , so changing that cause ERROR:ssl_client_socket_impl.cc(982)] handshake failed;
CHECKSERVICE=$(docker ps -a | grep naive | cut -d" " -f 1)

# Permission check

red='\033[0;31m'
yellow='\033[0;33m'
bblue='\033[0;34m'
plain='\033[0m'
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}


permissioncheck(){
ROOT_UID=0
if [[ $UID == $ROOT_UID ]]; then true ; else red "You Must be the ROOT to Perfom this Task"  ; fi
}

if [ -z "$DOMAIN" ]; then
    red "DOMAIN variable not set."
    exit 1
fi

if [ -z "$NAME" ]; then
    NAME="Naive"
fi

if [ -z "$PASSWORD" ]; then
    red "ERR PASSWORD variable not set."
    exit 1
fi

if [ -z "$PORT" ]; then
    red "ERR PORT variable not set."
    exit 1
fi

permissioncheck


# Install docker

if [[ -f '/usr/bin/docker' ]] || [[ -f '/usr/local/bin/docker' ]]
then
    true
else
    curl https://get.docker.com | sh
fi


STATUS="$(systemctl is-active docker.service)"

if [ "${STATUS}" = "active" ]; then
    green "Docker service are already enabled."
else 
    systemctl enable --now containerd
    systemctl enable --now docker
    sleep 3
fi

if [ "$CHECKSERVICE" ]; then
    yellow "Naive is already installed"
    blue "Docker container ID : $CHECKSERVICE"
    exit 1
fi

# Make configuration

mkdir -p /etc/naiveproxy /var/www/html /var/log/caddy
tee /etc/naiveproxy/config.json <<EOF
{
  "admin": {"disabled": true},
  "logging": {
    "sink": {"writer": {"output": "discard"}},
    "logs": {"default": {"writer": {"output": "discard"}}}
  },
  "apps": {
    "http": {
      "servers": {
        "srv0": {
          "listen": [":$PORT"],
          "routes": [{
            "handle": [{
              "handler": "forward_proxy",
              "hide_ip": true,
              "hide_via": true,
              "auth_user_deprecated": "$NAME",
              "auth_pass_deprecated": "$PASSWORD",
              "probe_resistance": {"domain": ""}
            }]
          }, {
            "match": [{"host": ["$DOMAIN", "www.$DOMAIN"]}],
            "handle": [{
              "handler": "file_server",
              "root": "/var/www/html"
            }],
            "terminal": true
          }],
          "tls_connection_policies": [{
            "match": {"sni": ["$DOMAIN", "www.$DOMAIN"]}
          }]
        }
      }
    },
    "tls": {
      "automation": {
        "policies": [{
          "subjects": ["$DOMAIN", "www.$DOMAIN"]
        }]
      }
    }
  }
}
EOF


# Pull pocat/naiveproxy and run it with docker

run(){
docker pull pocat/naiveproxy

docker run --network host --name naiveproxy \
 -v /etc/naiveproxy:/etc/naiveproxy \
 -v /var/www/html:/var/www/html \
 -v /var/log/caddy:/var/log/caddy \
 -e PATH=/etc/naiveproxy/config.json \
 --restart=always \
 -d pocat/naiveproxy
}

run

# Create client configuration

client(){
green "CLIENT config : "

tee naiveclient.json <<CLIENT
{
"listen": "socks://127.0.0.1:1080",
"proxy": "https://$NAME:$PASSWORD@$DOMAIN:$PORT"
}
CLIENT
}

# Create link

link(){
green "Link : "
cat << LINK
naive+https://$NAME:$PASSWORD@$DOMAIN:$PORT
LINK
}

client
link

echo "Done."
