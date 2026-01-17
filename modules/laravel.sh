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
        
        log_success "PHP configured for Laravel"
    else
        log_warning "PHP configuration file not found"
    fi
    
    # Configure PHP-FPM pool
    configure_php_fpm_pool
}

#############################################################################
# PHP-FPM POOL CONFIGURATION
#############################################################################

configure_php_fpm_pool() {
    if ! confirm "Configure PHP-FPM worker pool for optimal performance?"; then
        log_info "Skipping PHP-FPM pool configuration"
        systemctl restart "php${PHP_VERSION}-fpm"
        return 0
    fi
    
    print_section "⚙️ PHP-FPM Worker Pool Configuration"
    
    calculate_fpm_recommendations
    configure_fpm_pool_settings
}

calculate_fpm_recommendations() {
    log_step "Analyzing server resources for PHP-FPM recommendations..."
    
    # Get server resources
    local total_ram_mb=$(free -m | awk 'NR==2{print $2}')
    local available_ram_mb=$(free -m | awk 'NR==2{print $7}')
    local cpu_cores=$(nproc)
    
    # Average PHP process memory (estimated)
    local php_process_memory=64  # MB per PHP-FPM child process
    
    # Calculate recommendations based on server type
    case $SERVER_TYPE in
        "small")
            # Small server: Conservative settings
            PM_TYPE="dynamic"
            PM_MAX_CHILDREN=10
            PM_START_SERVERS=2
            PM_MIN_SPARE_SERVERS=1
            PM_MAX_SPARE_SERVERS=3
            PM_MAX_REQUESTS=500
            ;;
        "basic")
            # Basic server: Moderate settings
            PM_TYPE="dynamic"
            PM_MAX_CHILDREN=20
            PM_START_SERVERS=4
            PM_MIN_SPARE_SERVERS=2
            PM_MAX_SPARE_SERVERS=6
            PM_MAX_REQUESTS=500
            ;;
        "medium")
            # Medium server: Balanced settings
            PM_TYPE="dynamic"
            PM_MAX_CHILDREN=50
            PM_START_SERVERS=10
            PM_MIN_SPARE_SERVERS=5
            PM_MAX_SPARE_SERVERS=15
            PM_MAX_REQUESTS=1000
            ;;
        "large")
            # Large server: High-performance settings
            PM_TYPE="dynamic"
            PM_MAX_CHILDREN=100
            PM_START_SERVERS=20
            PM_MIN_SPARE_SERVERS=10
            PM_MAX_SPARE_SERVERS=30
            PM_MAX_REQUESTS=1000
            ;;
        *)
            # Default: Basic settings
            PM_TYPE="dynamic"
            PM_MAX_CHILDREN=20
            PM_START_SERVERS=4
            PM_MIN_SPARE_SERVERS=2
            PM_MAX_SPARE_SERVERS=6
            PM_MAX_REQUESTS=500
            ;;
    esac
    
    # Display recommendations
    echo ""
    echo -e "${BOLD}Server Analysis:${NC}"
    echo ""
    print_box_start
    print_box_item "  Total RAM: ${total_ram_mb} MB"
    print_box_item "  Available RAM: ${available_ram_mb} MB"
    print_box_item "  CPU Cores: ${cpu_cores}"
    print_box_item "  Server Type: ${SERVER_TYPE}"
    print_box_item "  Estimated PHP Memory: ${php_process_memory} MB per worker"
    print_box_end
    echo ""
    
    echo -e "${BOLD}Recommended PHP-FPM Settings:${NC}"
    echo ""
    print_box_start
    print_box_item "  ${GREEN}Process Manager:${NC} ${PM_TYPE}"
    print_box_item "  ${GREEN}Max Children:${NC} ${PM_MAX_CHILDREN} workers"
    print_box_item "  ${GREEN}Start Servers:${NC} ${PM_START_SERVERS} workers"
    print_box_item "  ${GREEN}Min Spare:${NC} ${PM_MIN_SPARE_SERVERS} workers"
    print_box_item "  ${GREEN}Max Spare:${NC} ${PM_MAX_SPARE_SERVERS} workers"
    print_box_item "  ${GREEN}Max Requests:${NC} ${PM_MAX_REQUESTS} per worker"
    print_box_end
    echo ""
    
    log_info "These settings are optimized for ${SERVER_TYPE} servers"
}

