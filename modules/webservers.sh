#!/bin/bash

#############################################################################
# WEB SERVER MODULE
# Supports: Apache, Nginx, Caddy, FrankenPHP
#############################################################################

install_system_dependencies() {
    log_step "Installing system dependencies..."
    
    case $OS in
        ubuntu|debian)
            apt-get update -qq || error_exit "Failed to update package lists"
            apt-get install -y wget curl tar software-properties-common \
                apt-transport-https ca-certificates acl git unzip jq \
                || error_exit "Failed to install dependencies"
            ;;
        centos|rhel|fedora)
            yum install -y wget curl tar acl git unzip jq \
                || error_exit "Failed to install dependencies"
            ;;
    esac
    
    log_success "System dependencies installed"
}

select_and_install_webserver() {
    print_section "🌐 Web Server Selection"
    
    echo -e "${BOLD}Choose your web server:${NC}"
    echo ""
    
    print_box_start
    print_box_item "  ${GREEN}1)${NC} ${BOLD}Nginx${NC} ${GREEN}(Recommended)${NC}"
    print_box_item "     → High performance, battle-tested, great for production"
    print_box_item ""
    print_box_item "  ${GREEN}2)${NC} ${BOLD}Apache${NC}"
    print_box_item "     → Traditional, .htaccess support, flexible"
    print_box_item ""
    print_box_item "  ${GREEN}3)${NC} ${BOLD}Caddy${NC}"
    print_box_item "     → Modern, automatic HTTPS, simple configuration"
    print_box_item ""
    print_box_item "  ${GREEN}4)${NC} ${BOLD}FrankenPHP${NC}"
    print_box_item "     → Cutting-edge, native PHP server, HTTP/2 & HTTP/3"
    print_box_end
    echo ""
    
    get_input "Select web server [1-4]" "1" webserver_choice
    
    case $webserver_choice in
        1)
            WEB_SERVER="nginx"
            install_nginx
            ;;
        2)
            WEB_SERVER="apache"
            install_apache
            ;;
        3)
            WEB_SERVER="caddy"
            install_caddy
            ;;
        4)
            WEB_SERVER="frankenphp"
            install_frankenphp
            ;;
        *)
            log_warning "Invalid selection, defaulting to Nginx"
            WEB_SERVER="nginx"
            install_nginx
            ;;
    esac
}

#############################################################################
# NGINX INSTALLATION
#############################################################################

install_nginx() {
    log_step "Installing Nginx..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y nginx || error_exit "Failed to install Nginx"
            ;;
        centos|rhel|fedora)
            yum install -y nginx || error_exit "Failed to install Nginx"
            ;;
    esac
    
    systemctl enable nginx
    systemctl start nginx
    
    log_success "Nginx installed and started"
}

configure_nginx_laravel() {
    local site_name=$1
    local project_path=$2
    local domain=$3
    
    log_step "Configuring Nginx for Laravel..."
    
    # Create nginx configuration
    cat > "/etc/nginx/sites-available/${site_name}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    root ${project_path}/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
    
    # Enable site
    if [ ! -d "/etc/nginx/sites-enabled" ]; then
        mkdir -p /etc/nginx/sites-enabled
    fi
    
    ln -sf "/etc/nginx/sites-available/${site_name}" "/etc/nginx/sites-enabled/${site_name}"
    
    # Remove default site if it exists
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t || error_exit "Nginx configuration test failed"
    
    # Reload nginx
    systemctl reload nginx
    
    log_success "Nginx configured for Laravel"
}

#############################################################################
# APACHE INSTALLATION
#############################################################################

install_apache() {
    log_step "Installing Apache..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y apache2 || error_exit "Failed to install Apache"
            
            # Enable required modules
            a2enmod rewrite
            a2enmod headers
            a2enmod ssl
            ;;
        centos|rhel|fedora)
            yum install -y httpd || error_exit "Failed to install Apache"
            ;;
    esac
    
    systemctl enable apache2 2>/dev/null || systemctl enable httpd
    systemctl start apache2 2>/dev/null || systemctl start httpd
    
    log_success "Apache installed and started"
}

configure_apache_laravel() {
    local site_name=$1
    local project_path=$2
    local domain=$3
    
    log_step "Configuring Apache for Laravel..."
    
    # Create apache configuration
    cat > "/etc/apache2/sites-available/${site_name}.conf" <<EOF
<VirtualHost *:80>
    ServerName ${domain}
    ServerAdmin webmaster@${domain}
    DocumentRoot ${project_path}/public

    <Directory ${project_path}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${site_name}-error.log
    CustomLog \${APACHE_LOG_DIR}/${site_name}-access.log combined
</VirtualHost>
EOF
    
    # Enable site
    a2ensite "${site_name}.conf"
    
    # Disable default site
    a2dissite 000-default.conf 2>/dev/null || true
    
    # Test configuration
    apache2ctl configtest || error_exit "Apache configuration test failed"
    
    # Reload apache
    systemctl reload apache2
    
    log_success "Apache configured for Laravel"
}

