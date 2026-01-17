#!/bin/bash

#############################################################################
# Laravel Server Setup Script - Version 3.0
# 
# Complete, Interactive, Production-Ready Server Setup
# 
# Features:
# - Multiple web servers: Apache, Nginx, Caddy, FrankenPHP
# - Flexible database: Local or Remote with auto-configuration
# - Queue workers with Supervisor
# - Cron scheduler automation
# - Optional monitoring: Prometheus + Grafana
# - User consent at every step
#
# Author: FIGLAB
# Repository: https://github.com/theihasan/laravel-server-setup
#############################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
DASHBOARDS_DIR="${SCRIPT_DIR}/dashboards"

# Version
SCRIPT_VERSION="3.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Global Variables
INSTALL_LOG="/var/log/laravel-server-setup-v3.log"
INSTALL_START_TIME=$(date +%s)
CONFIG_BACKUP_DIR="/root/laravel-setup-backup-$(date +%Y%m%d-%H%M%S)"

# System Information
CPU_CORES=0
RAM_GB=0
AVAILABLE_RAM_GB=0
DISK_GB=0
DISK_FREE_GB=0
SERVER_TYPE=""
OS=""
OS_VERSION=""

# User Selections
SETUP_MODE=""
WEB_SERVER=""
PHP_VERSION=""
DATABASE_TYPE=""
DATABASE_MODE=""
INSTALL_QUEUE="false"
INSTALL_CRON="false"
INSTALL_MONITORING="false"
USE_REMOTE_DB="false"

# Database Credentials
DB_HOST=""
DB_PORT=""
DB_NAME=""
DB_USER=""
DB_PASS=""

# Laravel Configuration
LARAVEL_PATH=""
REPO_URL=""
REPO_NAME=""
APP_NAME=""
APP_ENV="production"
APP_DEBUG="false"
APP_URL=""
DOMAIN_NAME=""

# Queue Configuration
QUEUE_DRIVER="database"
QUEUE_WORKERS=2
QUEUE_NAMES="default"

# Monitoring
PROMETHEUS_VERSION="2.48.1"
NODE_EXPORTER_VERSION="1.7.0"
GRAFANA_PORT="3000"

#############################################################################
# LOGGING FUNCTIONS
#############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_step() {
    echo -e "${CYAN}[→]${NC} $1" | tee -a "$INSTALL_LOG"
}

#############################################################################
# UI HELPER FUNCTIONS
#############################################################################

print_header() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}     ${BOLD}Laravel Server Setup Script v${SCRIPT_VERSION}${NC}                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}     ${CYAN}Automated • Interactive • Production-Ready${NC}                 ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_box_start() {
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────┐${NC}"
}

print_box_item() {
    echo -e "${CYAN}│${NC} $1"
}

print_box_end() {
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
}

draw_progress_bar() {
    local progress=$1
    local total=50
    local completed=$((progress * total / 100))
    local remaining=$((total - completed))
    
    printf "${GREEN}["
    printf "%${completed}s" | tr ' ' '█'
    printf "${NC}%${remaining}s" | tr ' ' '░'
    printf "${GREEN}]${NC} %3d%%" "$progress"
}

get_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [ -n "$default" ]; then
        read -p "$(echo -e ${CYAN}${prompt}${NC} [${GREEN}${default}${NC}]: )" input
        eval $var_name="${input:-$default}"
    else
        read -p "$(echo -e ${CYAN}${prompt}${NC}: )" input
        eval $var_name="$input"
    fi
}

get_password() {
    local prompt=$1
    local var_name=$2
    
    read -s -p "$(echo -e ${CYAN}${prompt}${NC}: )" password
    echo ""
    eval $var_name="$password"
}

confirm() {
    local prompt=$1
    local default=${2:-n}
    
    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${YELLOW}${prompt}${NC} [Y/n]: )" response
        case "$response" in
            [nN][oO]|[nN]) return 1 ;;
            *) return 0 ;;
        esac
    else
        read -p "$(echo -e ${YELLOW}${prompt}${NC} [y/N]: )" response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

error_exit() {
    log_error "$1"
    echo ""
    echo -e "${RED}Installation failed. Check logs: $INSTALL_LOG${NC}"
    exit 1
}

