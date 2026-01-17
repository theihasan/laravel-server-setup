# Grafana Dashboard Collection

This directory contains pre-configured Grafana dashboard JSON files for monitoring your Laravel application and infrastructure.

## 📊 Available Dashboards

### **1. Laravel Application Metrics** (`laravel-app-metrics.json`)

**Overview:** Comprehensive system monitoring dashboard for your Laravel server.

**Panels:**
- CPU Usage (%)
- Memory Usage (%)
- Disk Usage (%)
- Network Traffic (I/O)
- Load Average (1m, 5m, 15m)
- System Uptime
- Total Memory
- CPU Core Count

**Refresh Rate:** 30 seconds

**Data Source:** Prometheus + Node Exporter

**Use Case:** Monitor overall system health and resource utilization

---

### **2. Redis Monitoring** (`redis-monitoring.json`)

**Overview:** Detailed Redis performance and health monitoring.

**Panels:**
- Connected Clients
- Memory Used
- Total Keys
- Commands Per Second
- Memory Usage Over Time
- Keyspace Hit Rate (%)
- Network I/O
- Connected Clients Over Time
- Uptime
- Evicted Keys
- Expired Keys

**Refresh Rate:** 10 seconds

**Data Source:** Prometheus + Redis Exporter

**Use Case:** Monitor Redis cache/queue performance and troubleshoot issues

---

## 🚀 Installation

### **Method 1: Via Grafana UI**

1. Open Grafana in browser: `http://SERVER_IP:3000`
2. Login (default: admin/admin)
3. Navigate to: **Dashboards → Import**
4. Click **Upload JSON file**
5. Select dashboard file from this directory
6. Choose Prometheus datasource
7. Click **Import**

### **Method 2: Via API (Automated)**

```bash
# Set variables
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
DASHBOARD_FILE="laravel-app-metrics.json"

# Import dashboard
curl -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -d @"$DASHBOARD_FILE" \
  "$GRAFANA_URL/api/dashboards/db"
```

### **Method 3: Via Grafana CLI**

```bash
# Install dashboard from file
grafana-cli dashboard import laravel-app-metrics.json
```

---

## ⚙️ Configuration

### **Prerequisites**

1. **Grafana** must be installed and running
2. **Prometheus** must be configured as a datasource
3. **Node Exporter** must be running (for Laravel metrics)
4. **Redis Exporter** must be running (for Redis dashboard)

### **Setting Up Redis Exporter**

If Redis dashboard shows no data, install Redis Exporter:

```bash
# Download Redis Exporter
wget https://github.com/oliver006/redis_exporter/releases/download/v1.55.0/redis_exporter-v1.55.0.linux-amd64.tar.gz
tar xvfz redis_exporter-v1.55.0.linux-amd64.tar.gz
sudo mv redis_exporter-v1.55.0.linux-amd64/redis_exporter /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/redis_exporter.service <<EOF
[Unit]
Description=Redis Exporter
After=network.target

[Service]
Type=simple
User=redis
ExecStart=/usr/local/bin/redis_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable redis_exporter
sudo systemctl start redis_exporter
```

**Add to Prometheus configuration:**

```yaml
scrape_configs:
  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']
```

---

## 🎨 Customization

### **Modifying Panels**

1. Open dashboard in Grafana
2. Click panel title → **Edit**
3. Modify query, visualization, or settings
4. Click **Apply** and **Save dashboard**

### **Adding New Panels**

1. Click **Add panel** button
2. Configure data source and query
3. Choose visualization type
4. Customize display options
5. Save dashboard

### **Exporting Custom Dashboards**

1. Open dashboard
2. Click **Dashboard settings** (gear icon)
3. Go to **JSON Model**
4. Copy JSON
5. Save to file in this directory

---

## 📈 Dashboard Variables

You can add variables to make dashboards dynamic:

### **Example: Server Selection Variable**

1. Dashboard settings → **Variables** → **New**
2. Name: `server`
3. Type: `Query`
4. Query: `label_values(node_uname_info, instance)`
5. Use in queries: `node_cpu_seconds_total{instance="$server"}`

---

## 🔍 Troubleshooting

### **Dashboard Shows "No Data"**

**Check:**
1. Prometheus is running: `systemctl status prometheus`
2. Exporters are running: `systemctl status node_exporter`
3. Prometheus can scrape targets: Check `http://PROMETHEUS_IP:9090/targets`
4. Time range is appropriate (check top-right corner)
5. Datasource is configured correctly in Grafana

### **"Bad Gateway" Errors**

**Solution:**
```bash
# Restart Grafana
sudo systemctl restart grafana-server

# Check logs
sudo journalctl -u grafana-server -f
```

### **Panels Show Errors**

**Common Issues:**
- Wrong datasource selected
- Query syntax errors
- Missing metrics (exporter not running)
- Prometheus scrape configuration incorrect

