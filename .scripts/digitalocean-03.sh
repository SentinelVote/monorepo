#!/bin/sh
# shellcheck shell=dash

#
# This script should be run as the unprivileged user.
#

# GUIDE:
#
# SSH into the user with tmux, with two tabs (split horizontally):
#   ssh unprivileged@$sentinelvote -t "tmux new-session -A -s main"
#
# Split the tabs either,
# horizontally: Ctrl+B followed by " (that's a double-quote).
# vertically:   Ctrl+B followed by % (percent).
#

# TODO: rest of the guide.

# ---------------------------------------------------------------------
# Nginx with HTTP

DOMAIN="service.sentinelvote.tech"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y nginx

# We don't need this because we're going to use HTTPS.
sudo ufw allow 'Nginx HTTP'
sudo systemctl enable --now nginx
sudo mkdir -p "/var/www/$DOMAIN/html"
sudo chown -R "www-data:www-data" /var/www/$DOMAIN/html
sudo chmod -R 755 /var/www/$DOMAIN

# Add the backend api's /public/index.html file
BACKEND_INDEX=~/backend/public/index.html
sudo cp "$BACKEND_INDEX" "/var/www/$DOMAIN/html/index.html"
sudo chmod 666 "/var/www/$DOMAIN/html/index.html"

cat <<EOF | sudo tee /etc/nginx/sites-available/"$DOMAIN"
server {
        listen 80;
        listen [::]:80;

        root /var/www/$DOMAIN/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $DOMAIN www.$DOMAIN;

        location / {
                try_files \$uri \$uri/ =404;
        }
}
EOF
sudo ln -s /etc/nginx/sites-available/"$DOMAIN" /etc/nginx/sites-enabled/
sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default.bak || true

# Find 'server_names_hash_bucket_size 64;' and uncomment it.
sudo sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' /etc/nginx/nginx.conf || true

# ---------------------------------------------------------------------
# Nginx with HTTPS (Certbot)

sudo snap install core; sudo snap refresh core
DEBIAN_FRONTEND=noninteractive sudo apt-get remove -y certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'

sudo certbot --nginx -d "$DOMAIN" <<EOF
admin@sentinelvote.tech
Y
Y
EOF

# ---------------------------------------------------------------------
# Reverse proxy ports 8080 and 8801 to 80 and 443
