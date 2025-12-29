#!/bin/bash

#############################################################################
# Complete Server Setup & Monitoring Suite
# Version: 2.0
# Author: FIGLAB
# 
# Combines:
# - Enhanced LAMP/LEMP Stack (Laravel optimized)
# - Prometheus + Grafana + Node Exporter (Monitoring)
# - Interactive UX with smart recommendations
#############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Global Variables
SCRIPT_VERSION="2.0"
INSTALL_LOG="/var/log/server-setup-v2.log"
INSTALL_START_TIME=$(date +%s)
COMPONENTS_TO_INSTALL=()
ESTIMATED_TIME=0
ESTIMATED_SPACE=0

CPU_CORES=0
RAM_GB=0
AVAILABLE_RAM_GB=0
DISK_GB=0
SERVER_TYPE=""

SETUP_TYPE=""
ENV_PROFILE=""
WEB_SERVER=""
PHP_VERSION=""
DB_TYPE=""
INSTALL_MONITORING=false
INSTALL_LARAVEL=false
USE_RECOMMENDATIONS=false
RECOMMENDED_QUEUE_PROCESSES=2

# Logging Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1" | tee -a "$INSTALL_LOG"
}

# UI Helper Functions
print_header() {
    clear
    echo -e "${GREEN}+================================================================+${NC}"
    echo -e "${GREEN}|${NC}     ${BOLD}Complete Server Setup & Monitoring Suite${NC}             ${GREEN}|${NC}"
    echo -e "${GREEN}|${NC}                  ${CYAN}Version $SCRIPT_VERSION - FIGLAB${NC}                      ${GREEN}|${NC}"
    echo -e "${GREEN}+================================================================+${NC}"
    echo ""
}

print_box() {
    local title="$1"
    echo -e "${CYAN}+-----------------------------------------------------------------+${NC}"
    echo -e "${CYAN}|${NC} ${BOLD}$title${NC}"
    echo -e "${CYAN}+-----------------------------------------------------------------+${NC}"
}

close_box() {
    echo -e "${CYAN}+-----------------------------------------------------------------+${NC}"
}

print_section() {
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
}

draw_progress_bar() {
    local progress=$1
    local total=20
    local completed=$((progress * total / 100))
    local remaining=$((total - completed))
    
    printf "["
    printf "%${completed}s" | tr ' ' '#'
    printf "%${remaining}s" | tr ' ' '.'
    printf "] %3d%%" "$progress"
}

# Input Helper Functions
get_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [ -n "$default" ]; then
        read -p "$(echo -e ${BLUE}${prompt}${NC} [${GREEN}${default}${NC}]: )" input
        eval $var_name="${input:-$default}"
    else
        read -p "$(echo -e ${BLUE}${prompt}${NC}: )" input
        eval $var_name="$input"
    fi
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

# System Detection Functions
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "Please run this script as root or with sudo"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "Cannot detect OS"
        exit 1
    fi
    
    log_info "Detected OS: $OS $VER"
}

detect_system_resources() {
    print_section "Analyzing Your Server"
    
    CPU_CORES=$(nproc)
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    AVAILABLE_RAM_GB=$(free -g | awk '/^Mem:/{print $7}')
    DISK_GB=$(df -BG / | awk 'NR==2 {print $2}' | sed 's/G//')
    DISK_FREE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$RAM_GB" -ge 8 ] && [ "$CPU_CORES" -ge 4 ]; then
        SERVER_TYPE="High-Performance"
        RECOMMENDED_QUEUE_PROCESSES=$((CPU_CORES * 2))
    elif [ "$RAM_GB" -ge 4 ] && [ "$CPU_CORES" -ge 2 ]; then
        SERVER_TYPE="Medium-Performance"
        RECOMMENDED_QUEUE_PROCESSES=$CPU_CORES
    else
        SERVER_TYPE="Basic"
        RECOMMENDED_QUEUE_PROCESSES=2
    fi
    
    echo -e "  ${GREEN}OS:${NC} $OS $VER"
    echo -e "  ${GREEN}CPU:${NC} $CPU_CORES cores"
    echo -e "  ${GREEN}RAM:${NC} ${RAM_GB}GB (${AVAILABLE_RAM_GB}GB available)"
    echo -e "  ${GREEN}Disk:${NC} ${DISK_GB}GB (${DISK_FREE_GB}GB free)"
    echo ""
    echo -e "  ${BOLD}Server Classification:${NC} ${CYAN}$SERVER_TYPE${NC}"
    echo ""
    
    sleep 2
}

