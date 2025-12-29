#!/bin/bash

# ============================================================================
# INSTALLATION FUNCTIONS FOR SETUP-V2.SH
# This file contains all the actual installation logic
# ============================================================================

# ============================================================================
# DEPENDENCY INSTALLATION
# ============================================================================

install_dependencies() {
    log_step "Installing system dependencies..."
    
    case $OS in
        ubuntu|debian)
            apt-get update -qq || error_exit "Failed to update package lists"
            apt-get install -y wget curl tar software-properties-common \
                apt-transport-https ca-certificates acl git unzip \
                || error_exit "Failed to install dependencies"
            ;;
        centos|rhel|fedora)
            yum install -y wget curl tar acl git unzip \
                || error_exit "Failed to install dependencies"
            ;;
    esac
    
    log_success "Dependencies installed"
}

# ============================================================================
# USER CREATION
# ============================================================================

create_system_users() {
    log_step "Creating system users..."
    
    # Create prometheus user if needed
    if ! id -u prometheus >/dev/null 2>&1; then
        useradd --no-create-home --shell /bin/false prometheus
        log_success "User 'prometheus' created"
    fi
    
    # Create node_exporter user if needed
    if ! id -u node_exporter >/dev/null 2>&1; then
        useradd --no-create-home --shell /bin/false node_exporter
        log_success "User 'node_exporter' created"
    fi
    
    # Ensure www-data exists (usually default on Ubuntu/Debian)
    if ! id -u www-data >/dev/null 2>&1; then
        useradd --no-create-home --shell /bin/false www-data
        log_success "User 'www-data' created"
    fi
}

# ============================================================================
# PROMETHEUS INSTALLATION
# ============================================================================

install_prometheus() {
    local version=${1:-"2.48.1"}
    
    log_step "Installing Prometheus $version..."
    
    cd /tmp
    wget -q "https://github.com/prometheus/prometheus/releases/download/v${version}/prometheus-${version}.linux-amd64.tar.gz" \
        || error_exit "Failed to download Prometheus"
    
    tar -xzf "prometheus-${version}.linux-amd64.tar.gz" \
        || error_exit "Failed to extract Prometheus"
    
    mkdir -p /etc/prometheus /var/lib/prometheus
    
    cp "prometheus-${version}.linux-amd64/prometheus" /usr/local/bin/
    cp "prometheus-${version}.linux-amd64/promtool" /usr/local/bin/
    cp -r "prometheus-${version}.linux-amd64/consoles" /etc/prometheus/
    cp -r "prometheus-${version}.linux-amd64/console_libraries" /etc/prometheus/
    
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
    
    rm -rf "/tmp/prometheus-${version}.linux-amd64"*
    
    log_success "Prometheus $version installed"
}

configure_prometheus() {
    log_step "Configuring Prometheus..."
    
    local scrape_interval=${1:-"15"}
    local server_host=${2:-"localhost"}
    
    cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: ${scrape_interval}s
  evaluation_interval: ${scrape_interval}s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['${server_host}:9100']
EOF
    
    chown prometheus:prometheus /etc/prometheus/prometheus.yml
    
    log_success "Prometheus configured"
}

create_prometheus_service() {
    log_step "Creating Prometheus systemd service..."
    
    cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file=/etc/prometheus/prometheus.yml \\
    --storage.tsdb.path=/var/lib/prometheus/ \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries \\
    --web.enable-lifecycle

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable prometheus
    systemctl start prometheus
    
    sleep 3
    
    if systemctl is-active --quiet prometheus; then
        log_success "Prometheus service is running"
    else
        error_exit "Failed to start Prometheus service"
    fi
}

# ============================================================================
# NODE EXPORTER INSTALLATION
# ============================================================================

install_node_exporter() {
    local version=${1:-"1.7.0"}
    
    log_step "Installing Node Exporter $version..."
    
    cd /tmp
    wget -q "https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-amd64.tar.gz" \
        || error_exit "Failed to download Node Exporter"
    
    tar -xzf "node_exporter-${version}.linux-amd64.tar.gz" \
        || error_exit "Failed to extract Node Exporter"
    
    cp "node_exporter-${version}.linux-amd64/node_exporter" /usr/local/bin/
    chown node_exporter:node_exporter /usr/local/bin/node_exporter
    
    rm -rf "/tmp/node_exporter-${version}.linux-amd64"*
    
    log_success "Node Exporter $version installed"
}

create_node_exporter_service() {
    log_step "Creating Node Exporter systemd service..."
    
    cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
    
    sleep 2
    
    if systemctl is-active --quiet node_exporter; then
        log_success "Node Exporter service is running"
    else
        log_warning "Failed to start Node Exporter"
    fi
}

# ============================================================================
# GRAFANA INSTALLATION
# ============================================================================

