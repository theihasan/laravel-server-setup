#!/bin/bash

#############################################################################
# REDIS MODULE
# Complete Redis setup with session, cache, queue driver support
#############################################################################

configure_redis_setup() {
    print_section "🔴 Redis Configuration"
    
    echo -e "${BOLD}Redis is a high-performance in-memory data store${NC}"
    echo -e "Perfect for: caching, sessions, and queues"
    echo ""
    
    if ! confirm "Do you want to install and configure Redis?"; then
        log_info "Skipping Redis installation"
        return 0
    fi
    
    # Install Redis
    install_redis_server
    
    # Configure Redis password
    configure_redis_password
    
    # Ask about PHP Redis extension
    install_php_redis_extension
    
    # Configure Redis for Laravel
    configure_redis_for_laravel
}

#############################################################################
# REDIS INSTALLATION
#############################################################################

install_redis_server() {
    log_step "Installing Redis server..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y redis-server redis-tools || error_exit "Failed to install Redis"
            ;;
        centos|rhel|fedora)
            yum install -y redis || error_exit "Failed to install Redis"
            ;;
    esac
    
    # Configure Redis for production
    configure_redis_server
    
    # Enable and start Redis
    systemctl enable redis-server 2>/dev/null || systemctl enable redis
    systemctl start redis-server 2>/dev/null || systemctl start redis
    
    # Verify Redis is running
    sleep 2
    if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
        log_success "Redis server installed and running"
    else
        error_exit "Failed to start Redis service"
    fi
}

configure_redis_server() {
    log_step "Configuring Redis server..."
    
    local redis_conf="/etc/redis/redis.conf"
    
    # Try alternate path
    if [ ! -f "$redis_conf" ]; then
        redis_conf="/etc/redis.conf"
    fi
    
    if [ -f "$redis_conf" ]; then
        # Backup original
        cp "$redis_conf" "${redis_conf}.backup"
        
        # Production optimizations
        sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' "$redis_conf"
        sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' "$redis_conf"
        
        # Enable persistence (optional)
        sed -i 's/^save 900 1/save 900 1/' "$redis_conf"
        sed -i 's/^save 300 10/save 300 10/' "$redis_conf"
        sed -i 's/^save 60 10000/save 60 10000/' "$redis_conf"
        
        # Set appropriate working directory
        sed -i 's|^dir .*|dir /var/lib/redis|' "$redis_conf"
        
        log_success "Redis server configured"
    else
        log_warning "Redis configuration file not found, using defaults"
    fi
}

#############################################################################
# REDIS PASSWORD CONFIGURATION
#############################################################################

configure_redis_password() {
    echo ""
    echo -e "${BOLD}Redis Security Configuration${NC}"
    echo ""
    
    if ! confirm "Do you want to set a password for Redis? ${GREEN}(Recommended for production)${NC}"; then
        log_info "Redis will run without password (localhost only)"
        REDIS_PASSWORD=""
        return 0
    fi
    
    log_step "Configuring Redis password..."
    
    # Generate or get password
    echo ""
    echo "Password options:"
    echo "  1) Auto-generate secure password (Recommended)"
    echo "  2) Enter custom password"
    echo ""
    get_input "Select option [1-2]" "1" pass_option
    
    if [ "$pass_option" = "2" ]; then
        get_password "Enter Redis password" REDIS_PASSWORD
    else
        REDIS_PASSWORD=$(openssl rand -base64 32)
        log_info "Generated password: $REDIS_PASSWORD"
    fi
    
    # Save password to file
    echo "$REDIS_PASSWORD" > /root/.redis_password
    chmod 600 /root/.redis_password
    log_success "Password saved to /root/.redis_password"
    
    # Configure password in Redis
    local redis_conf="/etc/redis/redis.conf"
    if [ ! -f "$redis_conf" ]; then
        redis_conf="/etc/redis.conf"
    fi
    
    if [ -f "$redis_conf" ]; then
        # Remove any existing requirepass
        sed -i '/^requirepass /d' "$redis_conf"
        
        # Add new password
        echo "requirepass $REDIS_PASSWORD" >> "$redis_conf"
        
        # Restart Redis
        systemctl restart redis-server 2>/dev/null || systemctl restart redis
        
        log_success "Redis password configured"
        
        # Test connection
        sleep 2
        if redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
            log_success "Redis authentication test successful"
        else
            log_warning "Redis authentication test failed"
        fi
    else
        log_warning "Could not configure Redis password - config file not found"
    fi
}