---

## 📊 Dashboard Features

### **Time Range Selector**

- Located in top-right corner
- Quick ranges: Last 5m, 15m, 1h, 6h, 12h, 24h, 7d, 30d
- Custom range picker available

### **Refresh Options**

- Auto-refresh intervals: 5s, 10s, 30s, 1m, 5m, 15m, 30m, 1h
- Manual refresh button
- Live mode (continuous updates)

### **Annotations**

- Mark important events on graphs
- Add deployment markers
- Track incidents

### **Variables**

- Dynamic filtering
- Multi-select options
- Template variables in queries

---

## 🎯 Best Practices

### **Performance**

1. **Don't over-refresh:** Use appropriate refresh rates (30s-1m for most cases)
2. **Limit time ranges:** Shorter ranges = faster queries
3. **Use summary panels:** Aggregate data where possible
4. **Avoid complex queries:** Simplify PromQL when possible

### **Organization**

1. **Group related panels:** Use rows for logical grouping
2. **Consistent naming:** Clear, descriptive panel titles
3. **Add descriptions:** Help text for complex panels
4. **Use tags:** Categorize dashboards for easy discovery

### **Maintenance**

1. **Version control:** Export and commit dashboard JSON
2. **Document changes:** Add changelog in dashboard description
3. **Test before deploy:** Verify in staging environment
4. **Regular updates:** Keep up with Grafana versions

---

## 📚 Additional Dashboards

### **Recommended Community Dashboards**

Import from Grafana.com:

1. **Node Exporter Full** (ID: 1860)
   - Comprehensive system monitoring
   - `grafana-cli plugins install grafana-piechart-panel`

2. **MySQL Overview** (ID: 7362)
   - MySQL database metrics
   - Requires MySQL Exporter

3. **Nginx Metrics** (ID: 12708)
   - Nginx web server monitoring
   - Requires nginx-prometheus-exporter

4. **Redis Dashboard** (ID: 11835)
   - Alternative Redis monitoring
   - More detailed than our custom one

**Installation:**
```bash
# Via Grafana CLI
grafana-cli dashboards import 1860

# Via UI
Dashboards → Import → Enter ID: 1860
```

---

## 🔧 Advanced Configuration

### **Alerting**

Set up alerts for critical metrics:

1. Edit panel → **Alert** tab
2. Create alert rule
3. Define conditions (e.g., CPU > 80%)
4. Configure notification channel
5. Save dashboard

**Example Alert:**
```
Alert: High CPU Usage
Condition: avg() OF query(A, 5m, now) > 80
Send to: Email, Slack, PagerDuty
Message: "CPU usage exceeded 80% on {{server}}"
```

### **Provisioning**

Auto-deploy dashboards via config files:

Create `/etc/grafana/provisioning/dashboards/laravel.yaml`:

```yaml
apiVersion: 1

providers:
  - name: 'Laravel Dashboards'
    orgId: 1
    folder: 'Laravel'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /path/to/dashboards
```

---

## 📱 Mobile Access

Grafana dashboards are responsive and work on mobile devices:

- iOS/Android browsers supported
- Grafana mobile app available
- Touch-friendly interface
- Simplified view on small screens

---

## 🛡️ Security

### **Access Control**

1. Change default admin password
2. Create viewer accounts for read-only access
3. Use API keys for automation
4. Enable HTTPS
5. Configure authentication (LDAP, OAuth, etc.)

### **Dashboard Permissions**

Set per-dashboard permissions:

1. Dashboard settings → **Permissions**
2. Add roles/users
3. Set View/Edit/Admin permissions
4. Save changes

---

## 📝 Dashboard JSON Structure

Understanding the JSON format:

```json
{
  "dashboard": {
    "title": "Dashboard Name",
    "panels": [...],
    "time": {"from": "now-6h", "to": "now"},
    "refresh": "30s",
    "tags": ["tag1", "tag2"]
  },
  "overwrite": false
}
```

**Key Fields:**
- `panels`: Array of visualization panels
- `time`: Default time range
- `refresh`: Auto-refresh interval
- `tags`: Categorization tags
- `overwrite`: Replace existing dashboard with same UID

---

## 📞 Support

**Documentation:**
- [Grafana Docs](https://grafana.com/docs/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)

**Community:**
- [Grafana Community](https://community.grafana.com/)
- [Grafana Slack](https://grafana.slack.com/)

---

## 🎉 Contributing

Have a useful dashboard? Submit a pull request!

**Requirements:**
- JSON format
- Well-documented panels
- Tested with current Grafana version
- No hardcoded server values
- Clear description in this README

---

**Maintained by:** FIGLAB  
**Last Updated:** January 2026  
**Grafana Version:** 10.x+  
**Prometheus Version:** 2.48+
