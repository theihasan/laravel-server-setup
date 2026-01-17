#!/bin/bash

#############################################################################
# MONITORING MODULE
# Prometheus + Grafana + Node Exporter
#############################################################################

install_monitoring_stack() {
    if ! confirm "Install monitoring stack (Prometheus + Grafana)?"; then
        INSTALL_MONITORING="false"
        log_info "Skipping monitoring installation"
        return 0
    fi
    
    INSTALL_MONITORING="true"
    
    print_section "📊 Monitoring Stack Installation"
    
    # Create system users
    create_monitoring_users
    
    # Install components
    install_prometheus_server
    install_node_exporter_agent
    install_grafana_server
    
    # Configure firewall
    configure_firewall_monitoring
    
    log_success "Monitoring stack installed successfully"
}

create_monitoring_users() {
    log_step "Creating monitoring system users..."
    
    # Create prometheus user
    if ! id -u prometheus >/dev/null 2>&1; then
        useradd --no-create-home --shell /bin/false prometheus
        log_success "User 'prometheus' created"
    fi
    
    # Create node_exporter user
    if ! id -u node_exporter >/dev/null 2>&1; then
        useradd --no-create-home --shell /bin/false node_exporter
        log_success "User 'node_exporter' created"
    fi
}

#############################################################################
# PROMETHEUS INSTALLATION
#############################################################################

install_prometheus_server() {
    log_step "Installing Prometheus ${PROMETHEUS_VERSION}..."
    
    cd /tmp
    
    # Download Prometheus
    wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" \
        || error_exit "Failed to download Prometheus"
    
    tar -xzf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
    
    # Create directories
    mkdir -p /etc/prometheus /var/lib/prometheus
    
    # Copy binaries
    cp "prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus" /usr/local/bin/
    cp "prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool" /usr/local/bin/
    cp -r "prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles" /etc/prometheus/
    cp -r "prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries" /etc/prometheus/
    
    # Set permissions
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
    
    # Cleanup
    rm -rf "/tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64"*
    
    log_success "Prometheus binaries installed"
    
    # Configure Prometheus
    configure_prometheus
    
    # Create systemd service
    create_prometheus_service
}

configure_prometheus() {
    log_step "Configuring Prometheus..."
    
    local scrape_interval="15s"
    
    cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: ${scrape_interval}
  evaluation_interval: ${scrape_interval}
  external_labels:
    monitor: 'laravel-server'
    environment: '${APP_ENV}'

# Alertmanager configuration (optional)
# alerting:
#   alertmanagers:
#     - static_configs:
#         - targets: ['localhost:9093']

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: 'prometheus'

  # Node Exporter (system metrics)
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'server'

  # Laravel Application (if using Laravel Prometheus exporter)
  - job_name: 'laravel'
    static_configs:
      - targets: ['localhost:9091']
        labels:
          instance: 'laravel-app'
EOF
    
    chown prometheus:prometheus /etc/prometheus/prometheus.yml
    
    log_success "Prometheus configured"
}

create_prometheus_service() {
    log_step "Creating Prometheus systemd service..."
    
    cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/introduction/overview/
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
    --web.enable-lifecycle \\
    --storage.tsdb.retention.time=30d

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

#############################################################################
# NODE EXPORTER INSTALLATION
#############################################################################

install_node_exporter_agent() {
    log_step "Installing Node Exporter ${NODE_EXPORTER_VERSION}..."
    
    cd /tmp
    
    # Download Node Exporter
    wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
        || error_exit "Failed to download Node Exporter"
    
    tar -xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    
    # Copy binary
    cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
    chown node_exporter:node_exporter /usr/local/bin/node_exporter
    
    # Cleanup
    rm -rf "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"*
    
    log_success "Node Exporter binary installed"
    
    # Create systemd service
    create_node_exporter_service
}

create_node_exporter_service() {
    log_step "Creating Node Exporter systemd service..."
    
    cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \\
    --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)(\$|/)

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

#############################################################################
# GRAFANA INSTALLATION
#############################################################################

install_grafana_server() {
    log_step "Installing Grafana..."
    
    case $OS in
        ubuntu|debian)
            # Add Grafana GPG key and repository
            apt-get install -y apt-transport-https software-properties-common
            wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
            echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" \
                | tee /etc/apt/sources.list.d/grafana.list
            
            apt-get update -qq
            apt-get install -y grafana || error_exit "Failed to install Grafana"
            ;;
            
        centos|rhel|fedora)
            cat > /etc/yum.repos.d/grafana.repo <<EOFREPO
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOFREPO
            
            yum install -y grafana || error_exit "Failed to install Grafana"
            ;;
    esac
    
    # Configure Grafana
    configure_grafana
    
    # Start Grafana
    systemctl daemon-reload
    systemctl enable grafana-server
    systemctl start grafana-server
    
    sleep 3
    
    if systemctl is-active --quiet grafana-server; then
        log_success "Grafana service is running"
    else
        log_warning "Failed to start Grafana"
    fi
    
    # Setup datasources and dashboards
    setup_grafana_datasources
}

configure_grafana() {
    log_step "Configuring Grafana..."
    
    local grafana_ini="/etc/grafana/grafana.ini"
    
    if [ -f "$grafana_ini" ]; then
        # Backup original
        cp "$grafana_ini" "${grafana_ini}.backup"
        
        # Update configuration
        sed -i "s/^;http_port = 3000/http_port = ${GRAFANA_PORT}/" "$grafana_ini"
        sed -i "s/^;domain = localhost/domain = ${DOMAIN_NAME}/" "$grafana_ini"
        
        log_success "Grafana configured"
    fi
}