configure_fpm_pool_settings() {
    echo -e "${BOLD}PHP-FPM Configuration Options:${NC}"
    echo ""
    
    print_box_start
    print_box_item "  ${GREEN}1)${NC} Use Recommended Settings"
    print_box_item "     → Optimized for your server (${SERVER_TYPE})"
    print_box_item ""
    print_box_item "  ${GREEN}2)${NC} Custom Configuration"
    print_box_item "     → Manually set worker values"
    print_box_item ""
    print_box_item "  ${GREEN}3)${NC} Skip Configuration"
    print_box_item "     → Keep default PHP-FPM settings"
    print_box_end
    echo ""
    
    get_input "Select option [1-3]" "1" fpm_choice
    
    case $fpm_choice in
        1)
            log_info "Using recommended settings"
            apply_fpm_configuration
            ;;
        2)
            custom_fpm_configuration
            apply_fpm_configuration
            ;;
        3)
            log_info "Keeping default PHP-FPM configuration"
            systemctl restart "php${PHP_VERSION}-fpm"
            return 0
            ;;
        *)
            log_warning "Invalid selection, using recommended settings"
            apply_fpm_configuration
            ;;
    esac
}

custom_fpm_configuration() {
    echo ""
    echo -e "${BOLD}Custom PHP-FPM Configuration:${NC}"
    echo ""
    
    get_input "Max children (max concurrent workers)" "$PM_MAX_CHILDREN" PM_MAX_CHILDREN
    get_input "Start servers (workers on startup)" "$PM_START_SERVERS" PM_START_SERVERS
    get_input "Min spare servers (idle workers minimum)" "$PM_MIN_SPARE_SERVERS" PM_MIN_SPARE_SERVERS
    get_input "Max spare servers (idle workers maximum)" "$PM_MAX_SPARE_SERVERS" PM_MAX_SPARE_SERVERS
    get_input "Max requests per worker (before restart)" "$PM_MAX_REQUESTS" PM_MAX_REQUESTS
}

apply_fpm_configuration() {
    log_step "Applying PHP-FPM pool configuration..."
    
    local pool_config="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    
    if [ ! -f "$pool_config" ]; then
        log_warning "PHP-FPM pool configuration not found at $pool_config"
        return 1
    fi
    
    # Backup original
    cp "$pool_config" "${pool_config}.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Update pool configuration
    sed -i "s/^pm = .*/pm = ${PM_TYPE}/" "$pool_config"
    sed -i "s/^pm.max_children = .*/pm.max_children = ${PM_MAX_CHILDREN}/" "$pool_config"
    sed -i "s/^pm.start_servers = .*/pm.start_servers = ${PM_START_SERVERS}/" "$pool_config"
    sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = ${PM_MIN_SPARE_SERVERS}/" "$pool_config"
    sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = ${PM_MAX_SPARE_SERVERS}/" "$pool_config"
    sed -i "s/^;pm.max_requests = .*/pm.max_requests = ${PM_MAX_REQUESTS}/" "$pool_config"
    sed -i "s/^pm.max_requests = .*/pm.max_requests = ${PM_MAX_REQUESTS}/" "$pool_config"
    
    # Enable status page for monitoring
    sed -i "s/^;pm.status_path = .*/pm.status_path = \/php-fpm-status/" "$pool_config"
    
    # Enable slow log
    sed -i "s/^;slowlog = .*/slowlog = \/var\/log\/php${PHP_VERSION}-fpm-slow.log/" "$pool_config"
    sed -i "s/^;request_slowlog_timeout = .*/request_slowlog_timeout = 10s/" "$pool_config"
    
    # Set process priority
    sed -i "s/^;process.priority = .*/process.priority = -10/" "$pool_config"
    
    log_success "PHP-FPM pool configuration applied"
    
    # Restart PHP-FPM
    log_step "Restarting PHP-FPM..."
    systemctl restart "php${PHP_VERSION}-fpm"
    
    if systemctl is-active --quiet "php${PHP_VERSION}-fpm"; then
        log_success "PHP-FPM restarted successfully"
        show_fpm_status
    else
        log_error "PHP-FPM failed to restart. Check logs: journalctl -u php${PHP_VERSION}-fpm"
        return 1
    fi
}