#############################################################################
# SYSTEM DETECTION
#############################################################################

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        error_exit "Please run this script as root or with sudo"
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        error_exit "Cannot detect OS. This script supports Ubuntu/Debian and RHEL/CentOS"
    fi
    
    log_info "Detected OS: $OS $OS_VERSION"
    
    case $OS in
        ubuntu|debian)
            log_success "Supported OS detected"
            ;;
        centos|rhel|fedora)
            log_success "Supported OS detected"
            ;;
        *)
            error_exit "Unsupported OS: $OS. This script supports Ubuntu/Debian and RHEL/CentOS"
            ;;
    esac
}

detect_system_resources() {
    print_section "🔍 Analyzing Your Server"
    
    CPU_CORES=$(nproc)
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    AVAILABLE_RAM_GB=$(free -g | awk '/^Mem:/{print $7}')
    DISK_GB=$(df -BG / | awk 'NR==2 {print $2}' | sed 's/G//')
    DISK_FREE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    # Determine server type
    if [ "$RAM_GB" -ge 8 ] && [ "$CPU_CORES" -ge 4 ]; then
        SERVER_TYPE="High-Performance"
        QUEUE_WORKERS=$((CPU_CORES * 2))
    elif [ "$RAM_GB" -ge 4 ] && [ "$CPU_CORES" -ge 2 ]; then
        SERVER_TYPE="Medium-Performance"
        QUEUE_WORKERS=$CPU_CORES
    else
        SERVER_TYPE="Basic"
        QUEUE_WORKERS=2
    fi
    
    print_box_start
    print_box_item "  ${BOLD}Operating System:${NC} $OS $OS_VERSION"
    print_box_item "  ${BOLD}CPU Cores:${NC} $CPU_CORES"
    print_box_item "  ${BOLD}Total RAM:${NC} ${RAM_GB}GB (${AVAILABLE_RAM_GB}GB available)"
    print_box_item "  ${BOLD}Total Disk:${NC} ${DISK_GB}GB (${DISK_FREE_GB}GB free)"
    print_box_item ""
    print_box_item "  ${BOLD}Server Classification:${NC} ${CYAN}$SERVER_TYPE${NC}"
    print_box_item "  ${BOLD}Recommended Queue Workers:${NC} ${CYAN}$QUEUE_WORKERS${NC}"
    print_box_end
    echo ""
    
    # Check minimum requirements
    if [ "$DISK_FREE_GB" -lt 5 ]; then
        log_warning "Low disk space (${DISK_FREE_GB}GB free). Recommended: 10GB+"
        if ! confirm "Continue anyway?"; then
            exit 0
        fi
    fi
    
    sleep 2
}

#############################################################################
# MAIN MENU
#############################################################################

show_main_menu() {
    print_header
    
    echo -e "${BOLD}What would you like to set up today?${NC}"
    echo ""
    
    print_box_start
    print_box_item "${BOLD}COMPLETE SOLUTIONS${NC}"
    print_box_item ""
    print_box_item "  ${GREEN}1)${NC} ${BOLD}Full Laravel Stack${NC} ${GREEN}(Recommended)${NC}"
    print_box_item "     → Web server + PHP + Database + Redis + Queue + Cron"
    print_box_item ""
    print_box_item "  ${GREEN}2)${NC} ${BOLD}Full Stack + Monitoring${NC}"
    print_box_item "     → Everything + Prometheus + Grafana"
    print_box_item ""
    print_box_item "${BOLD}COMPONENT SETUP${NC}"
    print_box_item ""
    print_box_item "  ${GREEN}3)${NC} Web Server Only (Apache/Nginx/Caddy/FrankenPHP)"
    print_box_item "  ${GREEN}4)${NC} Database Only (MySQL/PostgreSQL - Local or Remote)"
    print_box_item "  ${GREEN}5)${NC} Queue Workers Only"
    print_box_item "  ${GREEN}6)${NC} Monitoring Stack Only (Prometheus + Grafana)"
    print_box_item ""
    print_box_item "${BOLD}OTHER OPTIONS${NC}"
    print_box_item ""
    print_box_item "  ${GREEN}0)${NC} Inspect Current System"
    print_box_item "  ${GREEN}q)${NC} Exit"
    print_box_end
    echo ""
    
    get_input "Select option [1-6, 0, q]" "1" choice
    
    case $choice in
        1) SETUP_MODE="full_stack" ;;
        2) SETUP_MODE="full_stack_monitoring" ;;
        3) SETUP_MODE="webserver_only" ;;
        4) SETUP_MODE="database_only" ;;
        5) SETUP_MODE="queue_only" ;;
        6) SETUP_MODE="monitoring_only" ;;
        0) inspect_system; show_main_menu ;;
        q|Q) exit 0 ;;
        *) 
            log_error "Invalid option selected"
            sleep 2
            show_main_menu
            ;;
    esac
    
    log_info "Selected setup mode: $SETUP_MODE"
}