install_grafana() {
    log_step "Installing Grafana..."
    
    case $OS in
        ubuntu|debian)
            wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
            echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" \
                | tee /etc/apt/sources.list.d/grafana.list
            
            apt-get update -qq
            apt-get install -y grafana || error_exit "Failed to install Grafana"
            ;;
        centos|rhel|fedora)
            cat > /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
            
            yum install -y grafana || error_exit "Failed to install Grafana"
            ;;
    esac
    
    systemctl daemon-reload
    systemctl enable grafana-server
    systemctl start grafana-server
    
    sleep 3
    
    if systemctl is-active --quiet grafana-server; then
        log_success "Grafana service is running"
    else
        log_warning "Failed to start Grafana"
    fi
}

# ============================================================================
# WEB SERVER INSTALLATION
# ============================================================================

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
    
    log_success "Nginx installed and running"
}

install_apache() {
    log_step "Installing Apache..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y apache2 || error_exit "Failed to install Apache"
            a2enmod rewrite
            ;;
        centos|rhel|fedora)
            yum install -y httpd || error_exit "Failed to install Apache"
            ;;
    esac
    
    systemctl enable apache2 || systemctl enable httpd
    systemctl start apache2 || systemctl start httpd
    
    log_success "Apache installed and running"
}

# ============================================================================
# PHP INSTALLATION
# ============================================================================

install_php() {
    local version=${1:-"8.3"}
    local db_extension=${2:-"mysql"}
    
    log_step "Installing PHP $version..."
    
    case $OS in
        ubuntu|debian)
            add-apt-repository -y ppa:ondrej/php
            apt-get update -qq
            
            apt-get install -y \
                "php${version}" \
                "php${version}-common" \
                "php${version}-opcache" \
                "php${version}-cli" \
                "php${version}-gd" \
                "php${version}-curl" \
                "php${version}-${db_extension}" \
                "php${version}-mbstring" \
                "php${version}-zip" \
                "php${version}-xml" \
                "php${version}-intl" \
                "php${version}-bcmath" \
                "php${version}-soap" \
                "php${version}-fpm" \
                "php${version}-imagick" \
                "php${version}-ldap" \
                "php${version}-redis" \
                || error_exit "Failed to install PHP"
            ;;
        centos|rhel|fedora)
            yum install -y "php${version}" "php${version}-fpm" "php${version}-mysqlnd" \
                || error_exit "Failed to install PHP"
            ;;
    esac
    
    log_success "PHP $version installed"
}

# ============================================================================
# DATABASE INSTALLATION
# ============================================================================

install_mysql() {
    log_step "Installing MySQL..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y mysql-server || error_exit "Failed to install MySQL"
            ;;
        centos|rhel|fedora)
            yum install -y mysql-server || error_exit "Failed to install MySQL"
            ;;
    esac
    
    systemctl enable mysql
    systemctl start mysql
    
    log_success "MySQL installed and running"
}

install_postgresql() {
    log_step "Installing PostgreSQL..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y postgresql postgresql-contrib \
                || error_exit "Failed to install PostgreSQL"
            ;;
        centos|rhel|fedora)
            yum install -y postgresql-server postgresql-contrib \
                || error_exit "Failed to install PostgreSQL"
            ;;
    esac
    
    systemctl enable postgresql
    systemctl start postgresql
    
    log_success "PostgreSQL installed and running"
}

# ============================================================================
# REDIS INSTALLATION
# ============================================================================

install_redis() {
    log_step "Installing Redis..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y redis-server || error_exit "Failed to install Redis"
            ;;
        centos|rhel|fedora)
            yum install -y redis || error_exit "Failed to install Redis"
            ;;
    esac
    
    systemctl enable redis-server || systemctl enable redis
    systemctl start redis-server || systemctl start redis
    
    log_success "Redis installed and running"
}

# ============================================================================
# SUPERVISOR INSTALLATION
# ============================================================================

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
    
    log_success "Supervisor installed and running"
}

# ============================================================================
# COMPOSER INSTALLATION
# ============================================================================

install_composer() {
    log_step "Installing Composer..."
    
    cd /tmp
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
    
    log_success "Composer installed"
}

# ============================================================================
# NODE.JS INSTALLATION
# ============================================================================

install_nodejs() {
    local version=${1:-"20"}
    
    log_step "Installing Node.js $version..."
    
    cd /tmp
    curl -sL "https://deb.nodesource.com/setup_${version}.x" -o nodesource_setup.sh
    bash nodesource_setup.sh
    
    case $OS in
        ubuntu|debian)
            apt-get install -y nodejs || error_exit "Failed to install Node.js"
            ;;
        centos|rhel|fedora)
            yum install -y nodejs || error_exit "Failed to install Node.js"
            ;;
    esac
    
    log_success "Node.js $version installed"
}

# ============================================================================
# FIREWALL CONFIGURATION
# ============================================================================