show_fpm_status() {
    echo ""
    echo -e "${BOLD}PHP-FPM Configuration Summary:${NC}"
    echo ""
    print_box_start
    print_box_item "  ${GREEN}✓${NC} Process Manager: ${PM_TYPE}"
    print_box_item "  ${GREEN}✓${NC} Max Children: ${PM_MAX_CHILDREN}"
    print_box_item "  ${GREEN}✓${NC} Start Servers: ${PM_START_SERVERS}"
    print_box_item "  ${GREEN}✓${NC} Min Spare: ${PM_MIN_SPARE_SERVERS}"
    print_box_item "  ${GREEN}✓${NC} Max Spare: ${PM_MAX_SPARE_SERVERS}"
    print_box_item "  ${GREEN}✓${NC} Max Requests: ${PM_MAX_REQUESTS}"
    print_box_item ""
    print_box_item "  Status Page: /php-fpm-status"
    print_box_item "  Slow Log: /var/log/php${PHP_VERSION}-fpm-slow.log"
    print_box_item "  Config: /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    print_box_end
    echo ""
    
    # Install PHP-FPM management CLI
    install_php_fpm_cli
}

install_php_fpm_cli() {
    log_step "Installing PHP-FPM management CLI..."
    
    local cli_script="/usr/local/bin/php-fpm-manage"
    
    cat > "$cli_script" << 'EOFCLI'
#!/bin/bash

#############################################################################
# PHP-FPM Management CLI
# Manage PHP-FPM workers and monitor performance
#############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect PHP version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")
FPM_SERVICE="php${PHP_VERSION}-fpm"
POOL_CONFIG="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
SLOW_LOG="/var/log/php${PHP_VERSION}-fpm-slow.log"

show_usage() {
    echo -e "${CYAN}PHP-FPM Management CLI${NC}"
    echo ""
    echo "Usage: php-fpm-manage [command]"
    echo ""
    echo "Commands:"
    echo "  status       Show PHP-FPM status and pool information"
    echo "  restart      Restart PHP-FPM service"
    echo "  reload       Reload PHP-FPM configuration"
    echo "  config       Show current pool configuration"
    echo "  workers      Show active workers"
    echo "  slow         Show slow requests log"
    echo "  stats        Show detailed statistics"
    echo "  test         Test PHP-FPM configuration"
    echo "  help         Show this help message"
    echo ""
}

show_status() {
    echo -e "${CYAN}=== PHP-FPM Status ===${NC}"
    echo ""
    
    if systemctl is-active --quiet "$FPM_SERVICE"; then
        echo -e "Service: ${GREEN}Running${NC}"
    else
        echo -e "Service: ${RED}Stopped${NC}"
        return 1
    fi
    
    echo "PHP Version: $PHP_VERSION"
    echo "Service: $FPM_SERVICE"
    echo ""
    
    systemctl status "$FPM_SERVICE" --no-pager -l | head -15
}

show_config() {
    echo -e "${CYAN}=== PHP-FPM Pool Configuration ===${NC}"
    echo ""
    
    if [ ! -f "$POOL_CONFIG" ]; then
        echo -e "${RED}Config file not found: $POOL_CONFIG${NC}"
        return 1
    fi
    
    echo "Config File: $POOL_CONFIG"
    echo ""
    
    echo -e "${YELLOW}Process Manager Settings:${NC}"
    grep -E "^pm = |^pm\.max_children|^pm\.start_servers|^pm\.min_spare|^pm\.max_spare|^pm\.max_requests" "$POOL_CONFIG" | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo -e "${YELLOW}Resource Limits:${NC}"
    grep -E "^pm\.max_requests|^request_terminate_timeout|^request_slowlog_timeout" "$POOL_CONFIG" | while read line; do
        echo "  $line"
    done
}

show_workers() {
    echo -e "${CYAN}=== Active PHP-FPM Workers ===${NC}"
    echo ""
    
    local worker_count=$(ps aux | grep "php-fpm: pool www" | grep -v grep | wc -l)
    echo "Active Workers: $worker_count"
    echo ""
    
    ps aux | grep "php-fpm: pool www" | grep -v grep | head -20
}

show_slow_log() {
    echo -e "${CYAN}=== Slow Request Log ===${NC}"
    echo ""
    
    if [ ! -f "$SLOW_LOG" ]; then
        echo -e "${YELLOW}No slow log file found: $SLOW_LOG${NC}"
        echo "Slow logging may not be enabled."
        return 0
    fi
    
    echo "Log File: $SLOW_LOG"
    echo ""
    
    if [ ! -s "$SLOW_LOG" ]; then
        echo -e "${GREEN}No slow requests recorded${NC}"
        return 0
    fi
    
    echo "Recent slow requests:"
    tail -50 "$SLOW_LOG"
}

show_stats() {
    echo -e "${CYAN}=== PHP-FPM Statistics ===${NC}"
    echo ""
    
    # Process information
    local total_workers=$(ps aux | grep "php-fpm: pool www" | grep -v grep | wc -l)
    local idle_workers=$(ps aux | grep "php-fpm: pool www" | grep "idle" | wc -l)
    local active_workers=$((total_workers - idle_workers))
    
    echo -e "${YELLOW}Worker Status:${NC}"
    echo "  Total Workers: $total_workers"
    echo "  Active: $active_workers"
    echo "  Idle: $idle_workers"
    echo ""
    
    # Memory usage
    local total_memory=$(ps aux | grep "php-fpm: pool www" | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
    local avg_memory=$(ps aux | grep "php-fpm: pool www" | grep -v grep | awk '{sum+=$6; count++} END {print sum/count/1024}')
    
    echo -e "${YELLOW}Memory Usage:${NC}"
    printf "  Total: %.2f MB\n" "$total_memory"
    printf "  Average per worker: %.2f MB\n" "$avg_memory"
    echo ""
    
    # System resources
    echo -e "${YELLOW}System Resources:${NC}"
    echo "  CPU Cores: $(nproc)"
    free -h | grep "Mem:" | awk '{print "  Total RAM: "$2"\n  Available: "$7}'
    echo ""
    
    # Uptime
    echo -e "${YELLOW}Service Uptime:${NC}"
    systemctl show "$FPM_SERVICE" --property=ActiveEnterTimestamp | cut -d= -f2
}

restart_fpm() {
    echo -e "${CYAN}=== Restarting PHP-FPM ===${NC}"
    echo ""
    
    echo "Restarting $FPM_SERVICE..."
    systemctl restart "$FPM_SERVICE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PHP-FPM restarted successfully${NC}"
    else
        echo -e "${RED}✗ Failed to restart PHP-FPM${NC}"
        return 1
    fi
}

reload_fpm() {
    echo -e "${CYAN}=== Reloading PHP-FPM ===${NC}"
    echo ""
    
    echo "Reloading $FPM_SERVICE configuration..."
    systemctl reload "$FPM_SERVICE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PHP-FPM configuration reloaded${NC}"
    else
        echo -e "${RED}✗ Failed to reload PHP-FPM${NC}"
        return 1
    fi
}

test_config() {
    echo -e "${CYAN}=== Testing PHP-FPM Configuration ===${NC}"
    echo ""
    
    php-fpm${PHP_VERSION} -t
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Configuration is valid${NC}"
    else
        echo ""
        echo -e "${RED}✗ Configuration has errors${NC}"
        return 1
    fi
}

# Main command handler
case "${1:-help}" in
    status) show_status ;;
    restart) restart_fpm ;;
    reload) reload_fpm ;;
    config) show_config ;;
    workers) show_workers ;;
    slow) show_slow_log ;;
    stats) show_stats ;;
    test) test_config ;;
    help|--help|-h) show_usage ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