#############################################################################
# PHP REDIS EXTENSION
#############################################################################

install_php_redis_extension() {
    echo ""
    echo -e "${BOLD}PHP Redis Extension${NC}"
    echo ""
    echo "Choose Redis driver for PHP:"
    echo "  ${GREEN}1)${NC} ${BOLD}PhpRedis${NC} (C extension - Recommended)"
    echo "     → Faster, native C extension"
    echo "     → Better performance"
    echo ""
    echo "  ${GREEN}2)${NC} ${BOLD}Predis${NC} (PHP library)"
    echo "     → Pure PHP implementation"
    echo "     → No compilation needed"
    echo ""
    echo "  ${GREEN}3)${NC} ${BOLD}Both${NC}"
    echo "     → Install both, Laravel will use PhpRedis by default"
    echo ""
    
    get_input "Select option [1-3]" "1" redis_driver_choice
    
    case $redis_driver_choice in
        1)
            install_phpredis_extension
            REDIS_CLIENT="phpredis"
            ;;
        2)
            install_predis_package
            REDIS_CLIENT="predis"
            ;;
        3)
            install_phpredis_extension
            install_predis_package
            REDIS_CLIENT="phpredis"
            ;;
        *)
            log_warning "Invalid selection, defaulting to PhpRedis"
            install_phpredis_extension
            REDIS_CLIENT="phpredis"
            ;;
    esac
}

install_phpredis_extension() {
    log_step "Installing PhpRedis extension..."
    
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION="8.3"
    fi
    
    case $OS in
        ubuntu|debian)
            apt-get install -y "php${PHP_VERSION}-redis" || error_exit "Failed to install PhpRedis"
            ;;
        centos|rhel|fedora)
            yum install -y "php${PHP_VERSION}-redis" || error_exit "Failed to install PhpRedis"
            ;;
    esac
    
    # Restart PHP-FPM
    systemctl restart "php${PHP_VERSION}-fpm" 2>/dev/null || true
    
    # Verify installation
    if php -m | grep -q redis; then
        log_success "PhpRedis extension installed successfully"
    else
        log_warning "PhpRedis installation verification failed"
    fi
}

install_predis_package() {
    log_step "Installing Predis via Composer..."
    
    if [ -z "$LARAVEL_PATH" ]; then
        log_warning "Laravel path not set, Predis will need to be installed manually"
        log_info "Run: composer require predis/predis"
        return 0
    fi
    
    cd "$LARAVEL_PATH"
    
    if [ -f "composer.json" ]; then
        sudo -u www-data composer require predis/predis --no-interaction || log_warning "Failed to install Predis"
        log_success "Predis package installed"
    else
        log_warning "composer.json not found, skipping Predis installation"
    fi
}

#############################################################################
# REDIS USAGE CONFIGURATION
#############################################################################