configure_firewall() {
    log_step "Configuring firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp comment 'HTTP'
        ufw allow 443/tcp comment 'HTTPS'
        ufw allow 9090/tcp comment 'Prometheus'
        ufw allow 9100/tcp comment 'Node Exporter'
        ufw allow 3000/tcp comment 'Grafana'
        log_success "UFW rules added"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=9090/tcp
        firewall-cmd --permanent --add-port=9100/tcp
        firewall-cmd --permanent --add-port=3000/tcp
        firewall-cmd --reload
        log_success "Firewalld rules added"
    else
        log_warning "No supported firewall detected"
    fi
}

# ============================================================================
# POST-INSTALLATION DASHBOARD
# ============================================================================

show_post_installation_dashboard() {
    local server_ip=$(hostname -I | awk '{print $1}')
    
    print_header
    echo -e "${GREEN}+================================================================+${NC}"
    echo -e "${GREEN}|${NC}               ${BOLD} Installation Complete!${NC}                       ${GREEN}|${NC}"
    echo -e "${GREEN}+================================================================+${NC}"
    echo ""
    
    echo -e "  ${BOLD}Total Time:${NC} $((TOTAL_TIME / 60)) minutes"
    echo -e " ${GREEN}All components installed successfully${NC}"
    echo -e " ${GREEN}All services running${NC}"
    echo ""
    
    print_box " ACCESS POINTS"
    
    if [ "$INSTALL_LARAVEL" = true ]; then
        echo -e "${CYAN}│${NC} ${BOLD}Laravel App:${NC}     http://${DOMAIN_NAME:-$server_ip}"
    fi
    
    if [ "$INSTALL_MONITORING" = true ]; then
        echo -e "${CYAN}│${NC} ${BOLD}Prometheus:${NC}      http://$server_ip:9090"
        echo -e "${CYAN}│${NC} ${BOLD}Grafana:${NC}         http://$server_ip:3000 ${YELLOW}(admin/admin)${NC}"
        echo -e "${CYAN}│${NC} ${BOLD}Node Metrics:${NC}    http://$server_ip:9100/metrics"
    fi
    
    close_box
    echo ""
    
    print_box " QUICK ACTIONS"
    echo -e "${CYAN}│${NC} 1)  Open Grafana setup wizard"
    echo -e "${CYAN}│${NC} 2)  Run system health check"
    echo -e "${CYAN}│${NC} 3)  View all credentials & URLs"
    echo -e "${CYAN}│${NC} 4)  Generate documentation"
    echo -e "${CYAN}│${NC} 5)  Backup configuration"
    echo -e "${CYAN}│${NC} 0)  Done - Exit"
    close_box
    echo ""
    
    get_input "Select action (0-5)" "0" action
    
    case $action in
        1) setup_grafana_wizard ;;
        2) run_health_check ;;
        3) show_credentials ;;
        4) generate_documentation ;;
        5) backup_configuration ;;
        0) exit 0 ;;
    esac
}

# ============================================================================
# HEALTH CHECK SYSTEM
# ============================================================================

run_health_check() {
    print_header
    print_section " System Health Check"
    
    echo "Running comprehensive diagnostics..."
    echo ""
    
    # Check services
    echo -e "${BOLD}SERVICES STATUS${NC}"
    check_service "nginx" "Nginx"
    check_service "apache2" "Apache"
    check_service "php8.3-fpm" "PHP-FPM"
    check_service "mysql" "MySQL"
    check_service "postgresql" "PostgreSQL"
    check_service "redis-server" "Redis"
    check_service "supervisor" "Supervisor"
    check_service "prometheus" "Prometheus"
    check_service "node_exporter" "Node Exporter"
    check_service "grafana-server" "Grafana"
    echo ""
    
    # Check resources
    echo -e "${BOLD}SYSTEM RESOURCES${NC}"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    check_threshold "CPU Usage" "$cpu_usage" "80" "%"
    check_threshold "Memory Usage" "$mem_usage" "85" "%"
    check_threshold "Disk Usage" "$disk_usage" "90" "%"
    echo ""
    
    read -p "Press Enter to continue..."
}

check_service() {
    local service=$1
    local name=$2
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "├─ $name                            ${GREEN} Running${NC}"
    else
        echo -e "├─ $name                            ${YELLOW} Not Running${NC}"
    fi
}

check_threshold() {
    local name=$1
    local current=$2
    local threshold=$3
    local unit=$4
    
    if (( $(echo "$current < $threshold" | bc -l) )); then
        echo -e "├─ $name                        ${current}${unit}      ${GREEN} Good${NC}"
    else
        echo -e "├─ $name                        ${current}${unit}      ${YELLOW} High${NC}"
    fi
}

# Placeholder functions for additional features
setup_grafana_wizard() {
    log_info "Grafana wizard not yet implemented"
    read -p "Press Enter to continue..."
}

show_credentials() {
    log_info "Credentials display not yet implemented"
    read -p "Press Enter to continue..."
}

generate_documentation() {
    log_info "Documentation generation not yet implemented"
    read -p "Press Enter to continue..."
}

backup_configuration() {
    log_info "Backup not yet implemented"
    read -p "Press Enter to continue..."
}
