# Laravel Server Setup Scripts

One-command server setup for Laravel applications with monitoring infrastructure.

> **Fork of** [sohag-pro/SingleCommand](https://github.com/sohag-pro/SingleCommand) with enhanced features, monitoring capabilities, and production-ready templates.

---

## Quick Start

### Version 3.0 (Latest - Production Ready) ⭐
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/install-v3.sh)
```

### Version 2.0 (Enhanced UX)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/setup-v2.sh)
```

### Version 1.0 (Original)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/setup.sh)
```

**Alternative (Download and Review First)**
```bash
# Version 3.0 (Recommended)
curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/install-v3.sh -o install-v3.sh
chmod +x install-v3.sh
sudo ./install-v3.sh

# Or clone the full repository
git clone https://github.com/theihasan/laravel-server-setup.git
cd laravel-server-setup
sudo ./setup-v3.sh

# Version 2.0
curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/setup-v2.sh -o setup-v2.sh
chmod +x setup-v2.sh
sudo ./setup-v2.sh

# Version 1.0
curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/setup.sh -o setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

---

## What's Included

### Version 3.0 Features ⭐ NEW!
- **Complete Modular Architecture**: 7 independent modules for maximum flexibility
- **4 Web Server Options**: Nginx, Apache, Caddy (auto-HTTPS), FrankenPHP (HTTP/2/3)
- **Full Redis Integration**: Cache, Session, Queue with PhpRedis/Predis support
- **Remote Database Support**: Use external MySQL/PostgreSQL servers
- **Configuration Templates**: 8 production-ready templates (Nginx, Apache, Caddy, Supervisor)
- **Grafana Dashboards**: Pre-built Laravel and Redis monitoring dashboards
- **Management CLIs**: 4 command-line tools (queue, scheduler, monitoring, redis)
- **Comprehensive Testing**: Detailed testing checklist and verification script
- **PHP Version Choice**: 8.1, 8.2, 8.3, 8.4
- **Documentation**: 8 comprehensive guides including testing and troubleshooting

### Version 2.0 Features
- **Smart Installation**: Modular setup (choose what you need)
- **Laravel Stack**: Nginx/Apache, PHP 8.3, MySQL/PostgreSQL, Redis, Supervisor
- **Monitoring**: Prometheus, Grafana, Node Exporter
- **Auto-Configuration**: Environment-aware with smart recommendations
- **System Analysis**: Automatic resource detection and optimization

### Version 1.0 Features
- **Complete LAMP/LEMP**: Web server, PHP 7.4-8.4, Database
- **Queue Workers**: Supervisor with multiple queue support
- **Laravel Ready**: Scheduler, migrations, permissions
- **Frontend Tools**: Node.js, NPM, Yarn, asset building

---

## Installation Options

### V3.0 Setup Modes
```
[1] Full Laravel Stack           - Complete web + database + Redis + queue + cron
[2] Full Stack + Monitoring      - Everything + Prometheus + Grafana
[3] Web Server Only              - Just Nginx/Apache/Caddy/FrankenPHP
[4] Database Only                - MySQL, PostgreSQL, or Remote DB
[5] Queue Workers Only           - Supervisor + Laravel queue workers
[6] Monitoring Only              - Prometheus + Grafana + Node Exporter
```

### V2.0 Setup Modes
```
[1] Full Laravel Stack          - Complete web application setup
[2] Laravel Components Only     - Add to existing server
[3] Database Only              - MySQL or PostgreSQL
[4] Full Monitoring Stack      - Prometheus + Grafana
[5] Metrics Collection         - Prometheus + Node Exporter
[6] Visualization Only         - Grafana dashboards
[7] Complete Solution          - Laravel + Monitoring (Best for Production)
[8] Quick Production Setup     - Pre-configured defaults
```

---

## Requirements

- Ubuntu 18.04+ or Debian 9+
- Root/sudo privileges
- 4GB+ RAM (2GB minimum)
- 20GB+ free disk space

---

## What Gets Installed

### V3.0 Components
| Component | Options | Purpose |
|-----------|---------|---------|
| **Web Server** | Nginx, Apache, Caddy, FrankenPHP | HTTP/HTTPS serving |
| **PHP** | 8.1, 8.2, 8.3, 8.4 | Laravel runtime |
| **Database** | MySQL, PostgreSQL, Remote | Data storage |
| **Redis** | Server + PhpRedis/Predis | Cache/Queue/Sessions |
| **Supervisor** | Queue workers | Background jobs |
| **Prometheus** | Metrics collector | Performance monitoring |
| **Grafana** | Dashboards | Visualization |
| **Node Exporter** | System metrics | Server monitoring |

