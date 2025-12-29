# Server Setup Scripts

One-command server setup for Laravel applications and monitoring infrastructure.

> **Fork of** [sohag-pro/SingleCommand](https://github.com/sohag-pro/SingleCommand) with enhanced features and monitoring capabilities.

---

## Quick Start

### Version 2.0 (Recommended - New Enhanced UX)
```bash
curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/setup-v2.sh -o setup-v2.sh
chmod +x setup-v2.sh
sudo ./setup-v2.sh
```

### Version 1.0 (Original)
```bash
curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/setup.sh -o setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

---

## What's Included

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

## Installation Options (V2.0)

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

| Component | Purpose |
|-----------|---------|
| Nginx/Apache | Web Server |
| PHP 8.3 | Laravel Runtime |
| MySQL/PostgreSQL | Database |
| Redis | Cache/Queue/Sessions |
| Supervisor | Queue Workers |
| Prometheus | Metrics (V2.0) |
| Grafana | Dashboards (V2.0) |
| Node Exporter | System Metrics (V2.0) |

---

## Quick Commands

### Service Management
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

### Monitoring (V2.0)
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

| Feature | V1.0 | V2.0 |
|---------|------|------|
| Installation | Linear | Menu-driven |
| Monitoring | No | Yes (Full stack) |
| System Analysis | No | Yes (Auto) |
| Recommendations | Manual | Smart/Auto |
| Modular Install | No | Yes |

**Use V1.0 if**: You want the traditional approach
**Use V2.0 if**: You want monitoring and smart recommendations

---

## Documentation

- **Quick Start**: This README
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