# Main Menu
show_main_menu() {
    print_header
    
    echo -e "${CYAN}What would you like to set up today?${NC}"
    echo ""
    
    print_box "APPLICATION STACK"
    echo -e "${CYAN}|${NC} 1) ${BOLD}Full Laravel Stack Setup${NC}"
    echo -e "${CYAN}|${NC}    - Web server + PHP + Database + Queue + Scheduler"
    echo -e "${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} 2) ${BOLD}Laravel Components Only${NC}"
    echo -e "${CYAN}|${NC}    - Queue workers, Scheduler, Redis, etc."
    echo -e "${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} 3) ${BOLD}Database Setup Only${NC}"
    echo -e "${CYAN}|${NC}    - MySQL/PostgreSQL with optimization"
    close_box
    echo ""
    
    print_box "MONITORING & OBSERVABILITY"
    echo -e "${CYAN}|${NC} 4) ${BOLD}Full Monitoring Stack${NC}"
    echo -e "${CYAN}|${NC}    - Prometheus + Grafana + Node Exporter"
    echo -e "${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} 5) ${BOLD}Metrics Collection Only${NC}"
    echo -e "${CYAN}|${NC}    - Prometheus + Node Exporter"
    echo -e "${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} 6) ${BOLD}Visualization Only${NC}"
    echo -e "${CYAN}|${NC}    - Grafana dashboard"
    close_box
    echo ""
    
    print_box "COMPLETE SOLUTIONS"
    echo -e "${CYAN}|${NC} 7) ${BOLD}Laravel + Monitoring${NC} ${GREEN}(Recommended)${NC}"
    echo -e "${CYAN}|${NC}    - Everything you need for production"
    echo -e "${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} 8) ${BOLD}Quick Production Setup${NC}"
    echo -e "${CYAN}|${NC}    - Pre-configured production-ready stack"
    close_box
    echo ""
    
    print_box "OTHER OPTIONS"
    echo -e "${CYAN}|${NC} 0) ${BOLD}Inspect Current System${NC}"
    echo -e "${CYAN}|${NC} q) ${BOLD}Exit${NC}"
    close_box
    echo ""
    
    get_input "Select option [1-8, 0, q]" "" choice
    
    case $choice in
        1) SETUP_TYPE="full_laravel" ;;
        2) SETUP_TYPE="laravel_components" ;;
        3) SETUP_TYPE="database_only" ;;
        4) SETUP_TYPE="full_monitoring" ;;
        5) SETUP_TYPE="monitoring_metrics" ;;
        6) SETUP_TYPE="monitoring_viz" ;;
        7) SETUP_TYPE="complete_solution" ;;
        8) SETUP_TYPE="quick_production" ;;
        0) inspect_system; show_main_menu ;;
        q|Q) exit 0 ;;
        *) 
            log_error "Invalid option selected"
            sleep 2
            show_main_menu
            ;;
    esac
}

# Environment Profile Selection
select_environment_profile() {
    print_header
    print_section "Select Your Environment Profile"
    
    echo -e "1) ${BOLD}Development${NC}"
    echo -e "   - Debug enabled, minimal resources, local monitoring"
    echo ""
    echo -e "2) ${BOLD}Staging${NC}"
    echo -e "   - Production-like, with extra logging"
    echo ""
    echo -e "3) ${BOLD}Production${NC} ${GREEN}(Recommended for live servers)${NC}"
    echo -e "   - Optimized, secured, full monitoring"
    echo ""
    echo -e "4) ${BOLD}Custom${NC}"
    echo -e "   - Configure everything yourself"
    echo ""
    
    get_input "Select environment (1-4)" "3" env_choice
    
    case $env_choice in
        1) 
            ENV_PROFILE="development"
            APP_ENV="local"
            APP_DEBUG="true"
            ;;
        2) 
            ENV_PROFILE="staging"
            APP_ENV="staging"
            APP_DEBUG="true"
            ;;
        3) 
            ENV_PROFILE="production"
            APP_ENV="production"
            APP_DEBUG="false"
            ;;
        4) 
            ENV_PROFILE="custom"
            get_input "Enter APP_ENV" "production" APP_ENV
            if confirm "Enable debug mode?"; then
                APP_DEBUG="true"
            else
                APP_DEBUG="false"
            fi
            ;;
        *) 
            log_warning "Invalid choice, defaulting to Production"
            ENV_PROFILE="production"
            APP_ENV="production"
            APP_DEBUG="false"
            ;;
    esac
    
    log_success "Environment profile: $ENV_PROFILE"
}

