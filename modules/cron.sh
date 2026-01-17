#!/bin/bash

#############################################################################
# CRON MODULE
# Laravel Task Scheduler setup
#############################################################################

setup_cron_scheduler() {
    if ! confirm "Set up Laravel task scheduler (cron)?"; then
        INSTALL_CRON="false"
        log_info "Skipping cron scheduler setup"
        return 0
    fi
    
    INSTALL_CRON="true"
    
    print_section "⏰ Laravel Task Scheduler Setup"
    
    configure_laravel_cron
}

configure_laravel_cron() {
    log_step "Configuring Laravel cron scheduler..."
    
    if [ -z "$LARAVEL_PATH" ]; then
        log_error "Laravel path not set"
        return 1
    fi
    
    if [ ! -f "$LARAVEL_PATH/artisan" ]; then
        log_error "Laravel project not found at: $LARAVEL_PATH"
        return 1
    fi
    
    # Create cron entry
    local cron_command="* * * * * cd $LARAVEL_PATH && php artisan schedule:run >> /dev/null 2>&1"
    
    # Check if cron entry already exists
    if crontab -u www-data -l 2>/dev/null | grep -q "artisan schedule:run"; then
        log_info "Cron entry already exists"
        
        if confirm "Update existing cron entry?"; then
            # Remove old entry
            crontab -u www-data -l 2>/dev/null | grep -v "artisan schedule:run" | crontab -u www-data -
        else
            log_info "Keeping existing cron entry"
            return 0
        fi
    fi
    
    # Add new cron entry
    (crontab -u www-data -l 2>/dev/null; echo "$cron_command") | crontab -u www-data -
    
    log_success "Laravel cron scheduler configured"
    log_info "Cron entry: $cron_command"
    
    # Create cron log directory
    mkdir -p "$LARAVEL_PATH/storage/logs/scheduler"
    chown -R www-data:www-data "$LARAVEL_PATH/storage/logs/scheduler"
    
    # Create enhanced cron with logging (optional)
    create_enhanced_cron_setup
    
    # Test cron
    test_laravel_scheduler
}

create_enhanced_cron_setup() {
    if ! confirm "Create enhanced cron with logging?"; then
        return 0
    fi
    
    log_step "Setting up enhanced cron with logging..."
    
    # Create cron wrapper script
    local cron_script="$LARAVEL_PATH/scheduler-cron.sh"
    
    cat > "$cron_script" <<EOF
#!/bin/bash
#
# Laravel Scheduler Cron Wrapper
# This script runs the Laravel scheduler and logs the output
#

PROJECT_PATH="$LARAVEL_PATH"
LOG_DIR="\${PROJECT_PATH}/storage/logs/scheduler"
LOG_FILE="\${LOG_DIR}/cron-\$(date +%Y-%m-%d).log"

# Ensure log directory exists
mkdir -p "\$LOG_DIR"

# Log start time
echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Starting Laravel scheduler..." >> "\$LOG_FILE"

# Run scheduler
cd "\$PROJECT_PATH"
php artisan schedule:run >> "\$LOG_FILE" 2>&1

# Log completion
echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Scheduler completed" >> "\$LOG_FILE"
echo "---" >> "\$LOG_FILE"
EOF
    
    chmod +x "$cron_script"
    chown www-data:www-data "$cron_script"
    
    # Update cron to use wrapper script
    local enhanced_cron="* * * * * $cron_script"
    
    # Remove old cron
    crontab -u www-data -l 2>/dev/null | grep -v "artisan schedule:run" | crontab -u www-data -
    
    # Add enhanced cron
    (crontab -u www-data -l 2>/dev/null; echo "$enhanced_cron") | crontab -u www-data -
    
    log_success "Enhanced cron with logging configured"
    log_info "Scheduler logs: $LARAVEL_PATH/storage/logs/scheduler/"
    
    # Create log rotation
    create_scheduler_logrotate
}

create_scheduler_logrotate() {
    log_step "Setting up log rotation for scheduler logs..."
    
    cat > "/etc/logrotate.d/laravel-scheduler" <<EOF
$LARAVEL_PATH/storage/logs/scheduler/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    missingok
}
EOF
    
    log_success "Log rotation configured for scheduler logs"
}

test_laravel_scheduler() {
    if ! confirm "Test Laravel scheduler now?"; then
        return 0
    fi
    
    log_step "Testing Laravel scheduler..."
    
    cd "$LARAVEL_PATH"
    
    echo ""
    echo -e "${CYAN}Running: php artisan schedule:list${NC}"
    echo ""
    
    sudo -u www-data php artisan schedule:list || log_warning "Failed to list scheduled tasks"
    
    echo ""
    if confirm "Run scheduler once to test?"; then
        echo ""
        echo -e "${CYAN}Running: php artisan schedule:run${NC}"
        echo ""
        sudo -u www-data php artisan schedule:run || log_warning "Scheduler test failed"
    fi
}

#############################################################################
# SCHEDULER MANAGEMENT COMMANDS
#############################################################################

