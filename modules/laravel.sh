#!/bin/bash

#############################################################################
# LARAVEL MODULE
# PHP Installation, Composer, Project Setup, Permissions
#############################################################################

select_and_install_php() {
    print_section "🐘 PHP Configuration"
    
    echo -e "${BOLD}Select PHP version:${NC}"
    echo ""
    
    print_box_start
    print_box_item "  ${GREEN}1)${NC} PHP 8.1 (LTS)"
    print_box_item "  ${GREEN}2)${NC} PHP 8.2"
    print_box_item "  ${GREEN}3)${NC} PHP 8.3 ${GREEN}(Recommended)${NC}"
    print_box_item "  ${GREEN}4)${NC} PHP 8.4 (Latest)"
    print_box_end
    echo ""
    
    get_input "Select PHP version [1-4]" "3" php_choice
    
    case $php_choice in
        1) PHP_VERSION="8.1" ;;
        2) PHP_VERSION="8.2" ;;
        3) PHP_VERSION="8.3" ;;
        4) PHP_VERSION="8.4" ;;
        *) 
            log_warning "Invalid selection, defaulting to PHP 8.3"
            PHP_VERSION="8.3"
            ;;
    esac
    
    install_php
}

install_php() {
    log_step "Installing PHP ${PHP_VERSION}..."
    
    # Determine database extension
    local db_extension="mysql"
    case $DATABASE_TYPE in
        "postgresql") db_extension="pgsql" ;;
        "mysql"|*) db_extension="mysql" ;;
    esac
    
    case $OS in
        ubuntu|debian)
            # Add PHP repository
            add-apt-repository -y ppa:ondrej/php
            apt-get update -qq
            
            # Install PHP and extensions
            apt-get install -y \
                "php${PHP_VERSION}" \
                "php${PHP_VERSION}-common" \
                "php${PHP_VERSION}-cli" \
                "php${PHP_VERSION}-fpm" \
                "php${PHP_VERSION}-${db_extension}" \
                "php${PHP_VERSION}-mbstring" \
                "php${PHP_VERSION}-xml" \
                "php${PHP_VERSION}-curl" \
                "php${PHP_VERSION}-zip" \
                "php${PHP_VERSION}-gd" \
                "php${PHP_VERSION}-intl" \
                "php${PHP_VERSION}-bcmath" \
                "php${PHP_VERSION}-soap" \
                "php${PHP_VERSION}-redis" \
                "php${PHP_VERSION}-imagick" \
                "php${PHP_VERSION}-opcache" \
                || error_exit "Failed to install PHP"
            
            # Enable and start PHP-FPM
            systemctl enable "php${PHP_VERSION}-fpm"
            systemctl start "php${PHP_VERSION}-fpm"
            ;;
            
        centos|rhel|fedora)
            yum install -y "php${PHP_VERSION}" "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-mysqlnd" \
                || error_exit "Failed to install PHP"
            
            systemctl enable "php${PHP_VERSION}-fpm"
            systemctl start "php${PHP_VERSION}-fpm"
            ;;
    esac
    
    log_success "PHP ${PHP_VERSION} installed"
    
    # Configure PHP
    configure_php
}

configure_php() {
    log_step "Configuring PHP for Laravel..."
    
    local php_ini="/etc/php/${PHP_VERSION}/fpm/php.ini"
    
    if [ ! -f "$php_ini" ]; then
        php_ini="/etc/php.ini"
    fi
    
    if [ -f "$php_ini" ]; then
        # Backup original
        cp "$php_ini" "${php_ini}.backup"
        
        # Update PHP settings for Laravel
        sed -i "s/^upload_max_filesize.*/upload_max_filesize = 50M/" "$php_ini"
        sed -i "s/^post_max_size.*/post_max_size = 50M/" "$php_ini"
        sed -i "s/^memory_limit.*/memory_limit = 512M/" "$php_ini"
        sed -i "s/^max_execution_time.*/max_execution_time = 300/" "$php_ini"
        
        # Enable OPcache for production
        if [ "$APP_ENV" = "production" ]; then
            sed -i "s/^;opcache.enable=.*/opcache.enable=1/" "$php_ini"
            sed -i "s/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/" "$php_ini"
            sed -i "s/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=20000/" "$php_ini"
        fi
        
        # Restart PHP-FPM
        systemctl restart "php${PHP_VERSION}-fpm"
        
        log_success "PHP configured for Laravel"
    else
        log_warning "PHP configuration file not found"
    fi
}