configure_redis_for_laravel() {
    print_section "⚙️ Redis Usage Configuration"
    
    echo -e "${BOLD}Where would you like to use Redis?${NC}"
    echo -e "${CYAN}(You can select multiple options)${NC}"
    echo ""
    
    USE_REDIS_FOR_CACHE="false"
    USE_REDIS_FOR_SESSION="false"
    USE_REDIS_FOR_QUEUE="false"
    
    # Cache
    echo -e "${BOLD}1. Cache Driver${NC}"
    if confirm "Use Redis for caching?" "y"; then
        USE_REDIS_FOR_CACHE="true"
        CACHE_DRIVER="redis"
        log_success "Redis will be used for caching"
    else
        CACHE_DRIVER="file"
        log_info "Cache driver: file"
    fi
    
    echo ""
    
    # Session
    echo -e "${BOLD}2. Session Driver${NC}"
    if confirm "Use Redis for sessions?" "y"; then
        USE_REDIS_FOR_SESSION="true"
        SESSION_DRIVER="redis"
        log_success "Redis will be used for sessions"
    else
        SESSION_DRIVER="file"
        log_info "Session driver: file"
    fi
    
    echo ""
    
    # Queue
    echo -e "${BOLD}3. Queue Driver${NC}"
    if confirm "Use Redis for queues?" "y"; then
        USE_REDIS_FOR_QUEUE="true"
        QUEUE_DRIVER="redis"
        log_success "Redis will be used for queues"
    else
        if [ -z "$QUEUE_DRIVER" ]; then
            QUEUE_DRIVER="database"
        fi
        log_info "Queue driver: $QUEUE_DRIVER"
    fi
    
    # Summary
    show_redis_configuration_summary
    
    # Update Laravel .env
    update_laravel_env_redis
}

show_redis_configuration_summary() {
    echo ""
    print_section "📋 Redis Configuration Summary"
    
    print_box_start
    print_box_item "  ${BOLD}Redis Server:${NC} Running on 127.0.0.1:6379"
    print_box_item "  ${BOLD}Password Protected:${NC} $([ -n "$REDIS_PASSWORD" ] && echo "Yes" || echo "No")"
    print_box_item "  ${BOLD}PHP Extension:${NC} $REDIS_CLIENT"
    print_box_item ""
    print_box_item "  ${BOLD}Usage:${NC}"
    
    if [ "$USE_REDIS_FOR_CACHE" = "true" ]; then
        print_box_item "    ✓ Cache: ${GREEN}Redis${NC}"
    else
        print_box_item "    ✗ Cache: ${YELLOW}File${NC}"
    fi
    
    if [ "$USE_REDIS_FOR_SESSION" = "true" ]; then
        print_box_item "    ✓ Session: ${GREEN}Redis${NC}"
    else
        print_box_item "    ✗ Session: ${YELLOW}File${NC}"
    fi
    
    if [ "$USE_REDIS_FOR_QUEUE" = "true" ]; then
        print_box_item "    ✓ Queue: ${GREEN}Redis${NC}"
    else
        print_box_item "    ✗ Queue: ${YELLOW}Database${NC}"
    fi
    
    print_box_end
    echo ""
}

#############################################################################
# UPDATE LARAVEL .ENV
#############################################################################

update_laravel_env_redis() {
    if [ -z "$LARAVEL_PATH" ] || [ ! -f "$LARAVEL_PATH/.env" ]; then
        log_warning "Laravel .env file not found, skipping Redis configuration"
        return 0
    fi
    
    log_step "Updating Laravel .env with Redis configuration..."
    
    local env_file="$LARAVEL_PATH/.env"
    
    # Update Redis connection details
    update_or_add_env "$env_file" "REDIS_HOST" "127.0.0.1"
    update_or_add_env "$env_file" "REDIS_PORT" "6379"
    
    if [ -n "$REDIS_PASSWORD" ]; then
        update_or_add_env "$env_file" "REDIS_PASSWORD" "$REDIS_PASSWORD"
    else
        update_or_add_env "$env_file" "REDIS_PASSWORD" "null"
    fi
    
    # Set Redis client
    update_or_add_env "$env_file" "REDIS_CLIENT" "$REDIS_CLIENT"
    
    # Update cache driver
    update_or_add_env "$env_file" "CACHE_DRIVER" "$CACHE_DRIVER"
    
    # Update session driver
    update_or_add_env "$env_file" "SESSION_DRIVER" "$SESSION_DRIVER"
    
    # Update queue driver
    update_or_add_env "$env_file" "QUEUE_CONNECTION" "$QUEUE_DRIVER"
    
    log_success "Laravel .env updated with Redis configuration"
}

update_or_add_env() {
    local file=$1
    local key=$2
    local value=$3
    
    if grep -q "^${key}=" "$file" 2>/dev/null; then
        # Update existing
        sed -i "s/^${key}=.*/${key}=${value}/" "$file"
    else
        # Add new
        echo "${key}=${value}" >> "$file"
    fi
}