inspect_system() {
    print_header
    print_section "🔍 System Inspection"
    
    echo -e "${BOLD}Checking for existing installations...${NC}"
    echo ""
    
    print_box_start
    systemctl is-active --quiet nginx 2>/dev/null && print_box_item "  [${GREEN}✓${NC}] Nginx is running" || print_box_item "  [${RED}✗${NC}] Nginx not detected"
    systemctl is-active --quiet apache2 2>/dev/null && print_box_item "  [${GREEN}✓${NC}] Apache is running" || print_box_item "  [${RED}✗${NC}] Apache not detected"
    command -v php &> /dev/null && print_box_item "  [${GREEN}✓${NC}] PHP $(php -v | head -n 1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2) installed" || print_box_item "  [${RED}✗${NC}] PHP not installed"
    systemctl is-active --quiet mysql 2>/dev/null && print_box_item "  [${GREEN}✓${NC}] MySQL running" || print_box_item "  [${RED}✗${NC}] MySQL not detected"
    systemctl is-active --quiet postgresql 2>/dev/null && print_box_item "  [${GREEN}✓${NC}] PostgreSQL running" || print_box_item "  [${RED}✗${NC}] PostgreSQL not detected"
    if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
        print_box_item "  [${GREEN}✓${NC}] Redis running"
    else
        print_box_item "  [${RED}✗${NC}] Redis not detected"
    fi
    systemctl is-active --quiet supervisor 2>/dev/null && print_box_item "  [${GREEN}✓${NC}] Supervisor running" || print_box_item "  [${RED}✗${NC}] Supervisor not detected"
    systemctl is-active --quiet prometheus 2>/dev/null && print_box_item "  [${GREEN}✓${NC}] Prometheus running" || print_box_item "  [${RED}✗${NC}] Prometheus not detected"
    systemctl is-active --quiet grafana-server 2>/dev/null && print_box_item "  [${GREEN}✓${NC}] Grafana running" || print_box_item "  [${RED}✗${NC}] Grafana not detected"
    systemctl is-active --quiet node_exporter 2>/dev/null && print_box_item "  [${GREEN}✗${NC}] Node Exporter running" || print_box_item "  [${RED}✗${NC}] Node Exporter not detected"
    print_box_end
    echo ""
    
    read -p "Press Enter to continue..."
}

#############################################################################
# LOAD MODULES
#############################################################################