### V2.0 Components
| Component | Purpose |
|-----------|---------|
| Nginx/Apache | Web Server |
| PHP 8.3 | Laravel Runtime |
| MySQL/PostgreSQL | Database |
| Redis | Cache/Queue/Sessions |
| Supervisor | Queue Workers |
| Prometheus | Metrics |
| Grafana | Dashboards |
| Node Exporter | System Metrics |

---

## Quick Commands

### V3.0 Management Tools
```bash
# Queue workers
laravel-queue status      # Check worker status
laravel-queue restart     # Restart workers
laravel-queue logs        # View logs
laravel-queue monitor     # Live monitoring

# Scheduler
laravel-scheduler list    # List scheduled tasks
laravel-scheduler run     # Run manually
laravel-scheduler logs    # View logs
laravel-scheduler tail    # Tail today's log

# Redis
redis-manage status       # Redis status
redis-manage info         # Redis info
redis-manage monitor      # Real-time monitoring
redis-manage cli          # Redis CLI
redis-manage keys         # List keys
redis-manage memory       # Memory usage

# Monitoring
monitoring status         # Service status
monitoring restart        # Restart services
monitoring logs           # View logs
monitoring urls           # Access URLs
```

### Service Management (All Versions)
```bash
# Check status
sudo systemctl status nginx mysql redis-server supervisor

# Restart services
sudo systemctl restart nginx
sudo supervisorctl restart projectname_*
```

### Laravel Operations
```bash
cd /var/www/html/your-project

# Run migrations
php artisan migrate

# Cache for production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Queue operations
php artisan queue:work
php artisan queue:restart
```

### Monitoring Access (V2.0 & V3.0)
```bash
# Access URLs
http://your-ip:9090    # Prometheus
http://your-ip:3000    # Grafana (admin/admin)
http://your-ip:9100    # Node Exporter metrics
```

---

## Troubleshooting

### Permission Issues
```bash
sudo chown -R www-data:www-data /var/www/html/your-project
sudo chmod -R 755 /var/www/html/your-project
sudo chmod -R 775 /var/www/html/your-project/storage
sudo chmod -R 775 /var/www/html/your-project/bootstrap/cache
```

### Queue Workers Not Running
```bash
sudo supervisorctl status
sudo supervisorctl restart projectname_*
tail -f /var/www/html/your-project/storage/logs/queue_default.log
```

### Database Connection Failed
```bash
# Check .env file
cat /var/www/html/your-project/.env | grep DB_

# Test connection
php artisan tinker
>>> DB::connection()->getPdo();
```

### Web Server Not Responding
```bash
# Apache
sudo apache2ctl configtest
sudo systemctl restart apache2

# Nginx
sudo nginx -t
sudo systemctl restart nginx
```

---

## Version Comparison

| Feature | V1.0 | V2.0 | V3.0 |
|---------|------|------|------|
| Installation | Linear | Menu-driven | Interactive Wizard |
| Web Servers | 2 | 2 | **4** (Nginx, Apache, Caddy, FrankenPHP) |
| PHP Versions | Multiple | 8.3 | **4 choices** (8.1-8.4) |
| Database Options | Local only | Local only | **Local + Remote** |
| Redis Integration | Basic | Basic | **Full** (Cache/Session/Queue) |
| Monitoring | No | Yes | **Yes + Dashboards** |
| Templates | No | No | **8 production templates** |
| Management CLIs | No | No | **4 tools** |
| System Analysis | No | Yes | **Enhanced** |
| Modular Install | No | Yes | **7 modules** |
| Documentation | Basic | Good | **Comprehensive (8 guides)** |

**Use V1.0 if**: You want the traditional simple approach  
**Use V2.0 if**: You want monitoring and smart recommendations  
**Use V3.0 if**: You want the most complete, production-ready solution ⭐

---

## Documentation

### Version 3.0 Documentation
- **Main Guide**: [README-V3.md](README-V3.md) - Complete feature documentation
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md) - 5-minute setup guide
- **Testing Guide**: [TESTING-CHECKLIST.md](TESTING-CHECKLIST.md) - Comprehensive testing
- **Implementation**: [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) - Technical details
- **Templates Guide**: [templates/README.md](templates/README.md) - Configuration templates
- **Dashboards Guide**: [dashboards/README.md](dashboards/README.md) - Grafana dashboards

### Other Versions
- **V2.0 Details**: [SETUP-V2-README.md](SETUP-V2-README.md)
- **Laravel Docs**: https://laravel.com/docs
- **Prometheus**: https://prometheus.io/docs
- **Grafana**: https://grafana.com/docs

---

## Support

- **Issues**: [GitHub Issues](https://github.com/theihasan/laravel-server-setup/issues)
- **Discussions**: [GitHub Discussions](https://github.com/theihasan/laravel-server-setup/discussions)
- **Email**: imabulhasan99@gmail.com

---

## License

MIT License - See [LICENSE](LICENSE) file

---

**Made for the Laravel community**
