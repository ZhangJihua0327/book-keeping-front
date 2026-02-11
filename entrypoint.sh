#!/bin/sh

# Set up SSL directory
mkdir -p /etc/nginx/ssl
mkdir -p /var/www/certbot

# Domains
DOMAIN_FRONT="bookeeper.lollipopzzz.cn"
DOMAIN_BACK="book-keeping-backend.lollipopzzz.cn"
EMAIL="admin@lollipopzzz.cn"

# Function to link certs
link_certs() {
    dom=$1
    prefix=$2
    le_path="/etc/letsencrypt/live/$dom"
    
    if [ -f "$le_path/fullchain.pem" ]; then
        echo "Found Let's Encrypt certificate for $dom"
        ln -sf "$le_path/fullchain.pem" "/etc/nginx/ssl/${prefix}_cert.pem"
        ln -sf "$le_path/privkey.pem" "/etc/nginx/ssl/${prefix}_key.pem"
    else
        echo "No Let's Encrypt certificate for $dom. Using dummy."
        if [ ! -f "/etc/nginx/ssl/${prefix}_dummy_cert.pem" ]; then
            echo "Generating dummy certificate for $dom..."
            openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
                -keyout "/etc/nginx/ssl/${prefix}_dummy_key.pem" \
                -out "/etc/nginx/ssl/${prefix}_dummy_cert.pem" \
                -subj "/CN=$dom"
        fi
        ln -sf "/etc/nginx/ssl/${prefix}_dummy_cert.pem" "/etc/nginx/ssl/${prefix}_cert.pem"
        ln -sf "/etc/nginx/ssl/${prefix}_dummy_key.pem" "/etc/nginx/ssl/${prefix}_key.pem"
    fi
}

link_certs "$DOMAIN_FRONT" "frontend"
link_certs "$DOMAIN_BACK" "backend"

# Check if Nginx is already running
if pgrep nginx > /dev/null; then
    echo "Nginx is already running."
else
    echo "Starting Nginx..."
    nginx -g "daemon off;" &
    NGINX_PID=$!
fi

# Wait for Nginx to start
sleep 5

get_cert() {
    dom=$1
    prefix=$2
    if [ ! -f "/etc/letsencrypt/live/$dom/fullchain.pem" ]; then
        echo "Requesting certificate for $dom..."
        certbot certonly --webroot -w /var/www/certbot \
            -d "$dom" \
            --email "$EMAIL" --agree-tos --no-eff-email --non-interactive
            
        if [ $? -eq 0 ]; then
             echo "Certificate obtained for $dom!"
             # Re-link
             link_certs "$dom" "$prefix"
             echo "Reloading Nginx..."
             nginx -s reload
        else
             echo "Failed to obtain certificate for $dom. Check DNS and port 80 connectivity."
        fi
    fi
}

# Run Certbot logic in background
(
    sleep 10
    get_cert "$DOMAIN_FRONT" "frontend"
    get_cert "$DOMAIN_BACK" "backend"
    
    # Auto-renew loop
    while :; do
        sleep 12h
        echo "Checking for renewal..."
        certbot renew --webroot -w /var/www/certbot --deploy-hook "nginx -s reload"
    done
) &

# Keep the container running
wait $NGINX_PID