#############################################################################
# REDIS CONFIGURATION FILE TEMPLATES
#############################################################################

create_redis_config_for_laravel() {
    if [ -z "$LARAVEL_PATH" ]; then
        return 0
    fi
    
    log_step "Creating Redis configuration for Laravel..."
    
    local config_dir="$LARAVEL_PATH/config"
    
    if [ ! -d "$config_dir" ]; then
        log_warning "Laravel config directory not found"
        return 1
    fi
    
    # Check if we need to update database.php
    if [ -f "$config_dir/database.php" ]; then
        log_info "Redis configuration should already exist in config/database.php"
        
        # Optionally add custom Redis configuration
        if confirm "Add additional Redis connection configurations?"; then
            add_custom_redis_connections
        fi
    fi
}

add_custom_redis_connections() {
    log_info "Custom Redis connections can be added manually to config/database.php"
    log_info "Example configurations:"
    
    cat <<EOF

// Add to config/database.php under 'redis' => [

'cache' => [
    'host' => env('REDIS_HOST', '127.0.0.1'),
    'password' => env('REDIS_PASSWORD', null),
    'port' => env('REDIS_PORT', 6379),
    'database' => 1,
],

'session' => [
    'host' => env('REDIS_HOST', '127.0.0.1'),
    'password' => env('REDIS_PASSWORD', null),
    'port' => env('REDIS_PORT', 6379),
    'database' => 2,
],

'queue' => [
    'host' => env('REDIS_HOST', '127.0.0.1'),
    'password' => env('REDIS_PASSWORD', null),
    'port' => env('REDIS_PORT', 6379),
    'database' => 3,
],

EOF
}

#############################################################################
# REDIS TESTING
#############################################################################

test_redis_connection() {
    if ! confirm "Test Redis connection?"; then
        return 0
    fi
    
    log_step "Testing Redis connection..."
    
    echo ""
    
    # Test 1: Basic ping
    echo -e "${CYAN}Test 1: Basic Connection${NC}"
    if [ -n "$REDIS_PASSWORD" ]; then
        if redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
            echo "  ✓ Redis responds to PING"
        else
            echo "  ✗ Redis does not respond"
        fi
    else
        if redis-cli ping 2>/dev/null | grep -q "PONG"; then
            echo "  ✓ Redis responds to PING"
        else
            echo "  ✗ Redis does not respond"
        fi
    fi
    
    # Test 2: Set and get value
    echo ""
    echo -e "${CYAN}Test 2: Read/Write Test${NC}"
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -a "$REDIS_PASSWORD" SET test_key "test_value" >/dev/null 2>&1
        local result=$(redis-cli -a "$REDIS_PASSWORD" GET test_key 2>/dev/null)
    else
        redis-cli SET test_key "test_value" >/dev/null 2>&1
        local result=$(redis-cli GET test_key 2>/dev/null)
    fi
    
    if [ "$result" = "test_value" ]; then
        echo "  ✓ Can write and read data"
        
        # Cleanup
        if [ -n "$REDIS_PASSWORD" ]; then
            redis-cli -a "$REDIS_PASSWORD" DEL test_key >/dev/null 2>&1
        else
            redis-cli DEL test_key >/dev/null 2>&1
        fi
    else
        echo "  ✗ Cannot write/read data"
    fi
    
    # Test 3: PHP extension
    echo ""
    echo -e "${CYAN}Test 3: PHP Extension${NC}"
    if php -m | grep -q redis; then
        echo "  ✓ PHP Redis extension loaded"
    else
        echo "  ✗ PHP Redis extension not found"
    fi
    
    # Test 4: Laravel connection (if Laravel is installed)
    if [ -n "$LARAVEL_PATH" ] && [ -f "$LARAVEL_PATH/artisan" ]; then
        echo ""
        echo -e "${CYAN}Test 4: Laravel Connection${NC}"
        cd "$LARAVEL_PATH"
        
        if sudo -u www-data php artisan tinker --execute="Redis::connection()->ping();" 2>/dev/null | grep -q "PONG"; then
            echo "  ✓ Laravel can connect to Redis"
        else
            echo "  ⚠ Laravel Redis connection test skipped (run manually: php artisan tinker)"
        fi
    fi
    
    echo ""
    log_success "Redis connection tests completed"
}

