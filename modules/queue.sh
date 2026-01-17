#!/bin/bash

#############################################################################
# QUEUE MODULE
# Supervisor setup for Laravel queue workers
#############################################################################

install_queue_workers() {
    if ! confirm "Set up Laravel queue workers?"; then
        INSTALL_QUEUE="false"
        log_info "Skipping queue worker setup"
        return 0
    fi
    
    INSTALL_QUEUE="true"
    
    print_section "⚙️ Queue Worker Configuration"
    
    # Install Supervisor
    install_supervisor
    
    # Configure queue workers
    configure_queue_workers
}

install_supervisor() {
    log_step "Installing Supervisor..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y supervisor || error_exit "Failed to install Supervisor"
            ;;
        centos|rhel|fedora)
            yum install -y supervisor || error_exit "Failed to install Supervisor"
            ;;
    esac
    
    systemctl enable supervisor
    systemctl start supervisor
    
    log_success "Supervisor installed and started"
}

configure_queue_workers() {
    log_step "Configuring queue workers..."
    
    # Select queue driver
    select_queue_driver
    
    # Get queue configuration
    echo ""
    echo -e "${BOLD}Queue Worker Configuration:${NC}"
    echo ""
    
    print_box_start
    print_box_item "  Server Recommendation: ${CYAN}$QUEUE_WORKERS workers${NC}"
    print_box_item "  Based on: ${SERVER_TYPE} server with ${CPU_CORES} CPU cores"
    print_box_end
    echo ""
    
    get_input "Number of queue workers" "$QUEUE_WORKERS" QUEUE_WORKERS
    get_input "Queue names (comma-separated)" "default" QUEUE_NAMES
    
    # Create supervisor configurations
    create_queue_supervisor_configs
    
    # Update Laravel .env
    update_laravel_env_queue
    
    log_success "Queue workers configured"
}

select_queue_driver() {
    echo ""
    echo -e "${BOLD}Select Queue Driver:${NC}"
    echo ""
    
    # Check if Redis is installed
    local redis_installed=false
    if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
        redis_installed=true
    fi
    
    print_box_start
    print_box_item "  ${GREEN}1)${NC} ${BOLD}Database${NC}"
    print_box_item "     → Simple, no additional setup required"
    print_box_item ""
    
    if [ "$redis_installed" = true ]; then
        print_box_item "  ${GREEN}2)${NC} ${BOLD}Redis${NC} ${GREEN}(Recommended - Already Installed!)${NC}"
    else
        print_box_item "  ${GREEN}2)${NC} ${BOLD}Redis${NC} ${GREEN}(Recommended for production)${NC}"
    fi
    print_box_item "     → Fast, efficient, requires Redis installation"
    print_box_item ""
    print_box_item "  ${GREEN}3)${NC} ${BOLD}Sync${NC}"
    print_box_item "     → Process immediately (development only)"
    print_box_end
    echo ""
    
    local default_choice="2"
    if [ "$redis_installed" = false ]; then
        default_choice="1"
    fi
    
    get_input "Select queue driver [1-3]" "$default_choice" driver_choice
    
    case $driver_choice in
        1)
            QUEUE_DRIVER="database"
            log_info "Selected: Database queue driver"
            ;;
        2)
            QUEUE_DRIVER="redis"
            log_info "Selected: Redis queue driver"
            
            # Check if Redis is installed
            if ! systemctl is-active --quiet redis-server 2>/dev/null && ! systemctl is-active --quiet redis 2>/dev/null; then
                log_warning "Redis is not installed!"
                echo ""
                echo "Redis setup is recommended. You can:"
                echo "  1. Run the full setup again and install Redis"
                echo "  2. Install Redis manually: apt install redis-server"
                echo "  3. Continue with database driver instead"
                echo ""
                
                if confirm "Switch to database driver instead?"; then
                    QUEUE_DRIVER="database"
                    log_info "Switched to database driver"
                else
                    log_warning "Queue driver set to Redis but Redis is not installed"
                    log_info "Install Redis before starting queue workers"
                fi
            fi
            ;;
        3)
            QUEUE_DRIVER="sync"
            log_warning "Sync driver selected - jobs will run immediately (not recommended for production)"
            ;;
        *)
            QUEUE_DRIVER="database"
            log_info "Default: Database queue driver"
            ;;
    esac
}