EOFCLI
    
    chmod +x "$cli_script"
    log_success "PHP-FPM management CLI installed: php-fpm-manage"
    log_info "Usage: php-fpm-manage [status|restart|reload|config|workers|slow|stats|test]"
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
# NODE.JS AND NPM INSTALLATION
#############################################################################

install_nodejs_npm() {
    if ! confirm "Install Node.js and NPM for frontend assets?"; then
        log_info "Skipping Node.js installation"
        return 0
    fi
    
    print_section "📦 Node.js & NPM Configuration"
    
    select_nodejs_version
    install_nodejs
    configure_npm
}

select_nodejs_version() {
    echo -e "${BOLD}Select Node.js version:${NC}"
    echo ""
    
    print_box_start
    print_box_item "  ${GREEN}1)${NC} Node.js 18.x LTS (Hydrogen)"
    print_box_item "     → Stable, well-tested, good for production"
    print_box_item ""
    print_box_item "  ${GREEN}2)${NC} Node.js 20.x LTS (Iron) ${GREEN}(Recommended)${NC}"
    print_box_item "     → Current LTS, best for Laravel 10/11 with Vite"
    print_box_item ""
    print_box_item "  ${GREEN}3)${NC} Node.js 22.x (Latest)"
    print_box_item "     → Cutting edge, latest features"
    print_box_end
    echo ""
    
    get_input "Select Node.js version [1-3]" "2" node_choice
    
    case $node_choice in
        1) 
            NODE_VERSION="18"
            log_info "Selected: Node.js 18.x LTS"
            ;;
        2) 
            NODE_VERSION="20"
            log_info "Selected: Node.js 20.x LTS (Recommended)"
            ;;
        3) 
            NODE_VERSION="22"
            log_info "Selected: Node.js 22.x (Latest)"
            ;;
        *) 
            log_warning "Invalid selection, defaulting to Node.js 20.x LTS"
            NODE_VERSION="20"
            ;;
    esac
}