#############################################################################
# REDIS MONITORING COMMANDS
#############################################################################

create_redis_management_script() {
    if ! confirm "Create Redis management script?"; then
        return 0
    fi
    
    log_step "Creating Redis management script..."
    
    cat > "/usr/local/bin/redis-manage" <<'EOFSCRIPT'
#!/bin/bash

# Redis Management Script

REDIS_PASSWORD=""
if [ -f "/root/.redis_password" ]; then
    REDIS_PASSWORD=$(cat /root/.redis_password)
fi

REDIS_CMD="redis-cli"
if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_CMD="redis-cli -a $REDIS_PASSWORD"
fi

case "$1" in
    status)
        echo "=== Redis Status ==="
        systemctl status redis-server 2>/dev/null || systemctl status redis
        ;;
    info)
        echo "=== Redis Info ==="
        $REDIS_CMD INFO | grep -E "redis_version|used_memory_human|connected_clients|total_commands_processed"
        ;;
    monitor)
        echo "=== Redis Monitor (Press Ctrl+C to exit) ==="
        $REDIS_CMD MONITOR
        ;;
    cli)
        echo "=== Redis CLI ==="
        $REDIS_CMD
        ;;
    flush)
        echo "⚠️  WARNING: This will delete ALL data in Redis!"
        read -p "Are you sure? (type 'yes' to confirm): " confirm
        if [ "$confirm" = "yes" ]; then
            $REDIS_CMD FLUSHALL
            echo "Redis flushed"
        else
            echo "Cancelled"
        fi
        ;;
    keys)
        PATTERN="${2:-*}"
        echo "=== Redis Keys (pattern: $PATTERN) ==="
        $REDIS_CMD KEYS "$PATTERN"
        ;;
    memory)
        echo "=== Redis Memory Usage ==="
        $REDIS_CMD INFO memory | grep -E "used_memory|maxmemory"
        ;;
    *)
        echo "Redis Management"
        echo ""
        echo "Usage: redis-manage {status|info|monitor|cli|flush|keys|memory}"
        echo ""
        echo "Commands:"
        echo "  status   - Show Redis service status"
        echo "  info     - Show Redis server info"
        echo "  monitor  - Monitor Redis commands in real-time"
        echo "  cli      - Open Redis CLI"
        echo "  flush    - Flush all Redis data (DANGEROUS)"
        echo "  keys     - List keys (optional: pattern)"
        echo "  memory   - Show memory usage"
        echo ""
        echo "Examples:"
        echo "  redis-manage status"
        echo "  redis-manage keys 'laravel*'"
        echo "  redis-manage monitor"
        exit 1
        ;;
esac
EOFSCRIPT
    
    chmod +x /usr/local/bin/redis-manage
    
    log_success "Redis management script created: /usr/local/bin/redis-manage"
}

#############################################################################
# REDIS PERFORMANCE TUNING
#############################################################################

show_redis_performance_tips() {
    cat <<EOF

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${BOLD}Redis Performance Tips${NC}
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${BOLD}1. Monitor Memory Usage:${NC}
   redis-manage memory

${BOLD}2. Use Separate Databases:${NC}
   - Database 0: Cache
   - Database 1: Sessions
   - Database 2: Queues

${BOLD}3. Set Appropriate TTL:${NC}
   Cache::put('key', 'value', 3600); // 1 hour

${BOLD}4. Use Redis for Read-Heavy Operations:${NC}
   Redis excels at read operations

${BOLD}5. Monitor Connection Pool:${NC}
   Watch for connection exhaustion

${BOLD}6. Configure Max Memory:${NC}
   Edit /etc/redis/redis.conf
   maxmemory 256mb

${BOLD}7. Use Appropriate Eviction Policy:${NC}
   allkeys-lru (recommended for cache)

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

EOF
}