#############################################################################
# CADDY INSTALLATION
#############################################################################

install_caddy() {
    log_step "Installing Caddy..."
    
    case $OS in
        ubuntu|debian)
            # Add Caddy repository
            apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
            apt-get update -qq
            apt-get install -y caddy || error_exit "Failed to install Caddy"
            ;;
        centos|rhel|fedora)
            yum install -y yum-plugin-copr
            yum copr enable @caddy/caddy -y
            yum install -y caddy || error_exit "Failed to install Caddy"
            ;;
    esac
    
    systemctl enable caddy
    systemctl start caddy
    
    log_success "Caddy installed and started"
}

configure_caddy_laravel() {
    local site_name=$1
    local project_path=$2
    local domain=$3
    
    log_step "Configuring Caddy for Laravel..."
    
    # Create Caddyfile
    cat > "/etc/caddy/Caddyfile" <<EOF
${domain} {
    root * ${project_path}/public
    
    encode gzip
    
    php_fastcgi unix//var/run/php/php${PHP_VERSION}-fpm.sock
    
    file_server
    
    log {
        output file /var/log/caddy/${site_name}.log
    }
}
EOF
    
    # Create log directory
    mkdir -p /var/log/caddy
    chown caddy:caddy /var/log/caddy
    
    # Reload caddy
    systemctl reload caddy
    
    log_success "Caddy configured for Laravel (Automatic HTTPS enabled)"
}

#############################################################################
# FRANKENPHP INSTALLATION
#############################################################################

install_frankenphp() {
    log_step "Installing FrankenPHP..."
    
    # Download FrankenPHP
    local frankenphp_version="1.0.3"
    
    cd /tmp
    wget -q "https://github.com/dunglas/frankenphp/releases/download/v${frankenphp_version}/frankenphp-linux-x86_64" \
        -O frankenphp || error_exit "Failed to download FrankenPHP"
    
    chmod +x frankenphp
    mv frankenphp /usr/local/bin/
    
    log_success "FrankenPHP installed"
}

configure_frankenphp_laravel() {
    local site_name=$1
    local project_path=$2
    local domain=$3
    
    log_step "Configuring FrankenPHP for Laravel..."
    
    # Create systemd service for FrankenPHP
    cat > "/etc/systemd/system/frankenphp-${site_name}.service" <<EOF
[Unit]
Description=FrankenPHP Server for ${site_name}
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=${project_path}
ExecStart=/usr/local/bin/frankenphp php-server --listen :80 --root ${project_path}/public
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable "frankenphp-${site_name}"
    systemctl start "frankenphp-${site_name}"
    
    log_success "FrankenPHP configured for Laravel"
}

#############################################################################
# SSL/TLS CONFIGURATION
#############################################################################

setup_ssl_certificate() {
    local domain=$1
    
    if [ "$WEB_SERVER" = "caddy" ]; then
        log_info "Caddy handles SSL automatically, no action needed"
        return 0
    fi
    
    if ! confirm "Do you want to set up SSL/TLS with Let's Encrypt?"; then
        log_info "Skipping SSL setup"
        return 0
    fi
    
    log_step "Installing Certbot..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y certbot python3-certbot-nginx python3-certbot-apache
            ;;
        centos|rhel|fedora)
            yum install -y certbot python3-certbot-nginx python3-certbot-apache
            ;;
    esac
    
    case $WEB_SERVER in
        "nginx")
            certbot --nginx -d "$domain" --non-interactive --agree-tos --email "admin@${domain}" || log_warning "SSL setup failed"
            ;;
        "apache")
            certbot --apache -d "$domain" --non-interactive --agree-tos --email "admin@${domain}" || log_warning "SSL setup failed"
            ;;
    esac
    
    log_success "SSL certificate installed"
}

#############################################################################
# FIREWALL CONFIGURATION
#############################################################################

configure_firewall_webserver() {
    if ! confirm "Configure firewall to allow HTTP/HTTPS traffic?"; then
        log_info "Skipping firewall configuration"
        return 0
    fi
    
    log_step "Configuring firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp comment 'HTTP' 2>/dev/null || true
        ufw allow 443/tcp comment 'HTTPS' 2>/dev/null || true
        ufw --force enable 2>/dev/null || true
        log_success "UFW rules added"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
        log_success "Firewalld rules added"
    else
        log_warning "No supported firewall detected"
    fi
}