create_queue_supervisor_configs() {
    log_step "Creating Supervisor configuration files..."
    
    # Convert comma-separated queue names to array
    IFS=',' read -ra QUEUE_ARRAY <<< "$QUEUE_NAMES"
    
    for queue_name in "${QUEUE_ARRAY[@]}"; do
        # Trim whitespace
        queue_name=$(echo "$queue_name" | xargs)
        
        local config_file="/etc/supervisor/conf.d/${REPO_NAME}_${queue_name}.conf"
        
        log_info "Creating config for queue: $queue_name"
        
        cat > "$config_file" <<EOF
[program:${REPO_NAME}_${queue_name}]
process_name=%(program_name)s_%(process_num)02d
command=php ${LARAVEL_PATH}/artisan queue:work ${QUEUE_DRIVER} --queue=${queue_name} --sleep=3 --tries=3 --max-time=3600 --timeout=3660
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=${QUEUE_WORKERS}
user=www-data
redirect_stderr=true
stdout_logfile=${LARAVEL_PATH}/storage/logs/queue_${queue_name}.log
stopwaitsecs=3660
priority=999
EOF
        
        # Create log file
        touch "${LARAVEL_PATH}/storage/logs/queue_${queue_name}.log"
        chown www-data:www-data "${LARAVEL_PATH}/storage/logs/queue_${queue_name}.log"
        
        log_success "Created supervisor config: $queue_name"
    done
    
    # Create queue management script
    create_queue_management_script
    
    # Reload supervisor
    supervisorctl reread
    supervisorctl update
    
    # Start queue workers
    for queue_name in "${QUEUE_ARRAY[@]}"; do
        queue_name=$(echo "$queue_name" | xargs)
        supervisorctl start "${REPO_NAME}_${queue_name}:*"
    done
    
    log_success "Queue workers started"
}

create_queue_management_script() {
    log_step "Creating queue management script..."
    
    cat > "/usr/local/bin/laravel-queue" <<'EOFSCRIPT'
#!/bin/bash

# Laravel Queue Management Script

PROJECT_NAME="${REPO_NAME}"
PROJECT_PATH="${LARAVEL_PATH}"

case "$1" in
    status)
        echo "=== Queue Workers Status ==="
        supervisorctl status | grep "${PROJECT_NAME}"
        ;;
    start)
        echo "Starting queue workers..."
        supervisorctl start "${PROJECT_NAME}_*:*"
        ;;
    stop)
        echo "Stopping queue workers..."
        supervisorctl stop "${PROJECT_NAME}_*:*"
        ;;
    restart)
        echo "Restarting queue workers..."
        supervisorctl restart "${PROJECT_NAME}_*:*"
        ;;
    logs)
        QUEUE_NAME="${2:-default}"
        echo "=== Queue Logs: $QUEUE_NAME ==="
        tail -f "${PROJECT_PATH}/storage/logs/queue_${QUEUE_NAME}.log"
        ;;
    monitor)
        echo "=== Queue Monitor (Press Ctrl+C to exit) ==="
        watch -n 2 "supervisorctl status | grep ${PROJECT_NAME}"
        ;;
    *)
        echo "Laravel Queue Management"
        echo ""
        echo "Usage: laravel-queue {status|start|stop|restart|logs|monitor}"
        echo ""
        echo "Commands:"
        echo "  status    - Show queue worker status"
        echo "  start     - Start all queue workers"
        echo "  stop      - Stop all queue workers"
        echo "  restart   - Restart all queue workers"
        echo "  logs      - Tail queue logs (optional: specify queue name)"
        echo "  monitor   - Live monitoring of queue workers"
        echo ""
        echo "Examples:"
        echo "  laravel-queue status"
        echo "  laravel-queue restart"
        echo "  laravel-queue logs default"
        exit 1
        ;;
