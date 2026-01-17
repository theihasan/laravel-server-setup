# Laravel Server Setup v3.0 - Testing Checklist

This document provides a comprehensive checklist for testing the Laravel Server Setup Script v3.0 on various environments.

---

## 🎯 Test Environment Matrix

### **Supported Operating Systems**
- [ ] Ubuntu 20.04 LTS
- [ ] Ubuntu 22.04 LTS
- [ ] Ubuntu 24.04 LTS
- [ ] Debian 11 (Bullseye)
- [ ] Debian 12 (Bookworm)
- [ ] CentOS 8 Stream
- [ ] RHEL 8
- [ ] Rocky Linux 8

### **Test Scenarios**
- [ ] Fresh installation (clean OS)
- [ ] Installation on server with existing packages
- [ ] Re-run script after partial installation
- [ ] Script interruption and resume

---

## 📋 Pre-Installation Tests

### **System Requirements Check**
- [ ] Verify OS version detection works
- [ ] Verify CPU core count detection
- [ ] Verify RAM detection (total & available)
- [ ] Verify disk space detection
- [ ] Verify root/sudo privilege check
- [ ] Verify internet connectivity check

### **Script Permissions**
- [ ] Verify script is executable (`chmod +x setup-v3.sh`)
- [ ] Verify modules directory is accessible
- [ ] Verify templates directory is accessible
- [ ] Verify dashboards directory is accessible
- [ ] Verify log file can be created (`/var/log/laravel-server-setup-v3.log`)

---

## 🔧 Installation Tests

### **1. Full Laravel Stack (Basic)**

#### Configuration:
- Web Server: Nginx
- PHP Version: 8.3
- Database: Local MySQL
- Redis: Yes (Cache, Session, Queue)
- Queue Workers: Yes (2 workers)
- Cron Scheduler: Yes
- Monitoring: No

#### Test Steps:
- [ ] Run `sudo ./setup-v3.sh`
- [ ] Select "Full Laravel Stack"
- [ ] Choose Nginx as web server
- [ ] Select PHP 8.3
- [ ] Choose Local MySQL
- [ ] Install Redis with all features
- [ ] Setup queue workers
- [ ] Setup cron scheduler
- [ ] Skip monitoring

#### Verification:
- [ ] Nginx is running: `systemctl status nginx`
- [ ] PHP-FPM is running: `systemctl status php8.3-fpm`
- [ ] MySQL is running: `systemctl status mysql`
- [ ] Redis is running: `systemctl status redis-server`
- [ ] Supervisor is running: `systemctl status supervisor`
- [ ] Queue workers are running: `supervisorctl status`
- [ ] Cron job is configured: `crontab -u www-data -l`
- [ ] Laravel app is accessible via browser
- [ ] Laravel .env is properly configured
- [ ] File permissions are correct
- [ ] Management CLIs work:
  - [ ] `laravel-queue status`
  - [ ] `laravel-scheduler list`
  - [ ] `redis-manage status`

---

### **2. Full Stack + Monitoring**

#### Configuration:
- Web Server: Apache
- PHP Version: 8.2
- Database: Local PostgreSQL
- Redis: Yes (Cache only)
- Queue Workers: Yes (4 workers)
- Cron Scheduler: Yes
- Monitoring: Yes (Prometheus + Grafana)

#### Test Steps:
- [ ] Run `sudo ./setup-v3.sh`
- [ ] Select "Full Stack + Monitoring"
- [ ] Choose Apache as web server
- [ ] Select PHP 8.2
- [ ] Choose Local PostgreSQL
- [ ] Install Redis (cache only)
- [ ] Setup queue workers (4 workers)
- [ ] Setup cron scheduler
- [ ] Install monitoring stack

#### Verification:
- [ ] Apache is running: `systemctl status apache2`
- [ ] PHP-FPM is running: `systemctl status php8.2-fpm`
- [ ] PostgreSQL is running: `systemctl status postgresql`
- [ ] Redis is running: `systemctl status redis-server`
- [ ] Prometheus is running: `systemctl status prometheus`
- [ ] Grafana is running: `systemctl status grafana-server`
- [ ] Node Exporter is running: `systemctl status node_exporter`
- [ ] Prometheus UI accessible: `http://SERVER_IP:9090`
- [ ] Grafana UI accessible: `http://SERVER_IP:3000`
- [ ] Grafana default credentials work (admin/admin)
- [ ] Prometheus datasource auto-configured in Grafana
- [ ] Management CLI works: `monitoring status`