#############################################################################
# COMPOSER INSTALLATION
#############################################################################

install_composer_tool() {
    log_step "Installing Composer..."
    
    cd /tmp
    curl -sS https://getcomposer.org/installer -o composer-setup.php || error_exit "Failed to download Composer"
    
    # Verify installer
    HASH=$(curl -sS https://composer.github.io/installer.sig)
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); exit(1); } echo PHP_EOL;"
    
    # Install Composer globally
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer || error_exit "Failed to install Composer"
    rm composer-setup.php
    
    log_success "Composer installed: $(composer --version | head -n1)"
    
    # Configure Composer
    configure_composer
}

configure_composer() {
    log_step "Configuring Composer..."
    
    # Create composer directories
    mkdir -p /var/www/.composer
    mkdir -p /var/www/.cache/composer
    mkdir -p /var/www/.config/composer
    
    chown -R www-data:www-data /var/www/.composer
    chown -R www-data:www-data /var/www/.cache
    chown -R www-data:www-data /var/www/.config
    
    # Set global configurations
    sudo -u www-data composer config --global process-timeout 2000
    sudo -u www-data composer config --global sort-packages true
    sudo -u www-data composer config --global optimize-autoloader true
    
    log_success "Composer configured"
}

#############################################################################
# LARAVEL PROJECT SETUP
#############################################################################

setup_laravel_project() {
    print_section "📦 Laravel Project Setup"
    
    echo -e "${BOLD}Laravel Project Options:${NC}"
    echo ""
    
    print_box_start
    print_box_item "  ${GREEN}1)${NC} Clone from Git repository"
    print_box_item "  ${GREEN}2)${NC} Create new Laravel project"
    print_box_item "  ${GREEN}3)${NC} Use existing project (skip)"
    print_box_end
    echo ""
    
    get_input "Select option [1-3]" "1" project_choice
    
    case $project_choice in
        1)
            clone_laravel_from_git
            ;;
        2)
            create_new_laravel_project
            ;;
        3)
            configure_existing_laravel_project
            ;;
        *)
            log_warning "Invalid selection, defaulting to Git clone"
            clone_laravel_from_git
            ;;
    esac
    
    # Configure Laravel
    if [ -d "$LARAVEL_PATH" ]; then
        configure_laravel_application
    fi
}

clone_laravel_from_git() {
    log_step "Cloning Laravel project from Git..."
    
    echo ""
    get_input "Git repository URL" "" REPO_URL
    
    if [ -z "$REPO_URL" ]; then
        error_exit "Repository URL is required"
    fi
    
    # Extract repository name
    REPO_NAME=$(basename "$REPO_URL" .git)
    LARAVEL_PATH="/var/www/html/${REPO_NAME}"
    
    # Clone repository
    cd /var/www/html
    
    if [ -d "$LARAVEL_PATH" ]; then
        log_warning "Directory already exists: $LARAVEL_PATH"
        if confirm "Remove and re-clone?"; then
            rm -rf "$LARAVEL_PATH"
        else
            log_info "Using existing directory"
            return 0
        fi
    fi
    
    git clone "$REPO_URL" "$REPO_NAME" || error_exit "Failed to clone repository"
    
    log_success "Repository cloned to $LARAVEL_PATH"
}