load_modules() {
    log_step "Loading modules..."
    
    # Check if modules exist
    if [ ! -d "$MODULES_DIR" ]; then
        error_exit "Modules directory not found: $MODULES_DIR"
    fi
    
    # Source all module files
    for module in "$MODULES_DIR"/*.sh; do
        if [ -f "$module" ]; then
            source "$module"
            log_info "Loaded module: $(basename $module)"
        fi
    done
    
    log_success "All modules loaded successfully"
}

#############################################################################
# INSTALLATION ORCHESTRATION
#############################################################################

run_installation() {
    print_section "🚀 Starting Installation"
    
    case $SETUP_MODE in
        "full_stack")
            install_full_stack
            ;;
        "full_stack_monitoring")
            install_full_stack
            install_monitoring_stack
            ;;
        "webserver_only")
            select_and_install_webserver
            ;;
        "database_only")
            configure_and_install_database
            ;;
        "queue_only")
            install_queue_workers
            ;;
        "monitoring_only")
            install_monitoring_stack
            ;;
        *)
            error_exit "Unknown setup mode: $SETUP_MODE"
            ;;
    esac
}

install_full_stack() {
    log_step "Installing Full Laravel Stack..."
    
    # 1. Install dependencies
    install_system_dependencies
    
    # 2. Select and install web server
    select_and_install_webserver
    
    # 3. Install PHP
    select_and_install_php
    
    # 4. Configure database
    configure_and_install_database
    
    # 5. Configure Redis (optional but recommended)
    configure_redis_setup
    
    # 6. Install Composer
    install_composer_tool
    
    # 7. Setup Laravel project
    setup_laravel_project
    
    # 8. Setup queue workers (if requested)
    if [ "$INSTALL_QUEUE" = "true" ]; then
        install_queue_workers
    fi
    
    # 9. Setup cron scheduler (if requested)
    if [ "$INSTALL_CRON" = "true" ]; then
        setup_cron_scheduler
    fi
    
    log_success "Full Laravel Stack installed successfully"
}

#############################################################################
# POST-INSTALLATION
#############################################################################

show_installation_summary() {
    local server_ip=$(hostname -I | awk '{print $1}')
    local install_end_time=$(date +%s)
    local total_time=$((install_end_time - INSTALL_START_TIME))
    
    print_header
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                ${BOLD}🎉 Installation Complete! 🎉${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_box_start
    print_box_item "  ${BOLD}Installation Time:${NC} $((total_time / 60)) minutes $((total_time % 60)) seconds"
    print_box_item "  ${BOLD}Log File:${NC} $INSTALL_LOG"
    print_box_item "  ${BOLD}Backup Location:${NC} $CONFIG_BACKUP_DIR"
    print_box_end
    echo ""
    
    print_section "📍 Access Points"
    
    print_box_start
    if [ -n "$DOMAIN_NAME" ]; then
        print_box_item "  ${BOLD}Laravel Application:${NC} http://${DOMAIN_NAME}"
    else
        print_box_item "  ${BOLD}Laravel Application:${NC} http://${server_ip}"
    fi
    
    if [ "$INSTALL_MONITORING" = "true" ]; then
        print_box_item "  ${BOLD}Prometheus:${NC} http://${server_ip}:9090"
        print_box_item "  ${BOLD}Grafana:${NC} http://${server_ip}:3000 (admin/admin)"
        print_box_item "  ${BOLD}Node Exporter:${NC} http://${server_ip}:9100/metrics"
    fi
    print_box_end
    echo ""
    
    print_section "📋 Installed Components"
    
    print_box_start
    [ -n "$WEB_SERVER" ] && print_box_item "  [${GREEN}✓${NC}] Web Server: $WEB_SERVER"
    [ -n "$PHP_VERSION" ] && print_box_item "  [${GREEN}✓${NC}] PHP: $PHP_VERSION"
    [ -n "$DATABASE_TYPE" ] && print_box_item "  [${GREEN}✓${NC}] Database: $DATABASE_TYPE ($DATABASE_MODE)"
    if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
        print_box_item "  [${GREEN}✓${NC}] Redis: Installed"
        [ "$USE_REDIS_FOR_CACHE" = "true" ] && print_box_item "    → Cache: Redis"
        [ "$USE_REDIS_FOR_SESSION" = "true" ] && print_box_item "    → Session: Redis"
        [ "$USE_REDIS_FOR_QUEUE" = "true" ] && print_box_item "    → Queue: Redis"
    fi
    [ "$INSTALL_QUEUE" = "true" ] && print_box_item "  [${GREEN}✓${NC}] Queue Workers: $QUEUE_WORKERS workers"
    [ "$INSTALL_CRON" = "true" ] && print_box_item "  [${GREEN}✓${NC}] Cron Scheduler: Enabled"
    [ "$INSTALL_MONITORING" = "true" ] && print_box_item "  [${GREEN}✓${NC}] Monitoring: Prometheus + Grafana"
    print_box_end
    echo ""
    
    if confirm "Run health check now?" "y"; then
        run_health_check
    fi
    
    echo ""
    echo -e "${GREEN}Thank you for using Laravel Server Setup Script v${SCRIPT_VERSION}!${NC}"
    echo ""
}

run_health_check() {
    print_section "🏥 System Health Check"
    
    echo -e "${BOLD}Checking services...${NC}"
    echo ""
    
    local all_healthy=true
    
    # Check web server
    if [ -n "$WEB_SERVER" ]; then
        case $WEB_SERVER in
            "nginx")
                if systemctl is-active --quiet nginx; then
                    echo -e "  [${GREEN}✓${NC}] Nginx is running"
                else
                    echo -e "  [${RED}✗${NC}] Nginx is not running"
                    all_healthy=false
                fi
                ;;
            "apache")
                if systemctl is-active --quiet apache2; then
                    echo -e "  [${GREEN}✓${NC}] Apache is running"
                else
                    echo -e "  [${RED}✗${NC}] Apache is not running"
                    all_healthy=false
                fi
                ;;
        esac
    fi
    
    # Check PHP-FPM
    if [ -n "$PHP_VERSION" ]; then
        if systemctl is-active --quiet "php${PHP_VERSION}-fpm" 2>/dev/null; then
            echo -e "  [${GREEN}✓${NC}] PHP-FPM is running"
        else
            echo -e "  [${YELLOW}⚠${NC}] PHP-FPM status unknown"
        fi
    fi
    
    # Check database
    if [ "$DATABASE_MODE" = "local" ]; then
        case $DATABASE_TYPE in
            "mysql")
                if systemctl is-active --quiet mysql; then
                    echo -e "  [${GREEN}✓${NC}] MySQL is running"
                else
                    echo -e "  [${RED}✗${NC}] MySQL is not running"
                    all_healthy=false
                fi
                ;;
            "postgresql")
                if systemctl is-active --quiet postgresql; then
                    echo -e "  [${GREEN}✓${NC}] PostgreSQL is running"
                else
                    echo -e "  [${RED}✗${NC}] PostgreSQL is not running"
                    all_healthy=false
                fi
                ;;
        esac
    fi
    
    # Check supervisor
    if [ "$INSTALL_QUEUE" = "true" ]; then
        if systemctl is-active --quiet supervisor; then
            echo -e "  [${GREEN}✓${NC}] Supervisor is running"
        else
            echo -e "  [${RED}✗${NC}] Supervisor is not running"
            all_healthy=false
        fi
    fi
    
    # Check monitoring
    if [ "$INSTALL_MONITORING" = "true" ]; then
        if systemctl is-active --quiet prometheus; then
            echo -e "  [${GREEN}✓${NC}] Prometheus is running"
        else
            echo -e "  [${RED}✗${NC}] Prometheus is not running"
            all_healthy=false
        fi
        
        if systemctl is-active --quiet grafana-server; then
            echo -e "  [${GREEN}✓${NC}] Grafana is running"
        else
            echo -e "  [${RED}✗${NC}] Grafana is not running"
            all_healthy=false
        fi
    fi
    
    echo ""
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}✓ All services are healthy!${NC}"
    else
        echo -e "${YELLOW}⚠ Some services may need attention. Check logs for details.${NC}"
    fi
    echo ""
    
    read -p "Press Enter to continue..."
}

#############################################################################
# MAIN EXECUTION
#############################################################################

main() {
    # Initialize log
    touch "$INSTALL_LOG" 2>/dev/null || INSTALL_LOG="/tmp/laravel-server-setup-v3.log"
    chmod 666 "$INSTALL_LOG" 2>/dev/null || true
    
    log_info "====== Laravel Server Setup Script v${SCRIPT_VERSION} Started ======"
    log_info "Date: $(date)"
    log_info "User: $(whoami)"
    
    # Pre-flight checks
    check_root
    detect_os
    detect_system_resources
    
    # Load all modules
    load_modules
    
    # Show main menu and get user selections
    show_main_menu
    
    # Confirm before proceeding
    if ! confirm "Ready to begin installation?" "y"; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Run installation
    run_installation
    
    # Show summary
    show_installation_summary
    
    log_success "====== Installation completed successfully ======"
}

# Run main function
main