---

### **3. Caddy with Remote Database**

#### Configuration:
- Web Server: Caddy
- PHP Version: 8.4
- Database: Remote MySQL (provide credentials)
- Redis: No
- Queue Workers: No
- Cron Scheduler: Yes
- Monitoring: No

#### Test Steps:
- [ ] Setup remote MySQL database beforehand
- [ ] Run `sudo ./setup-v3.sh`
- [ ] Select "Full Laravel Stack"
- [ ] Choose Caddy as web server
- [ ] Select PHP 8.4
- [ ] Choose "Use Remote Database"
- [ ] Provide remote database credentials
- [ ] Skip Redis
- [ ] Skip queue workers
- [ ] Setup cron scheduler
- [ ] Skip monitoring

#### Verification:
- [ ] Caddy is running: `systemctl status caddy`
- [ ] PHP-FPM is running: `systemctl status php8.4-fpm`
- [ ] Remote database connection works
- [ ] Laravel .env has correct DB credentials
- [ ] Caddyfile is properly configured
- [ ] Automatic HTTPS works (if domain configured)
- [ ] Laravel app is accessible
- [ ] Migrations run successfully

---

### **4. FrankenPHP Setup**

#### Configuration:
- Web Server: FrankenPHP
- PHP Version: 8.3 (embedded)
- Database: Local MySQL
- Redis: Yes (Queue only)
- Queue Workers: Yes
- Cron Scheduler: Yes
- Monitoring: No

#### Test Steps:
- [ ] Run `sudo ./setup-v3.sh`
- [ ] Select "Full Laravel Stack"
- [ ] Choose FrankenPHP as web server
- [ ] Install Local MySQL
- [ ] Install Redis (queue only)
- [ ] Setup queue workers
- [ ] Setup cron scheduler

#### Verification:
- [ ] FrankenPHP service is running: `systemctl status frankenphp-*`
- [ ] MySQL is running: `systemctl status mysql`
- [ ] Redis is running: `systemctl status redis-server`
- [ ] Laravel app accessible with HTTP/2
- [ ] Queue connection uses Redis
- [ ] Performance benchmarks show improvement

---

### **5. Monitoring Only**

#### Configuration:
- Install only monitoring stack (no Laravel)

#### Test Steps:
- [ ] Run `sudo ./setup-v3.sh`
- [ ] Select "Monitoring Only"
- [ ] Complete installation

#### Verification:
- [ ] Prometheus installed and running
- [ ] Grafana installed and running
- [ ] Node Exporter installed and running
- [ ] All services accessible via browser
- [ ] System metrics visible in Prometheus
- [ ] Grafana dashboards can be imported

---

## 🔍 Component-Specific Tests

### **Web Server Tests**

#### Nginx:
- [ ] Virtual host configuration is correct
- [ ] PHP-FPM socket connection works
- [ ] Static file serving works
- [ ] Gzip compression enabled
- [ ] Security headers present
- [ ] Laravel routing works (try_files)
- [ ] Log files created and writable
- [ ] Reload works: `systemctl reload nginx`

#### Apache:
- [ ] Virtual host configuration is correct
- [ ] mod_rewrite enabled
- [ ] PHP-FPM proxy works
- [ ] .htaccess files work
- [ ] Security headers present
- [ ] Log files created and writable
- [ ] Reload works: `systemctl reload apache2`

#### Caddy:
- [ ] Caddyfile syntax is correct
- [ ] PHP-FPM connection works
- [ ] Automatic HTTPS works (with domain)
- [ ] Compression enabled
- [ ] Security headers present
- [ ] Reload works: `systemctl reload caddy`

#### FrankenPHP:
- [ ] Systemd service file correct
- [ ] HTTP/2 and HTTP/3 work
- [ ] Worker mode enabled
- [ ] Performance is optimal
- [ ] Restart works: `systemctl restart frankenphp-*`

---

### **Database Tests**

#### MySQL:
- [ ] Installation successful
- [ ] Root password set correctly
- [ ] New database created
- [ ] New user created with correct privileges
- [ ] Remote connection works (if configured)
- [ ] Laravel connection works
- [ ] Migrations run successfully
- [ ] Security configuration applied

#### PostgreSQL:
- [ ] Installation successful
- [ ] New database created
- [ ] New user created with correct role
- [ ] Authentication method correct (md5/scram-sha-256)
- [ ] Laravel connection works
- [ ] Migrations run successfully
- [ ] pg_hba.conf configured correctly