create_new_laravel_project() {
    log_step "Creating new Laravel project..."
    
    echo ""
    get_input "Project name" "laravel-app" REPO_NAME
    
    LARAVEL_PATH="/var/www/html/${REPO_NAME}"
    
    if [ -d "$LARAVEL_PATH" ]; then
        error_exit "Directory already exists: $LARAVEL_PATH"
    fi
    
    cd /var/www/html
    composer create-project laravel/laravel "$REPO_NAME" || error_exit "Failed to create Laravel project"
    
    log_success "Laravel project created at $LARAVEL_PATH"
}

configure_existing_laravel_project() {
    log_step "Configuring existing Laravel project..."
    
    echo ""
    get_input "Full path to Laravel project" "/var/www/html/laravel" LARAVEL_PATH
    
    if [ ! -d "$LARAVEL_PATH" ]; then
        error_exit "Directory not found: $LARAVEL_PATH"
    fi
    
    if [ ! -f "$LARAVEL_PATH/artisan" ]; then
        error_exit "Not a valid Laravel project (artisan not found)"
    fi
    
    REPO_NAME=$(basename "$LARAVEL_PATH")
    
    log_success "Using existing project at $LARAVEL_PATH"
}

#############################################################################
# LARAVEL APPLICATION CONFIGURATION
#############################################################################

configure_laravel_application() {
    log_step "Configuring Laravel application..."
    
    cd "$LARAVEL_PATH" || error_exit "Failed to navigate to project directory"
    
    # Install dependencies if composer.json exists
    if [ -f "composer.json" ]; then
        log_step "Installing Composer dependencies..."
        sudo -u www-data composer install --optimize-autoloader --no-dev --no-interaction || log_warning "Composer install had issues"
    fi
    
    # Setup .env file
    setup_env_file
    
    # Generate application key
    log_step "Generating application key..."
    sudo -u www-data php artisan key:generate --force || log_warning "Failed to generate key"
    
    # Update database configuration
    if [ "$DATABASE_TYPE" != "none" ]; then
        update_laravel_env_database "$LARAVEL_PATH/.env"
    fi
    
    # Set permissions
    set_laravel_permissions
    
    # Run migrations
    if confirm "Run database migrations now?"; then
        sudo -u www-data php artisan migrate --force || log_warning "Migrations failed"
    fi
    
    # Clear and cache config
    clear_and_cache_laravel
    
    # Create storage link
    sudo -u www-data php artisan storage:link 2>/dev/null || log_info "Storage link already exists"
    
    # Configure web server
    configure_webserver_for_laravel
    
    log_success "Laravel application configured"
}

setup_env_file() {
    log_step "Setting up .env file..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_success "Created .env from .env.example"
        else
            create_basic_env_file
        fi
    else
        log_info ".env file already exists"
    fi
    
    # Get application details
    echo ""
    get_input "Application name" "Laravel" APP_NAME
    get_input "Application URL/Domain" "$(hostname -I | awk '{print $1}')" DOMAIN_NAME
    
    APP_URL="http://${DOMAIN_NAME}"
    
    # Update .env
    sed -i "s/^APP_NAME=.*/APP_NAME=\"${APP_NAME}\"/" .env || echo "APP_NAME=\"${APP_NAME}\"" >> .env
    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env || echo "APP_URL=${APP_URL}" >> .env
    sed -i "s/^APP_ENV=.*/APP_ENV=${APP_ENV}/" .env || echo "APP_ENV=${APP_ENV}" >> .env
    sed -i "s/^APP_DEBUG=.*/APP_DEBUG=${APP_DEBUG}/" .env || echo "APP_DEBUG=${APP_DEBUG}" >> .env
    
    chown www-data:www-data .env
    chmod 644 .env
}

create_basic_env_file() {
    log_step "Creating basic .env file..."
    
    cat > .env <<EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=info

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF
    
    log_success "Basic .env file created"
}