install_nodejs() {
    log_step "Installing Node.js ${NODE_VERSION}.x and NPM..."
    
    case $OS in
        ubuntu|debian)
            # Install Node.js from NodeSource repository
            curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
            apt-get install -y nodejs || error_exit "Failed to install Node.js"
            ;;
        centos|rhel|fedora)
            # Install Node.js from NodeSource repository
            curl -fsSL "https://rpm.nodesource.com/setup_${NODE_VERSION}.x" | bash -
            yum install -y nodejs || error_exit "Failed to install Node.js"
            ;;
    esac
    
    # Verify installation
    local node_version=$(node --version 2>/dev/null || echo "not installed")
    local npm_version=$(npm --version 2>/dev/null || echo "not installed")
    
    if [ "$node_version" != "not installed" ] && [ "$npm_version" != "not installed" ]; then
        log_success "Node.js ${node_version} and NPM ${npm_version} installed"
    else
        log_warning "Node.js/NPM installation may have failed"
        return 1
    fi
}

configure_npm() {
    log_step "Configuring NPM..."
    
    # Configure npm for www-data user
    mkdir -p /var/www/.npm
    mkdir -p /var/www/.npm-global
    chown -R www-data:www-data /var/www/.npm
    chown -R www-data:www-data /var/www/.npm-global
    
    # Set npm global directory for www-data
    sudo -u www-data npm config set prefix '/var/www/.npm-global'
    
    log_success "NPM configured for www-data user"
    log_info "Node.js and NPM ready for Laravel Vite asset compilation"
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
    
    # Set ownership immediately after cloning to avoid permission issues
    chown -R www-data:www-data "$LARAVEL_PATH"
    
    # Fix git safe directory warning
    cd "$LARAVEL_PATH"
    git config --global --add safe.directory "$LARAVEL_PATH"
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
    
    # Set ownership immediately after creating project
    chown -R www-data:www-data "$LARAVEL_PATH"
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
    
    # Ensure proper ownership before any operations
    chown -R www-data:www-data "$LARAVEL_PATH"
    
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
    
    # Install NPM dependencies and build assets (if Node.js is installed)
    setup_frontend_assets
    
    # Configure web server
    configure_webserver_for_laravel
    
    # Configure Git for deployment
    configure_git_for_deployment
    
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
# GIT CONFIGURATION FOR DEPLOYMENT
#############################################################################

configure_git_for_deployment() {
    # Check if this is a Git repository
    if [ ! -d "$LARAVEL_PATH/.git" ]; then
        log_info "Not a Git repository, skipping Git configuration"
        return 0
    fi
    
    if ! confirm "Configure Git for easy deployment and updates?"; then
        log_info "Skipping Git configuration"
        return 0
    fi
    
    print_section "🔧 Git Deployment Configuration"
    
    cd "$LARAVEL_PATH" || return 1
    
    log_step "Configuring Git for deployment..."
    
    # Add safe directory (prevents "dubious ownership" errors)
    git config --global --add safe.directory "$LARAVEL_PATH"
    
    # Configure Git to allow www-data user to run git commands
    chown -R www-data:www-data "$LARAVEL_PATH/.git"
    
    # Set Git to preserve file permissions
    sudo -u www-data git config core.fileMode false
    
    # Configure credential helper for HTTPS repositories
    sudo -u www-data git config credential.helper store
    
    # Get current remote info
    local remote_url=$(sudo -u www-data git config --get remote.origin.url 2>/dev/null || echo "")
    local current_branch=$(sudo -u www-data git branch --show-current 2>/dev/null || echo "main")
    
    if [ -n "$remote_url" ]; then
        log_info "Current remote: $remote_url"
        log_info "Current branch: $current_branch"
    fi
    
    # Configure Git user (for commits if needed)
    echo ""
    if confirm "Configure Git user for commits?"; then
        get_input "Git user name" "Deployment User" git_user_name
        get_input "Git user email" "deploy@${DOMAIN_NAME}" git_user_email
        
        sudo -u www-data git config user.name "$git_user_name"
        sudo -u www-data git config user.email "$git_user_email"
        
        log_success "Git user configured"
    fi
    
    # Setup deployment workflow
    setup_git_deployment_workflow
    
    # Create deployment helper script
    create_git_deploy_script
    
    log_success "Git configured for deployment"
}

setup_git_deployment_workflow() {
    log_step "Setting up deployment workflow..."
    
    echo ""
    echo -e "${BOLD}Git Deployment Strategy:${NC}"
    echo ""
    print_box_start
    print_box_item "  ${GREEN}1)${NC} Standard Pull (git pull)"
    print_box_item "     → Pull and merge changes"
    print_box_item ""
    print_box_item "  ${GREEN}2)${NC} Force Pull (git reset --hard + pull)"
    print_box_item "     → Discard local changes, force update"
    print_box_item ""
    print_box_item "  ${GREEN}3)${NC} Custom (manual configuration)"
    print_box_item "     → You manage Git workflow"
    print_box_end
    echo ""
    
    get_input "Select deployment strategy [1-3]" "1" deploy_strategy
    
    case $deploy_strategy in
        1)
            GIT_DEPLOY_MODE="pull"
            log_info "Using standard pull strategy"
            ;;
        2)
            GIT_DEPLOY_MODE="force"
            log_info "Using force pull strategy"
            ;;
        3)
            GIT_DEPLOY_MODE="manual"
            log_info "Manual Git workflow"
            ;;
        *)
            GIT_DEPLOY_MODE="pull"
            log_info "Defaulting to standard pull strategy"
            ;;
    esac
    
    # Configure branch tracking
    local current_branch=$(sudo -u www-data git branch --show-current 2>/dev/null || echo "main")
    sudo -u www-data git branch --set-upstream-to=origin/$current_branch $current_branch 2>/dev/null || true
    
    log_success "Deployment workflow configured"
}