#### Remote Database:
- [ ] Connection test successful
- [ ] Credentials saved to .env
- [ ] Laravel can connect
- [ ] Migrations work
- [ ] No local database installed

---

### **Redis Tests**

- [ ] Redis server installed
- [ ] Redis running: `systemctl status redis-server`
- [ ] Password configured (if selected)
- [ ] PHP extension installed (PhpRedis or Predis)
- [ ] Laravel .env updated correctly
- [ ] REDIS_CLIENT set correctly
- [ ] Cache driver set to redis (if selected)
- [ ] Session driver set to redis (if selected)
- [ ] Queue connection set to redis (if selected)
- [ ] Connection test passes: `redis-cli ping`
- [ ] Laravel Redis connection works
- [ ] Management CLI works: `redis-manage status`
- [ ] Keys can be listed: `redis-manage keys`
- [ ] Memory usage visible: `redis-manage memory`

---

### **Queue Worker Tests**

- [ ] Supervisor installed and running
- [ ] Queue worker configuration created
- [ ] Workers are running: `supervisorctl status`
- [ ] Correct number of workers spawned
- [ ] Log files created
- [ ] Jobs are processed
- [ ] Failed jobs handled correctly
- [ ] Auto-restart works (kill a worker process)
- [ ] Management CLI works:
  - [ ] `laravel-queue status`
  - [ ] `laravel-queue restart`
  - [ ] `laravel-queue logs default`
  - [ ] `laravel-queue monitor`

---

### **Cron Scheduler Tests**

- [ ] Cron job added to www-data user
- [ ] Cron runs every minute
- [ ] Schedule log directory created
- [ ] Logs are written with timestamps
- [ ] Laravel scheduler works: `php artisan schedule:list`
- [ ] Manual run works: `php artisan schedule:run`
- [ ] Management CLI works:
  - [ ] `laravel-scheduler list`
  - [ ] `laravel-scheduler run`
  - [ ] `laravel-scheduler logs`
  - [ ] `laravel-scheduler tail`

---

### **Monitoring Tests**

#### Prometheus:
- [ ] Service running: `systemctl status prometheus`
- [ ] UI accessible: `http://SERVER_IP:9090`
- [ ] Configuration file correct
- [ ] Scrape configs present
- [ ] Targets are up (check /targets)
- [ ] Node Exporter metrics visible
- [ ] Query interface works

#### Grafana:
- [ ] Service running: `systemctl status grafana-server`
- [ ] UI accessible: `http://SERVER_IP:3000`
- [ ] Default login works (admin/admin)
- [ ] Prometheus datasource auto-added
- [ ] Datasource connection test passes
- [ ] Dashboards can be imported
- [ ] Laravel metrics dashboard works
- [ ] Redis monitoring dashboard works

#### Node Exporter:
- [ ] Service running: `systemctl status node_exporter`
- [ ] Metrics endpoint accessible: `http://SERVER_IP:9100/metrics`
- [ ] CPU metrics present
- [ ] Memory metrics present
- [ ] Disk metrics present
- [ ] Network metrics present

---

## 🛡️ Security Tests

### **File Permissions**
- [ ] Laravel project owned by www-data:www-data
- [ ] storage/ directory is writable (775)
- [ ] bootstrap/cache/ directory is writable (775)
- [ ] .env file has restricted permissions (600)
- [ ] Web server can read files
- [ ] Web server can write to storage/

### **Web Server Security**
- [ ] Hidden files (.git, .env) are not accessible via browser
- [ ] Composer files not accessible via browser
- [ ] Directory listing disabled
- [ ] Security headers present in HTTP responses:
  - [ ] X-Frame-Options
  - [ ] X-Content-Type-Options
  - [ ] X-XSS-Protection
  - [ ] Referrer-Policy
- [ ] Server signature hidden

### **Database Security**
- [ ] Root password set and secure
- [ ] Application user has limited privileges
- [ ] Remote root login disabled (MySQL)
- [ ] Test database removed (MySQL)
- [ ] Anonymous users removed (MySQL)

### **Redis Security**
- [ ] Password configured (if sensitive data)
- [ ] Bind to localhost only
- [ ] Protected mode enabled
- [ ] No dangerous commands exposed

---

## 🔄 Functionality Tests

### **Laravel Application**
- [ ] Homepage loads successfully
- [ ] Routes work correctly
- [ ] Database queries execute
- [ ] Cache works (if using Redis)
- [ ] Sessions work (if using Redis)
- [ ] File uploads work
- [ ] Asset compilation works (if using Node.js)
- [ ] Artisan commands work
- [ ] Scheduled tasks execute

