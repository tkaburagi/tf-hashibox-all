#!/usr/bin/env bash
set -e

echo "--> Installing nodejs and nginx"
# wetty is a terminal over browser project
sudo apt-get install -y nodejs-legacy npm nginx


echo "--> Installing Wetty web terminal"
git clone https://github.com/krishnasrinivas/wetty /opt/wetty
cd /opt/wetty
npm install -g wetty

echo "--> Configuring Nginx proxy for Wetty web terminal"
sudo tee /etc/nginx/nginx.conf > /dev/null <<"EOF"
user www-data;
worker_processes auto;
pid /run/nginx.pid;
events {
    worker_connections 768;
}
http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
    ssl_prefer_server_ciphers on;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
  server {
      listen 80 default_server;
      listen [::]:80 default_server;
      server_name _;
      location /wetty {
        proxy_pass http://127.0.0.1:3000/wetty;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 43200000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
      }
  }
}
EOF

echo "--> Enabling HTTPS"
cd /opt/wetty
sudo openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 30000 -nodes \-subj "/C=US/ST=California/L=SF/O=Training/CN=www.hashitraining.com"



echo "--> Create wetty service account"
sudo useradd wetty \
   --shell /bin/bash \
   --create-home
echo "wetty:${wetty_pw}" | sudo chpasswd
sudo tee /etc/sudoers.d/wetty > /dev/null <<"EOF"
wetty ALL=(ALL:ALL) ALL
EOF
sudo chmod 0440 /etc/sudoers.d/wetty
sudo usermod -a -G sudo wetty

echo "--> Installing systemd script for Wetty web terminal"
sudo tee /etc/systemd/system/wetty.service > /dev/null <<"SERVICE"
[Unit]
Description=Wetty Web Terminal
After=network.target

[Service]
User=wetty
Group=wetty

WorkingDirectory=/opt/wetty
ExecStart=/usr/local/bin/wetty -p 3000 --host 127.0.0.1 --sslkey /opt/wetty/key.pem --sslcert /opt/wetty/cert.pem

[Install]
WantedBy=multi-user.target
SERVICE

sudo chmod 0755 /etc/systemd/system/wetty.service

echo "--> Enable Nginx and Wetty web terminal services"
sudo systemctl daemon-reload
sudo systemctl enable wetty
sudo systemctl start wetty
sudo systemctl enable nginx
sudo systemctl restart nginx