esac
EOFSCRIPT
    
    # Replace placeholders
    sed -i "s/\${REPO_NAME}/${REPO_NAME}/g" /usr/local/bin/laravel-queue
    sed -i "s|\${LARAVEL_PATH}|${LARAVEL_PATH}|g" /usr/local/bin/laravel-queue
    
    chmod +x /usr/local/bin/laravel-queue
    
    log_success "Queue management script created: /usr/local/bin/laravel-queue"
}

update_laravel_env_queue() {
    if [ ! -f "$LARAVEL_PATH/.env" ]; then
        log_warning ".env file not found"
        return 0
    fi
    
    log_step "Updating .env with queue configuration..."
    
    # Update queue connection
    sed -i "s/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=${QUEUE_DRIVER}/" "$LARAVEL_PATH/.env" || \
        echo "QUEUE_CONNECTION=${QUEUE_DRIVER}" >> "$LARAVEL_PATH/.env"
    
    log_success "Queue configuration updated in .env"
}

#############################################################################
# QUEUE MONITORING DASHBOARD
#############################################################################

create_queue_monitoring_dashboard() {
    if ! confirm "Create simple queue monitoring dashboard?"; then
        return 0
    fi
    
    log_step "Creating queue monitoring dashboard..."
    
    local dashboard_path="${LARAVEL_PATH}/public/queue-monitor.php"
    
    cat > "$dashboard_path" <<'EOF'
<?php
/**
 * Simple Queue Monitoring Dashboard
 * Access: http://your-domain/queue-monitor.php
 */

// Basic authentication (change these!)
$auth_user = 'admin';
$auth_pass = 'change_me';

if (!isset($_SERVER['PHP_AUTH_USER']) || 
    $_SERVER['PHP_AUTH_USER'] !== $auth_user || 
    $_SERVER['PHP_AUTH_PW'] !== $auth_pass) {
    header('WWW-Authenticate: Basic realm="Queue Monitor"');
    header('HTTP/1.0 401 Unauthorized');
    echo 'Access Denied';
    exit;
}

// Get supervisor status
$output = shell_exec('supervisorctl status 2>&1');
$lines = explode("\n", trim($output));

?>
<!DOCTYPE html>
<html>
<head>
    <title>Queue Monitor</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        h1 { color: #333; }
        table { width: 100%; border-collapse: collapse; background: white; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #4CAF50; color: white; }
        .running { color: green; font-weight: bold; }
        .stopped { color: red; font-weight: bold; }
        .info { background: #e7f3fe; padding: 15px; margin: 20px 0; border-left: 4px solid #2196F3; }
    </style>
</head>
<body>
    <h1>🚀 Queue Workers Status</h1>
    <div class="info">
        <strong>Auto-refresh:</strong> Every 5 seconds | 
        <strong>Last updated:</strong> <?= date('Y-m-d H:i:s') ?>
    </div>
    
    <table>
        <thead>
            <tr>
                <th>Worker</th>
                <th>Status</th>
                <th>PID</th>
                <th>Uptime</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($lines as $line): ?>
                <?php if (empty(trim($line))) continue; ?>
                <?php
                    $parts = preg_split('/\s+/', $line);
                    $name = $parts[0] ?? 'Unknown';
                    $status = $parts[1] ?? 'Unknown';
                    $pid = $parts[3] ?? '-';
                    $uptime = implode(' ', array_slice($parts, 5)) ?: '-';
                    
                    $statusClass = (strtolower($status) === 'running') ? 'running' : 'stopped';
                ?>
                <tr>
                    <td><?= htmlspecialchars($name) ?></td>
                    <td class="<?= $statusClass ?>"><?= htmlspecialchars($status) ?></td>
                    <td><?= htmlspecialchars($pid) ?></td>
                    <td><?= htmlspecialchars($uptime) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
EOF
    
    chown www-data:www-data "$dashboard_path"
    chmod 644 "$dashboard_path"
    
    log_success "Queue monitoring dashboard created"
    log_info "Access at: http://${DOMAIN_NAME}/queue-monitor.php"
    log_warning "Default credentials: admin / change_me (change these!)"
}
