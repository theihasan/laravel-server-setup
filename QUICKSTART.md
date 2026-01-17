# Quick Start Guide - Laravel Server Setup v3.0

## 🚀 5-Minute Setup

### Step 1: Download

```bash
git clone https://github.com/theihasan/laravel-server-setup.git
cd laravel-server-setup
```

### Step 2: Run

```bash
sudo ./setup-v3.sh
```

### Step 3: Follow Prompts

The script will guide you through:

1. **System Analysis** - Automatic detection of your server specs
2. **Setup Mode Selection** - Choose what to install
3. **Web Server** - Select Nginx, Apache, Caddy, or FrankenPHP
4. **PHP Version** - Choose 8.1, 8.2, 8.3, or 8.4
5. **Database** - Local MySQL/PostgreSQL or Remote
6. **Queue Workers** - Optional with Supervisor
7. **Cron Scheduler** - Optional task scheduling
8. **Monitoring** - Optional Prometheus + Grafana

### Step 4: Enjoy!

Access your Laravel application at your domain or server IP.

---

## 📱 Common Scenarios

### Scenario 1: New Server, Laravel from Git

```bash
sudo ./setup-v3.sh

# Selections:
- Setup: Full Laravel Stack
- Web Server: Nginx
- PHP: 8.3
- Database: Local MySQL
- Git Repository: https://github.com/your/repo.git
- Queue: Yes, Redis with 4 workers
- Cron: Yes
- Monitoring: No
```

**Time**: ~15 minutes  
**Result**: Production-ready Laravel server

---

### Scenario 2: Existing Server, Add Monitoring

```bash
sudo ./setup-v3.sh

# Selections:
- Setup: Monitoring Stack Only
- Prometheus: Yes
- Grafana: Yes
- Node Exporter: Yes
```

**Time**: ~5 minutes  
**Result**: Monitoring added to existing setup

---

### Scenario 3: Microservice with Remote DB

```bash
sudo ./setup-v3.sh

# Selections:
- Setup: Full Laravel Stack
- Web Server: FrankenPHP (modern & fast)
- PHP: 8.4
- Database: Remote
  - Host: db.aws.com
  - Credentials: [provided]
- Queue: Yes, Database driver
- Cron: Yes
- Monitoring: Yes
```

**Time**: ~20 minutes  
**Result**: Modern Laravel microservice with monitoring

---

## 🎯 What Gets Installed?

### Full Laravel Stack Includes:

- ✅ Web Server (your choice)
- ✅ PHP + Extensions
- ✅ Composer
- ✅ Database (local or configured for remote)
- ✅ Git + Project setup
- ✅ File permissions (ACL)
- ✅ Queue workers (optional)
- ✅ Cron scheduler (optional)
- ✅ Redis (if selected)

### Monitoring Stack Includes:

- ✅ Prometheus (metrics collection)
- ✅ Grafana (dashboards)
- ✅ Node Exporter (system metrics)
- ✅ Pre-configured dashboards

---

## 🔑 Default Credentials

| Service | Username | Password | Change? |
|---------|----------|----------|---------|
| MySQL | laravel_user | [auto-generated] | ✅ Yes |
| PostgreSQL | laravel_user | [auto-generated] | ✅ Yes |
| Grafana | admin | admin | ⚠️ **Required** |

**Passwords saved to**: `/root/.{mysql|pgsql}_laravel_password`

---

## 📊 Post-Installation

### Check Status

```bash
# Web server
systemctl status nginx

# PHP-FPM
systemctl status php8.3-fpm

# Database
systemctl status mysql

# Queue workers
laravel-queue status

# Monitoring
monitoring status
```

### View Your Site

```bash
# Get server IP
hostname -I

# Access
http://YOUR_SERVER_IP
```

### Configure Domain

Edit your web server config:
- Nginx: `/etc/nginx/sites-available/`
- Apache: `/etc/apache2/sites-available/`
- Caddy: `/etc/caddy/Caddyfile`

---

## 🆘 Quick Troubleshooting

### Issue: 502 Bad Gateway

```bash
# Check PHP-FPM
systemctl status php8.3-fpm
systemctl restart php8.3-fpm
```

### Issue: Database Connection Failed

```bash
# Check .env file
cat /var/www/html/project/.env | grep DB_

# Test connection
mysql -h 127.0.0.1 -u laravel_user -p laravel_db
```

### Issue: Queue Not Processing

```bash
# Check supervisor
supervisorctl status

# View logs
laravel-queue logs

# Restart workers
laravel-queue restart
```

### Issue: Permission Denied

```bash
# Fix permissions
cd /var/www/html/project
sudo chown -R www-data:www-data .
sudo chmod -R 775 storage bootstrap/cache
```

---

## 📞 Need Help?

- 📖 [Full Documentation](README-V3.md)
- 🐛 [Report Issues](https://github.com/theihasan/laravel-server-setup/issues)
- 💬 [Discussions](https://github.com/theihasan/laravel-server-setup/discussions)

---

## 🎓 Next Steps

1. **Secure Your Server**
   - Change default passwords
   - Set up firewall
   - Configure SSL/TLS

2. **Optimize Performance**
   - Tune PHP-FPM
   - Configure opcache
   - Set up Redis

3. **Monitor Your App**
   - Set up Grafana dashboards
   - Configure alerts
   - Monitor queue depth

4. **Backup Strategy**
   - Database backups
   - Code repository
   - Environment files

---

**Happy Coding! 🚀**