set_laravel_permissions() {
    log_step "Setting Laravel permissions..."
    
    # Set ownership
    chown -R www-data:www-data "$LARAVEL_PATH"
    
    # Set directory permissions
    find "$LARAVEL_PATH" -type d -exec chmod 755 {} \;
    
    # Set file permissions
    find "$LARAVEL_PATH" -type f -exec chmod 644 {} \;
    
    # Set executable for artisan
    chmod +x "$LARAVEL_PATH/artisan"
    
    # Set writable directories
    chmod -R 775 "$LARAVEL_PATH/storage"
    chmod -R 775 "$LARAVEL_PATH/bootstrap/cache"
    
    # Set ACL if available
    if command -v setfacl >/dev/null 2>&1; then
        setfacl -R -m u:www-data:rwx "$LARAVEL_PATH/storage"
        setfacl -R -m u:www-data:rwx "$LARAVEL_PATH/bootstrap/cache"
        setfacl -R -d -m u:www-data:rwx "$LARAVEL_PATH/storage"
        setfacl -R -d -m u:www-data:rwx "$LARAVEL_PATH/bootstrap/cache"
    fi
    
    log_success "Permissions set successfully"
}

clear_and_cache_laravel() {
    log_step "Clearing and caching Laravel configuration..."
    
    cd "$LARAVEL_PATH"
    
    sudo -u www-data php artisan config:clear 2>/dev/null || true
    sudo -u www-data php artisan cache:clear 2>/dev/null || true
    sudo -u www-data php artisan view:clear 2>/dev/null || true
    sudo -u www-data php artisan route:clear 2>/dev/null || true
    
    if [ "$APP_ENV" = "production" ]; then
        sudo -u www-data php artisan config:cache 2>/dev/null || true
        sudo -u www-data php artisan route:cache 2>/dev/null || true
        sudo -u www-data php artisan view:cache 2>/dev/null || true
    fi
    
    log_success "Laravel cache cleared and optimized"
}

configure_webserver_for_laravel() {
    case $WEB_SERVER in
        "nginx")
            configure_nginx_laravel "$REPO_NAME" "$LARAVEL_PATH" "$DOMAIN_NAME"
            ;;
        "apache")
            configure_apache_laravel "$REPO_NAME" "$LARAVEL_PATH" "$DOMAIN_NAME"
            ;;
        "caddy")
            configure_caddy_laravel "$REPO_NAME" "$LARAVEL_PATH" "$DOMAIN_NAME"
            ;;
        "frankenphp")
            configure_frankenphp_laravel "$REPO_NAME" "$LARAVEL_PATH" "$DOMAIN_NAME"
            ;;
    esac
}

#############################################################################
# NPM AND NODE.JS (OPTIONAL)
#############################################################################

install_nodejs_npm() {
    if [ ! -f "$LARAVEL_PATH/package.json" ]; then
        log_info "No package.json found, skipping Node.js"
        return 0
    fi
    
    if ! confirm "Install Node.js and build frontend assets?"; then
        log_info "Skipping Node.js installation"
        return 0
    fi
    
    log_step "Installing Node.js..."
    
    local node_version="20"
    
    cd /tmp
    curl -sL "https://deb.nodesource.com/setup_${node_version}.x" -o nodesource_setup.sh
    bash nodesource_setup.sh
    
    case $OS in
        ubuntu|debian)
            apt-get install -y nodejs || error_exit "Failed to install Node.js"
            ;;
        centos|rhel|fedora)
            yum install -y nodejs || error_exit "Failed to install Node.js"
            ;;
    esac
    
    log_success "Node.js $(node --version) installed"
    
    # Install dependencies and build
    cd "$LARAVEL_PATH"
    
    if confirm "Install NPM dependencies and build assets?"; then
        log_step "Installing NPM dependencies..."
        sudo -u www-data npm install || log_warning "NPM install had issues"
        
        if confirm "Build production assets?"; then
            sudo -u www-data npm run build || log_warning "Build had issues"
        fi
    fi
}