create_scheduler_management_script() {
    if ! confirm "Create scheduler management script?"; then
        return 0
    fi
    
    log_step "Creating scheduler management script..."
    
    cat > "/usr/local/bin/laravel-scheduler" <<'EOFSCRIPT'
#!/bin/bash

# Laravel Scheduler Management Script

PROJECT_PATH="${LARAVEL_PATH}"

case "$1" in
    list)
        echo "=== Scheduled Tasks ==="
        cd "$PROJECT_PATH"
        php artisan schedule:list
        ;;
    run)
        echo "=== Running Scheduler Manually ==="
        cd "$PROJECT_PATH"
        php artisan schedule:run -v
        ;;
    logs)
        DAYS="${2:-1}"
        echo "=== Scheduler Logs (Last $DAYS days) ==="
        find "$PROJECT_PATH/storage/logs/scheduler" -name "cron-*.log" -mtime -$DAYS -exec tail -50 {} \;
        ;;
    tail)
        LOG_FILE="$PROJECT_PATH/storage/logs/scheduler/cron-$(date +%Y-%m-%d).log"
        echo "=== Tailing Today's Scheduler Log ==="
        echo "File: $LOG_FILE"
        echo ""
        tail -f "$LOG_FILE"
        ;;
    test)
        echo "=== Testing Scheduler ==="
        cd "$PROJECT_PATH"
        php artisan schedule:test
        ;;
    cron)
        echo "=== Current Cron Configuration ==="
        crontab -u www-data -l | grep artisan
        ;;
    *)
        echo "Laravel Scheduler Management"
        echo ""
        echo "Usage: laravel-scheduler {list|run|logs|tail|test|cron}"
        echo ""
        echo "Commands:"
        echo "  list     - List all scheduled tasks"
        echo "  run      - Run scheduler manually"
        echo "  logs     - View scheduler logs (optional: days, default 1)"
        echo "  tail     - Tail today's scheduler log"
        echo "  test     - Test scheduler configuration"
        echo "  cron     - Show cron configuration"
        echo ""
        echo "Examples:"
        echo "  laravel-scheduler list"
        echo "  laravel-scheduler run"
        echo "  laravel-scheduler logs 7"
        echo "  laravel-scheduler tail"
        exit 1
        ;;
esac
EOFSCRIPT
    
    # Replace placeholders
    sed -i "s|\${LARAVEL_PATH}|${LARAVEL_PATH}|g" /usr/local/bin/laravel-scheduler
    
    chmod +x /usr/local/bin/laravel-scheduler
    
    log_success "Scheduler management script created: /usr/local/bin/laravel-scheduler"
}

#############################################################################
# SCHEDULER MONITORING
#############################################################################

setup_scheduler_monitoring() {
    if ! confirm "Set up scheduler monitoring (check if cron is running)?"; then
        return 0
    fi
    
    log_step "Setting up scheduler monitoring..."
    
    # Create monitoring script
    cat > "/usr/local/bin/check-laravel-scheduler" <<EOFSCRIPT
#!/bin/bash

# Laravel Scheduler Health Check

PROJECT_PATH="$LARAVEL_PATH"
LOG_DIR="\${PROJECT_PATH}/storage/logs/scheduler"
ALERT_EMAIL="${ALERT_EMAIL:-root}"

# Check if scheduler has run in the last 2 minutes
LATEST_LOG=\$(find "\$LOG_DIR" -name "cron-*.log" -mmin -2 | head -1)

if [ -z "\$LATEST_LOG" ]; then
    echo "WARNING: Laravel scheduler has not run in the last 2 minutes"
    echo "This may indicate a cron job failure" | mail -s "Laravel Scheduler Alert" "\$ALERT_EMAIL"
    exit 1
else
    echo "OK: Laravel scheduler is running normally"
    exit 0
fi
EOFSCRIPT
    
    chmod +x /usr/local/bin/check-laravel-scheduler
    
    log_success "Scheduler monitoring script created"
    log_info "Run manually: /usr/local/bin/check-laravel-scheduler"
}

#############################################################################
# TROUBLESHOOTING HELPERS
#############################################################################

show_scheduler_troubleshooting() {
    cat <<EOF

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${BOLD}Laravel Scheduler Troubleshooting Guide${NC}
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${BOLD}1. Check if cron is configured:${NC}
   crontab -u www-data -l

${BOLD}2. View scheduled tasks:${NC}
   cd $LARAVEL_PATH
   php artisan schedule:list

${BOLD}3. Run scheduler manually:${NC}
   cd $LARAVEL_PATH
   php artisan schedule:run -v

${BOLD}4. Check scheduler logs:${NC}
   tail -f $LARAVEL_PATH/storage/logs/scheduler/cron-\$(date +%Y-%m-%d).log

${BOLD}5. Verify www-data user permissions:${NC}
   sudo -u www-data php $LARAVEL_PATH/artisan schedule:list

${BOLD}6. Check system cron service:${NC}
   systemctl status cron     # Debian/Ubuntu
   systemctl status crond    # CentOS/RHEL

${BOLD}Common Issues:${NC}
  • Permissions: Ensure www-data can read/write Laravel files
  • Path: Verify PHP path in cron (/usr/bin/php)
  • Environment: Cron runs with limited environment variables
  • Logs: Check $LARAVEL_PATH/storage/logs for errors

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

EOF
}