setup_grafana_datasources() {
    log_step "Setting up Grafana datasources..."
    
    # Wait for Grafana to be ready
    sleep 5
    
    # Add Prometheus datasource
    curl -X POST -H "Content-Type: application/json" \
        -d '{
          "name":"Prometheus",
          "type":"prometheus",
          "url":"http://localhost:9090",
          "access":"proxy",
          "isDefault":true
        }' \
        http://admin:admin@localhost:${GRAFANA_PORT}/api/datasources 2>/dev/null || \
        log_warning "Failed to add Prometheus datasource (may already exist)"
    
    log_success "Grafana datasources configured"
    
    # Import dashboards
    import_grafana_dashboards
}

import_grafana_dashboards() {
    log_step "Importing Grafana dashboards..."
    
    # Import Node Exporter dashboard (ID: 1860)
    curl -X POST -H "Content-Type: application/json" \
        -d '{
          "dashboard": {
            "id": null,
            "uid": null,
            "title": "Node Exporter Full",
            "tags": ["node-exporter"],
            "timezone": "browser"
          },
          "folderId": 0,
          "overwrite": true
        }' \
        http://admin:admin@localhost:${GRAFANA_PORT}/api/dashboards/import 2>/dev/null || \
        log_info "Dashboard import skipped"
    
    log_success "Grafana dashboards imported"
}

#############################################################################
# FIREWALL CONFIGURATION
#############################################################################

configure_firewall_monitoring() {
    if ! confirm "Configure firewall for monitoring services?"; then
        log_info "Skipping firewall configuration"
        return 0
    fi
    
    log_step "Configuring firewall for monitoring..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 9090/tcp comment 'Prometheus' 2>/dev/null || true
        ufw allow 9100/tcp comment 'Node Exporter' 2>/dev/null || true
        ufw allow ${GRAFANA_PORT}/tcp comment 'Grafana' 2>/dev/null || true
        log_success "UFW rules added for monitoring"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=9090/tcp
        firewall-cmd --permanent --add-port=9100/tcp
        firewall-cmd --permanent --add-port=${GRAFANA_PORT}/tcp
        firewall-cmd --reload
        log_success "Firewalld rules added for monitoring"
    else
        log_warning "No supported firewall detected"
    fi
}

#############################################################################
# MONITORING DASHBOARD SUMMARY
#############################################################################

show_monitoring_summary() {
    local server_ip=$(hostname -I | awk '{print $1}')
    
    print_section "📊 Monitoring Stack Summary"
    
    print_box_start
    print_box_item ""
    print_box_item "  ${BOLD}Prometheus:${NC}"
    print_box_item "    URL: http://${server_ip}:9090"
    print_box_item "    Status: http://${server_ip}:9090/targets"
    print_box_item ""
    print_box_item "  ${BOLD}Grafana:${NC}"
    print_box_item "    URL: http://${server_ip}:${GRAFANA_PORT}"
    print_box_item "    Default Login: admin / admin"
    print_box_item "    ${YELLOW}⚠ Change default password immediately!${NC}"
    print_box_item ""
    print_box_item "  ${BOLD}Node Exporter:${NC}"
    print_box_item "    Metrics: http://${server_ip}:9100/metrics"
    print_box_item ""
    print_box_end
    
    echo ""
    log_info "Monitoring stack is ready!"
    log_warning "Remember to change Grafana default password"
}

#############################################################################
# MONITORING MANAGEMENT SCRIPT
#############################################################################

create_monitoring_management_script() {
    log_step "Creating monitoring management script..."
    
    cat > "/usr/local/bin/monitoring" <<'EOFSCRIPT'
#!/bin/bash

# Monitoring Stack Management Script

case "$1" in
    status)
        echo "=== Monitoring Stack Status ==="
        echo ""
        systemctl status prometheus --no-pager -l
        echo ""
        systemctl status node_exporter --no-pager -l
        echo ""
        systemctl status grafana-server --no-pager -l
        ;;
    start)
        echo "Starting monitoring services..."
        systemctl start prometheus node_exporter grafana-server
        ;;
    stop)
        echo "Stopping monitoring services..."
        systemctl stop prometheus node_exporter grafana-server
        ;;
    restart)
        echo "Restarting monitoring services..."
        systemctl restart prometheus node_exporter grafana-server
        ;;
    logs)
        SERVICE="${2:-prometheus}"
        echo "=== $SERVICE Logs ==="
        journalctl -u "$SERVICE" -f
        ;;
    urls)
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo "=== Monitoring URLs ==="
        echo "  Prometheus: http://$SERVER_IP:9090"
        echo "  Grafana:    http://$SERVER_IP:3000"
        echo "  Metrics:    http://$SERVER_IP:9100/metrics"
        ;;
    *)
        echo "Monitoring Stack Management"
        echo ""
        echo "Usage: monitoring {status|start|stop|restart|logs|urls}"
        echo ""
        echo "Commands:"
        echo "  status    - Show service status"
        echo "  start     - Start all monitoring services"
        echo "  stop      - Stop all monitoring services"
        echo "  restart   - Restart all monitoring services"
        echo "  logs      - View logs (optional: service name)"
        echo "  urls      - Show monitoring URLs"
        echo ""
        echo "Examples:"
        echo "  monitoring status"
        echo "  monitoring logs prometheus"
        echo "  monitoring urls"
        exit 1
        ;;
esac
EOFSCRIPT
    
    chmod +x /usr/local/bin/monitoring
    
    log_success "Monitoring management script created: /usr/local/bin/monitoring"
}