create_git_deploy_script() {
    log_step "Creating deployment helper script..."
    
    local deploy_script="/usr/local/bin/laravel-deploy"
    
    cat > "$deploy_script" << 'EOFDEPLOY'
#!/bin/bash

#############################################################################
# Laravel Deployment Script
# Easy Git-based deployment with automatic Laravel updates
#############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect Laravel path from command line or current directory
LARAVEL_PATH="${1:-$(pwd)}"

if [ ! -f "$LARAVEL_PATH/artisan" ]; then
    echo -e "${RED}Error: Not a Laravel project${NC}"
    echo "Usage: laravel-deploy [/path/to/laravel]"
    exit 1
fi

cd "$LARAVEL_PATH" || exit 1

# Detect PHP version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")

show_usage() {
    echo -e "${CYAN}Laravel Deployment Helper${NC}"
    echo ""
    echo "Usage: laravel-deploy [command] [path]"
    echo ""
    echo "Commands:"
    echo "  pull         Pull latest changes and update"
    echo "  force        Force pull (discard local changes)"
    echo "  status       Show Git status"
    echo "  branch       Show/switch branches"
    echo "  log          Show recent commits"
    echo "  rollback     Rollback to previous commit"
    echo "  help         Show this help"
    echo ""
    echo "Path: /path/to/laravel (defaults to current directory)"
    echo ""
    echo "Examples:"
    echo "  laravel-deploy pull"
    echo "  laravel-deploy pull /var/www/html/myapp"
    echo "  laravel-deploy branch"
    echo "  laravel-deploy rollback"
    echo ""
}

enable_maintenance() {
    echo -e "${YELLOW}[→]${NC} Enabling maintenance mode..."
    sudo -u www-data php artisan down --render="errors::503" 2>/dev/null || echo "Already in maintenance mode"
}

disable_maintenance() {
    echo -e "${YELLOW}[→]${NC} Disabling maintenance mode..."
    sudo -u www-data php artisan up 2>/dev/null
}

pull_changes() {
    echo -e "${CYAN}=== Deploying Latest Changes ===${NC}"
    echo ""
    
    # Check for uncommitted changes
    if ! sudo -u www-data git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
        sudo -u www-data git status --short
        echo ""
        read -p "Continue? This will stash your changes. [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Deployment cancelled"
            exit 1
        fi
        sudo -u www-data git stash
    fi
    
    # Enable maintenance mode
    enable_maintenance
    
    # Pull changes
    echo -e "${YELLOW}[→]${NC} Pulling latest changes..."
    if sudo -u www-data git pull origin $(git branch --show-current); then
        echo -e "${GREEN}✓${NC} Changes pulled successfully"
    else
        echo -e "${RED}✗${NC} Failed to pull changes"
        disable_maintenance
        exit 1
    fi
    
    # Update dependencies
    update_application
    
    # Disable maintenance mode
    disable_maintenance
    
    echo ""
    echo -e "${GREEN}✓ Deployment completed successfully${NC}"
}

force_pull() {
    echo -e "${CYAN}=== Force Deploying (Discard Local Changes) ===${NC}"
    echo ""
    echo -e "${RED}WARNING: This will discard all local changes!${NC}"
    read -p "Are you sure? [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 1
    fi
    
    # Enable maintenance mode
    enable_maintenance
    
    # Get current branch
    local branch=$(sudo -u www-data git branch --show-current)
    
    # Fetch and reset
    echo -e "${YELLOW}[→]${NC} Fetching latest changes..."
    sudo -u www-data git fetch origin
    
    echo -e "${YELLOW}[→]${NC} Resetting to origin/$branch..."
    sudo -u www-data git reset --hard origin/$branch
    
    echo -e "${YELLOW}[→]${NC} Cleaning untracked files..."
    sudo -u www-data git clean -fd
    
    # Update dependencies
    update_application
    
    # Disable maintenance mode
    disable_maintenance
    
    echo ""
    echo -e "${GREEN}✓ Force deployment completed${NC}"
}

update_application() {
    echo -e "${YELLOW}[→]${NC} Updating Composer dependencies..."
    sudo -u www-data composer install --no-dev --optimize-autoloader --no-interaction
    
    echo -e "${YELLOW}[→]${NC} Running migrations..."
    sudo -u www-data php artisan migrate --force
    
    echo -e "${YELLOW}[→]${NC} Clearing caches..."
    sudo -u www-data php artisan cache:clear
    sudo -u www-data php artisan config:clear
    sudo -u www-data php artisan view:clear
    sudo -u www-data php artisan route:clear
    
    echo -e "${YELLOW}[→]${NC} Optimizing for production..."
    sudo -u www-data php artisan config:cache
    sudo -u www-data php artisan route:cache
    sudo -u www-data php artisan view:cache
    
    # Build frontend assets if package.json exists
    if [ -f "package.json" ] && command -v npm &> /dev/null; then
        echo -e "${YELLOW}[→]${NC} Building frontend assets..."
        sudo -u www-data npm ci --production
        sudo -u www-data npm run build 2>/dev/null || sudo -u www-data npm run production 2>/dev/null || true
    fi
    
    # Restart PHP-FPM
    echo -e "${YELLOW}[→]${NC} Restarting PHP-FPM..."
    systemctl reload php${PHP_VERSION}-fpm
    
    # Restart queue workers if supervisor is installed
    if command -v supervisorctl &> /dev/null; then
        echo -e "${YELLOW}[→]${NC} Restarting queue workers..."
        supervisorctl restart all 2>/dev/null || true
    fi
}

show_status() {
    echo -e "${CYAN}=== Git Status ===${NC}"
    echo ""
    sudo -u www-data git status
    echo ""
    echo -e "${CYAN}=== Current Branch ===${NC}"
    echo ""
    sudo -u www-data git branch -v
}

manage_branches() {
    echo -e "${CYAN}=== Git Branches ===${NC}"
    echo ""
    sudo -u www-data git branch -a
    echo ""
    read -p "Switch to branch (or press Enter to skip): " branch_name
    
    if [ -n "$branch_name" ]; then
        echo ""
        echo -e "${YELLOW}[→]${NC} Switching to branch: $branch_name..."
        
        if sudo -u www-data git checkout "$branch_name"; then
            echo -e "${GREEN}✓${NC} Switched to $branch_name"
            echo ""
            read -p "Pull latest changes? [Y/n]: " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                pull_changes
            fi
        else
            echo -e "${RED}✗${NC} Failed to switch branch"
        fi
    fi
}

show_log() {
    echo -e "${CYAN}=== Recent Commits ===${NC}"
    echo ""
    sudo -u www-data git log --oneline --decorate --graph -20
}

rollback_commit() {
    echo -e "${CYAN}=== Rollback Deployment ===${NC}"
    echo ""
    
    echo "Recent commits:"
    sudo -u www-data git log --oneline -10
    echo ""
    
    read -p "Enter commit hash to rollback to: " commit_hash
    
    if [ -z "$commit_hash" ]; then
        echo "Cancelled"
        exit 1
    fi
    
    echo ""
    echo -e "${RED}WARNING: This will reset to commit: $commit_hash${NC}"
    read -p "Are you sure? [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 1
    fi
    
    # Enable maintenance mode
    enable_maintenance
    
    # Reset to commit
    echo -e "${YELLOW}[→]${NC} Rolling back to $commit_hash..."
    if sudo -u www-data git reset --hard "$commit_hash"; then
        echo -e "${GREEN}✓${NC} Rolled back successfully"
        
        # Update application
        update_application
    else
        echo -e "${RED}✗${NC} Rollback failed"
    fi
    
    # Disable maintenance mode
    disable_maintenance
}

# Command handler
case "${1:-pull}" in
    pull)
        pull_changes
        ;;
    force)
        force_pull
        ;;
    status)
        show_status
        ;;
    branch)
        manage_branches
        ;;
    log)
        show_log
        ;;
    rollback)
        rollback_commit
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        if [ -d "$1" ]; then
            LARAVEL_PATH="$1"
            pull_changes
        else
            echo -e "${RED}Unknown command: $1${NC}"
            echo ""
            show_usage
            exit 1
        fi
        ;;