### **Performance Tests**
- [ ] Page load time acceptable (<2s)
- [ ] Static assets cached properly
- [ ] Gzip/Brotli compression works
- [ ] Database query performance acceptable
- [ ] Redis response time acceptable (<1ms)
- [ ] Queue jobs process quickly

---

## 📊 Logging Tests

- [ ] Installation log created: `/var/log/laravel-server-setup-v3.log`
- [ ] Web server logs created and writable
- [ ] PHP-FPM logs created and writable
- [ ] Laravel logs created: `storage/logs/laravel.log`
- [ ] Queue worker logs created
- [ ] Scheduler logs created
- [ ] Log rotation configured (if applicable)

---

## 🔧 Management CLI Tests

### laravel-queue
- [ ] `laravel-queue status` shows worker status
- [ ] `laravel-queue restart` restarts workers
- [ ] `laravel-queue stop` stops workers
- [ ] `laravel-queue start` starts workers
- [ ] `laravel-queue logs <queue>` shows logs
- [ ] `laravel-queue monitor` works (if implemented)

### laravel-scheduler
- [ ] `laravel-scheduler list` shows scheduled tasks
- [ ] `laravel-scheduler run` runs scheduler manually
- [ ] `laravel-scheduler logs` shows recent logs
- [ ] `laravel-scheduler tail` tails today's log

### monitoring
- [ ] `monitoring status` shows all service statuses
- [ ] `monitoring restart` restarts all services
- [ ] `monitoring logs <service>` shows logs
- [ ] `monitoring urls` shows access URLs

### redis-manage
- [ ] `redis-manage status` shows Redis status
- [ ] `redis-manage info` shows Redis info
- [ ] `redis-manage monitor` monitors Redis
- [ ] `redis-manage cli` opens Redis CLI
- [ ] `redis-manage keys` lists all keys
- [ ] `redis-manage memory` shows memory usage

---

## 🚨 Error Handling Tests

### **Interruption Tests**
- [ ] Script handles Ctrl+C gracefully
- [ ] Partial installation can be resumed
- [ ] Error messages are clear and helpful
- [ ] Rollback works if installation fails

### **Edge Cases**
- [ ] Script handles low disk space
- [ ] Script handles low memory
- [ ] Script handles missing dependencies
- [ ] Script handles invalid user input
- [ ] Script handles network failures
- [ ] Script handles permission issues

### **Conflict Tests**
- [ ] Script detects existing Nginx installation
- [ ] Script detects existing MySQL installation
- [ ] Script handles port conflicts
- [ ] Script handles existing Laravel project

---

## 📝 Documentation Tests

- [ ] README.md is accurate and up-to-date
- [ ] QUICKSTART.md instructions work
- [ ] All management commands documented
- [ ] Troubleshooting section helpful
- [ ] Security recommendations clear
- [ ] Code examples work

---

## ✅ Final Validation

### **Post-Installation Checklist**
- [ ] Run verification script: `./verify-setup.sh`
- [ ] All services running
- [ ] All ports accessible
- [ ] Laravel app fully functional
- [ ] No error messages in logs
- [ ] System stable after 24 hours
- [ ] Restart server and verify all services auto-start

### **Performance Baseline**
- [ ] Document CPU usage at idle
- [ ] Document memory usage at idle
- [ ] Document response times
- [ ] Document queue processing speed

---

## 🐛 Bug Reporting Template

If you find issues, report them with:

```
**Environment:**
- OS: Ubuntu 22.04
- RAM: 4GB
- CPU: 2 cores

**Configuration:**
- Web Server: Nginx
- PHP: 8.3
- Database: MySQL
- Redis: Yes

**Steps to Reproduce:**
1. Run setup-v3.sh
2. Select...
3. ...

**Expected Behavior:**
...

**Actual Behavior:**
...

**Error Messages:**
```
[paste error messages]
```

**Log Excerpt:**
```
[paste relevant log lines]
```
```

---

## 📈 Performance Benchmarks

Document baseline performance for future reference:

```bash
# Web server performance
ab -n 1000 -c 10 http://your-domain.com/

# Redis performance
redis-benchmark -q -n 10000

# MySQL performance
mysqlslap --auto-generate-sql --verbose

# System load
uptime
top -bn1 | head -20
```

---

**Testing Status:** ⚠️ Ready for testing - not yet validated on production systems

**Last Updated:** [Current Date]
**Version:** 3.0