# Smart Recommendations
show_recommendations() {
    print_header
    print_section "Recommended Configuration"
    
    echo -e "${BOLD}Based on your ${CYAN}$SERVER_TYPE${NC} ${BOLD}server and ${CYAN}$ENV_PROFILE${NC} ${BOLD}profile:${NC}"
    echo ""
    
    print_box "RECOMMENDED SETTINGS"
    echo -e "${CYAN}|${NC} + ${GREEN}PHP Workers:${NC} $((CPU_CORES * 2))"
    echo -e "${CYAN}|${NC} + ${GREEN}Queue Processes:${NC} $RECOMMENDED_QUEUE_PROCESSES"
    echo -e "${CYAN}|${NC} + ${GREEN}Prometheus Scrape:${NC} 15s"
    echo -e "${CYAN}|${NC} + ${GREEN}Expected Capacity:${NC} ~$((CPU_CORES * 100)) concurrent users"
    
    if [ "$ENV_PROFILE" = "production" ]; then
        echo -e "${CYAN}|${NC} + ${GREEN}Cache Driver:${NC} Redis (recommended)"
        echo -e "${CYAN}|${NC} + ${GREEN}Session Driver:${NC} Redis (recommended)"
        echo -e "${CYAN}|${NC} + ${GREEN}Queue Driver:${NC} Redis (recommended)"
    else
        echo -e "${CYAN}|${NC} + ${GREEN}Cache Driver:${NC} File (development)"
        echo -e "${CYAN}|${NC} + ${GREEN}Session Driver:${NC} File (development)"
        echo -e "${CYAN}|${NC} + ${GREEN}Queue Driver:${NC} Database (simple)"
    fi
    close_box
    echo ""
    
    if confirm "Use these recommendations?" "y"; then
        USE_RECOMMENDATIONS=true
        log_success "Using recommended configuration"
    else
        USE_RECOMMENDATIONS=false
        log_info "You'll configure settings manually"
    fi
}

# System Inspection
inspect_system() {
    print_header
    print_section "System Inspection"
    
    echo -e "${BOLD}Checking for existing installations...${NC}"
    echo ""
    
    systemctl is-active --quiet nginx 2>/dev/null && echo -e "  [+] ${GREEN}Nginx${NC} is running" || echo -e "  [-] Nginx not detected"
    systemctl is-active --quiet apache2 2>/dev/null && echo -e "  [+] ${GREEN}Apache${NC} is running" || echo -e "  [-] Apache not detected"
    command -v php &> /dev/null && echo -e "  [+] ${GREEN}PHP$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2)${NC} installed" || echo -e "  [-] PHP not installed"
    systemctl is-active --quiet mysql 2>/dev/null && echo -e "  [+] ${GREEN}MySQL${NC} running" || echo -e "  [-] MySQL not detected"
    systemctl is-active --quiet postgresql 2>/dev/null && echo -e "  [+] ${GREEN}PostgreSQL${NC} running" || echo -e "  [-] PostgreSQL not detected"
    systemctl is-active --quiet redis-server 2>/dev/null && echo -e "  [+] ${GREEN}Redis${NC} running" || echo -e "  [-] Redis not detected"
    systemctl is-active --quiet prometheus 2>/dev/null && echo -e "  [+] ${GREEN}Prometheus${NC} running" || echo -e "  [-] Prometheus not detected"
    systemctl is-active --quiet grafana-server 2>/dev/null && echo -e "  [+] ${GREEN}Grafana${NC} running" || echo -e "  [-] Grafana not detected"
    systemctl is-active --quiet node_exporter 2>/dev/null && echo -e "  [+] ${GREEN}Node Exporter${NC} running" || echo -e "  [-] Node Exporter not detected"
    
    echo ""
    read -p "Press Enter to continue..."
}

# Placeholder Installation Functions
install_full_laravel() {
    log_info "Installing Full Laravel Stack..."
    COMPONENTS_TO_INSTALL=("nginx" "php" "mysql" "redis" "supervisor" "composer")
    log_success "Full Laravel Stack installation started"
}

install_full_monitoring() {
    log_info "Installing Full Monitoring Stack..."
    COMPONENTS_TO_INSTALL=("prometheus" "node_exporter" "grafana")
    log_success "Full Monitoring Stack installation started"
}

install_complete_solution() {
    log_info "Installing Complete Solution..."
    COMPONENTS_TO_INSTALL=("nginx" "php" "mysql" "redis" "supervisor" "composer" "prometheus" "node_exporter" "grafana")
    log_success "Complete Solution installation started"
}

# Main Execution
main() {
    sudo touch "$INSTALL_LOG" 2>/dev/null || INSTALL_LOG="/tmp/server-setup-v2.log"
    sudo chmod 666 "$INSTALL_LOG" 2>/dev/null
    
    log_info "====== Server Setup Script Started ======"
    log_info "Version: $SCRIPT_VERSION"
    log_info "Date: $(date)"
    
    check_root
    detect_os
    detect_system_resources
    
    show_main_menu
    select_environment_profile
    show_recommendations
    
    case $SETUP_TYPE in
        "full_laravel")
            install_full_laravel
            ;;
        "full_monitoring")
            install_full_monitoring
            ;;
        "complete_solution")
            install_complete_solution
            ;;
        *)
            log_info "Setup type: $SETUP_TYPE"
            log_warning "Installation function not yet implemented"
            ;;
    esac
    
    INSTALL_END_TIME=$(date +%s)
    TOTAL_TIME=$((INSTALL_END_TIME - INSTALL_START_TIME))
    
    log_success "Process completed in $((TOTAL_TIME / 60)) minutes"
}

main
