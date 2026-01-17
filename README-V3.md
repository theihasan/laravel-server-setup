# Laravel Server Setup Script v3.0

> **Complete, Interactive, Production-Ready Server Setup**  
> Automated Laravel server configuration with user consent at every step

[![Version](https://img.shields.io/badge/version-3.0-blue.svg)](https://github.com/theihasan/laravel-server-setup)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 🎯 Features

### **Web Server Options**
- ✅ **Nginx** - High performance, battle-tested (Recommended)
- ✅ **Apache** - Traditional, .htaccess support
- ✅ **Caddy** - Modern, automatic HTTPS
- ✅ **FrankenPHP** - Native PHP server with HTTP/2 & HTTP/3

### **Database Flexibility**
- ✅ **Local MySQL** - Full server installation
- ✅ **Local PostgreSQL** - Full server installation
- ✅ **Remote Database** - Connect to external database
- ✅ **Auto-configuration** - Laravel .env automatically updated

### **Laravel Optimization**
- ✅ **Multiple PHP Versions** - 8.1, 8.2, 8.3, 8.4
- ✅ **Composer** - Latest version with optimization
- ✅ **Queue Workers** - Supervisor-managed with auto-restart
- ✅ **Cron Scheduler** - Automated task scheduling
- ✅ **Redis Support** - Complete Redis setup with cache/session/queue
- ✅ **File Permissions** - ACL-based for proper Laravel operation

### **Redis Integration** (NEW!)
- ✅ **Redis Server** - Full installation with secure configuration
- ✅ **PHP Extensions** - PhpRedis (C extension) or Predis (Pure PHP)
- ✅ **Flexible Usage** - Choose Cache, Session, Queue independently
- ✅ **Auto-Configuration** - Laravel .env automatically updated
- ✅ **Management CLI** - `redis-manage` command for operations
- ✅ **Connection Testing** - Verify Redis integration works

### **Monitoring Stack** (Optional)
- ✅ **Prometheus** - Metrics collection
- ✅ **Grafana** - Visualization dashboards
- ✅ **Node Exporter** - System metrics
- ✅ **Pre-configured Dashboards** - Ready to use

### **User Experience**
- ✅ **Interactive Menus** - Clear options at every step
- ✅ **User Consent** - Confirm before each major operation
- ✅ **Smart Recommendations** - Based on server specifications
- ✅ **Progress Indicators** - Real-time feedback
- ✅ **Health Checks** - Verify installation success
- ✅ **Management Scripts** - Easy service management

---

## 🚀 Quick Start

### **One-Line Installation**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/install-v3.sh)
```

### **Manual Installation**

```bash
# Clone the repository
git clone https://github.com/theihasan/laravel-server-setup.git
cd laravel-server-setup

# Make it executable
chmod +x setup-v3.sh

# Run the setup
sudo ./setup-v3.sh
```

---

## 📋 Requirements

- **OS**: Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+
- **Access**: Root or sudo privileges
- **Network**: Internet connection
- **Disk**: Minimum 5GB free space
- **RAM**: Minimum 1GB (2GB+ recommended)

---

## 🎬 Usage Examples

### **Example 1: Full Laravel Stack**

```bash
sudo ./setup-v3.sh

# Select: 1) Full Laravel Stack
# Choose: Nginx
# PHP: 8.3
# Database: Local MySQL
# Queue: Yes, with Redis
# Cron: Yes
# Monitoring: No
```

### **Example 2: Laravel + Monitoring**

```bash
sudo ./setup-v3.sh

# Select: 2) Full Stack + Monitoring
# Everything from Example 1, plus:
# - Prometheus
# - Grafana
# - Node Exporter
```

### **Example 3: Remote Database**

```bash
sudo ./setup-v3.sh

# Select: 1) Full Laravel Stack
# Choose: Nginx
# PHP: 8.3
# Database: 3) Use Remote Database
#   Host: db.example.com
#   Port: 3306
#   Name: production_db
#   User: app_user
#   Pass: ********
```

---

## 📂 Project Structure

```
laravel-server-setup/
├── setup-v3.sh                 # Main orchestration script
├── modules/
│   ├── webservers.sh          # Nginx, Apache, Caddy, FrankenPHP
│   ├── databases.sh           # MySQL, PostgreSQL, Remote DB
│   ├── laravel.sh             # PHP, Composer, Project setup
│   ├── queue.sh               # Supervisor, Queue workers
│   ├── cron.sh                # Task scheduler
│   ├── redis.sh               # Redis server & configuration
│   └── monitoring.sh          # Prometheus, Grafana
├── templates/                  # Configuration templates
├── dashboards/                 # Grafana dashboards
└── README-V3.md               # This file
```

---

## 🛠️ Management Commands

After installation, you'll have access to these management scripts:

### **Queue Workers**

```bash
# View queue status
laravel-queue status

# Restart queue workers
laravel-queue restart

# View queue logs
laravel-queue logs default

# Monitor queue workers
laravel-queue monitor
```

### **Laravel Scheduler**

```bash
# List scheduled tasks
laravel-scheduler list

# Run scheduler manually
laravel-scheduler run

# View scheduler logs
laravel-scheduler logs

# Tail today's log
laravel-scheduler tail
```

### **Monitoring Stack**

```bash
# Check monitoring status
monitoring status

# Restart monitoring services
monitoring restart

# View logs
monitoring logs prometheus

# Show access URLs
monitoring urls
```

### **Redis Management**

```bash
# Check Redis status
redis-manage status

# View Redis info
redis-manage info

# Monitor Redis in real-time
redis-manage monitor

# Access Redis CLI
redis-manage cli

# List all keys
redis-manage keys

# Check memory usage
redis-manage memory
```

---

## 📊 Access Points

After successful installation:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Laravel App** | `http://your-domain.com` | N/A |
| **Prometheus** | `http://server-ip:9090` | No auth |
| **Grafana** | `http://server-ip:3000` | admin / admin |
| **Node Exporter** | `http://server-ip:9100/metrics` | No auth |

⚠️ **Security**: Change default Grafana password immediately!

---

## 🔧 Configuration Details

### **Web Servers**

#### Nginx
- Config: `/etc/nginx/sites-available/`
- Logs: `/var/log/nginx/`
- Reload: `systemctl reload nginx`

#### Apache
- Config: `/etc/apache2/sites-available/`
- Logs: `/var/log/apache2/`
- Reload: `systemctl reload apache2`

#### Caddy
- Config: `/etc/caddy/Caddyfile`
- Logs: `/var/log/caddy/`
- Reload: `systemctl reload caddy`

#### FrankenPHP
- Service: `/etc/systemd/system/frankenphp-*.service`
- Restart: `systemctl restart frankenphp-*`

### **Queue Workers**

- Supervisor configs: `/etc/supervisor/conf.d/`
- Queue logs: `/var/www/html/project/storage/logs/queue_*.log`
- Manage: `supervisorctl status`

### **Cron Scheduler**

- Crontab: `crontab -u www-data -l`
- Logs: `/var/www/html/project/storage/logs/scheduler/`
- Test: `php artisan schedule:list`

### **Redis**

- Config: `/etc/redis/redis.conf`
- Logs: `/var/log/redis/redis-server.log`
- CLI: `redis-cli` or `redis-manage cli`
- Restart: `systemctl restart redis-server`

---

## 🔍 Troubleshooting

### **Installation Failed**

```bash
# Check installation log
cat /var/log/laravel-server-setup-v3.log

# Check service status
systemctl status nginx
systemctl status php8.3-fpm
systemctl status mysql
```

### **Queue Workers Not Running**

```bash
# Check supervisor status
supervisorctl status

# View queue logs
tail -f /var/www/html/project/storage/logs/queue_default.log

# Restart queue workers
laravel-queue restart
```

### **Scheduler Not Working**

```bash
# Check cron is configured
crontab -u www-data -l

# Test scheduler
cd /var/www/html/project
php artisan schedule:list
php artisan schedule:run -v

# View scheduler logs
laravel-scheduler logs
```

### **Database Connection Issues**

```bash
# Test MySQL connection
mysql -h 127.0.0.1 -u username -p database_name

# Test PostgreSQL connection
psql -h 127.0.0.1 -U username -d database_name

# Check Laravel .env
cat /var/www/html/project/.env | grep DB_
```

### **Permissions Issues**

```bash
# Fix Laravel permissions
cd /var/www/html/project
sudo chown -R www-data:www-data .
sudo chmod -R 775 storage bootstrap/cache
```

### **Redis Connection Issues**

```bash
# Test Redis connection
redis-cli ping

# Test with password
redis-cli -a your_password ping

# Check Redis status
redis-manage status

# Test from Laravel
cd /var/www/html/project
php artisan tinker
>>> Illuminate\Support\Facades\Redis::connection()->ping();
```

---

## 🔐 Security Recommendations

### **After Installation**

1. **Change Grafana Password**
   ```bash
   # Access: http://server-ip:3000
   # Login: admin / admin
   # Change password immediately
   ```

2. **Configure Firewall**
   ```bash
   # Allow only necessary ports
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```

3. **Secure Database**
   ```bash
   # Run MySQL secure installation
   mysql_secure_installation
   ```

4. **SSL/TLS Setup**
   ```bash
   # For Nginx/Apache
   certbot --nginx -d yourdomain.com
   
   # Caddy handles SSL automatically
   ```

5. **Update Laravel .env**
   ```bash
   # Set strong APP_KEY
   php artisan key:generate
   
   # Set APP_ENV to production
   APP_ENV=production
   APP_DEBUG=false
   ```

---

## 🎨 Customization

### **Add Custom Web Server Config**

Edit the appropriate file in `/etc/{nginx|apache2|caddy}/`

### **Customize Queue Workers**

Edit supervisor configs in `/etc/supervisor/conf.d/`

```bash
# Example: Increase workers
numprocs=8

# Then reload
supervisorctl reread
supervisorctl update
```

### **Add Custom Monitoring**

Edit Prometheus config: `/etc/prometheus/prometheus.yml`

```yaml
scrape_configs:
  - job_name: 'custom-app'
    static_configs:
      - targets: ['localhost:9091']
```

---

## 📈 Performance Tuning

### **PHP-FPM Optimization**

```bash
# Edit: /etc/php/8.3/fpm/pool.d/www.conf

# Adjust based on server resources
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20

# Restart
systemctl restart php8.3-fpm
```

### **MySQL Optimization**

```bash
# Edit: /etc/mysql/my.cnf

[mysqld]
innodb_buffer_pool_size = 1G
max_connections = 200
query_cache_size = 64M

# Restart
systemctl restart mysql
```

### **Nginx Optimization**

```bash
# Edit: /etc/nginx/nginx.conf

worker_processes auto;
worker_connections 2048;

# Enable caching
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=CACHEZONE:10m;

# Reload
systemctl reload nginx
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## 📝 Changelog

### v3.0 (Current)
- ✨ Complete rewrite with modular architecture
- ✨ Added FrankenPHP support
- ✨ Added Caddy support
- ✨ Remote database configuration
- ✨ Enhanced monitoring with Grafana
- ✨ Management scripts for queue, cron, monitoring
- ✨ Interactive menus with user consent
- ✨ Smart recommendations based on server specs

### v2.0
- ✨ Added Prometheus monitoring
- ✨ Enhanced queue configuration
- ✨ Better UI/UX

### v1.0
- ✨ Initial release
- ✨ Basic LAMP stack setup

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/theihasan/laravel-server-setup/issues)
- **Discussions**: [GitHub Discussions](https://github.com/theihasan/laravel-server-setup/discussions)

---

## 👏 Credits

- **Original Script**: [sohag-pro/SingleCommand](https://github.com/sohag-pro/SingleCommand)
- **Enhanced Version**: [theihasan](https://github.com/theihasan)
- **Contributors**: All amazing contributors

---

## ⭐ Star History

If this project helped you, please consider giving it a ⭐!

---

**Made with ❤️ by FIGLAB**
