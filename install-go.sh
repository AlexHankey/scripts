#!/bin/bash

# ========================
# VPS Setup Script for Nginx + Self-Signed SSL + Firewall
# ========================

set -e

# CONFIG
VPS_IP="194.164.126.194"
WEB_ROOT="/var/www/html"
SSL_CERT="/etc/ssl/certs/selfsigned.crt"
SSL_KEY="/etc/ssl/private/selfsigned.key"
NGINX_DEFAULT_CONF="/etc/nginx/sites-available/default"

echo "🔄 Updating package lists..."
sudo apt update

echo "📦 Installing Nginx (if not installed)..."
sudo apt install -y nginx

echo "🛡️ Installing UFW firewall (if not installed)..."
sudo apt install -y ufw

echo "🛡️ Configuring UFW rules..."
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

if [[ ! -f "$SSL_CERT" ]] || [[ ! -f "$SSL_KEY" ]]; then
  echo "🔐 Generating self-signed SSL certificate for IP $VPS_IP..."
  sudo openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$SSL_KEY" \
    -out "$SSL_CERT" \
    -subj "/CN=$VPS_IP"
else
  echo "🔐 Self-signed SSL certificate already exists, skipping generation."
fi

echo "🧹 Setting up Nginx configuration..."

sudo tee "$NGINX_DEFAULT_CONF" > /dev/null << EOF
# Redirect HTTP to HTTPS
server {
    listen 80 default_server;
    server_name _;

    return 301 https://\$host\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl default_server;
    server_name _;

    ssl_certificate $SSL_CERT;
    ssl_certificate_key $SSL_KEY;

    root $WEB_ROOT;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
}
EOF

echo "📁 Setting ownership and permissions for $WEB_ROOT..."
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo chmod -R 755 "$WEB_ROOT"

echo "🔄 Testing Nginx configuration..."
sudo nginx -t

echo "♻️ Reloading Nginx to apply changes..."
sudo systemctl reload nginx

echo ""
echo "✅ Setup complete!"
echo "👉 Visit your website at: https://$VPS_IP (note: browser will warn about self-signed cert)"
echo ""
echo "To replace the self-signed cert with a trusted one, consider using a domain name and Let's Encrypt."