esac
EOFDEPLOY
    
    chmod +x "$deploy_script"
    log_success "Deployment script installed: laravel-deploy"
    log_info "Usage: laravel-deploy [pull|force|status|branch|log|rollback]"
}

#############################################################################
# FRONTEND ASSETS SETUP
#############################################################################

setup_frontend_assets() {
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_info "Node.js not installed, skipping frontend asset compilation"
        return 0
    fi
    
    # Check if package.json exists
    if [ ! -f "$LARAVEL_PATH/package.json" ]; then
        log_info "No package.json found, skipping frontend asset setup"
        return 0
    fi
    
    cd "$LARAVEL_PATH"
    
    if ! confirm "Install NPM dependencies and build frontend assets?"; then
        log_info "Skipping frontend asset setup"
        return 0
    fi
    
    log_step "Installing NPM dependencies..."
    
    # Install dependencies as www-data user
    sudo -u www-data npm install || log_warning "NPM install had issues (you can run manually later)"
    
    # Detect if using Vite or Mix
    local build_tool="unknown"
    if grep -q '"vite"' package.json; then
        build_tool="vite"
        log_info "Detected Vite build tool"
    elif grep -q '"laravel-mix"' package.json || grep -q '"mix"' package.json; then
        build_tool="mix"
        log_info "Detected Laravel Mix build tool"
    fi
    
    # Ask if they want to build now
    echo ""
    echo -e "${BOLD}Build Options:${NC}"
    echo ""
    print_box_start
    print_box_item "  ${GREEN}1)${NC} Build for production (npm run build)"
    print_box_item "     → Optimized, minified assets"
    print_box_item ""
    print_box_item "  ${GREEN}2)${NC} Skip build (run manually later)"
    print_box_item "     → You can build when ready"
    print_box_end
    echo ""
    
    get_input "Select option [1-2]" "1" build_choice
    
    case $build_choice in
        1)
            log_step "Building frontend assets for production..."
            if [ "$build_tool" = "vite" ]; then
                sudo -u www-data npm run build || log_warning "Vite build had issues"
            else
                sudo -u www-data npm run production 2>/dev/null || sudo -u www-data npm run build || log_warning "Asset build had issues"
            fi
            log_success "Frontend assets built successfully"
            ;;
        2)
            log_info "Skipping asset build"
            echo ""
            log_info "To build assets later, run:"
            if [ "$build_tool" = "vite" ]; then
                echo "  cd $LARAVEL_PATH && npm run build"
            else
                echo "  cd $LARAVEL_PATH && npm run production"
            fi
            ;;
    esac
}

