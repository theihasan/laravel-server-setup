# Server Setup V2.0 - Enhanced UX Implementation

## Overview
Complete reorganization of Laravel server setup and Prometheus/Grafana monitoring scripts with improved user experience.

## Files Created

### 1. setup-v2.sh (Main Script)
**Location:** `/Users/figlab/Desktop/sites/laravel-server-setup/setup-v2.sh`

**Features Implemented:**
- ✓ Clean main menu with organized options
- ✓ Environment profile selection (Development/Staging/Production/Custom)
- ✓ Smart server resource detection
- ✓ Automated recommendations based on server specs
- ✓ System inspection tool
- ✓ Modular setup options (Laravel, Monitoring, or Both)
- ✓ Color-coded UI without emojis
- ✓ Progress tracking framework
- ✓ Comprehensive logging

### 2. setup-v2-functions.sh (Installation Functions)
**Location:** `/Users/figlab/Desktop/sites/laravel-server-setup/setup-v2-functions.sh`

**Contains:**
- ✓ Prometheus installation functions
- ✓ Node Exporter installation functions
- ✓ Grafana installation functions
- ✓ Web server (Nginx/Apache) installation
- ✓ PHP installation with extensions
- ✓ Database installation (MySQL/PostgreSQL)
- ✓ Redis installation
- ✓ Supervisor installation
- ✓ Composer installation
- ✓ Node.js installation
- ✓ Firewall configuration
- ✓ Health check system
- ✓ Post-installation dashboard

## UX Improvements

### 1. Main Menu Structure
```
APPLICATION STACK
├─ 1) Full Laravel Stack Setup
├─ 2) Laravel Components Only
└─ 3) Database Setup Only

MONITORING & OBSERVABILITY
├─ 4) Full Monitoring Stack
├─ 5) Metrics Collection Only
└─ 6) Visualization Only

COMPLETE SOLUTIONS
├─ 7) Laravel + Monitoring (Recommended)
└─ 8) Quick Production Setup

OTHER OPTIONS
├─ 0) Inspect Current System
└─ q) Exit
```

### 2. Environment Profiles
- **Development:** Debug enabled, minimal resources
- **Staging:** Production-like with extra logging
- **Production:** Optimized and secured
- **Custom:** Manual configuration

### 3. Smart Recommendations
Automatically detects:
- CPU cores
- RAM availability
- Disk space
- Server performance tier (Basic/Medium/High-Performance)

Recommends:
- Optimal PHP worker count
- Queue process count
- Cache/Session drivers
- Expected capacity

### 4. Server Classification
- **High-Performance:** 8GB+ RAM, 4+ CPU cores
  - Recommended for production workloads
  - Queue processes: CPU cores × 2
  
- **Medium-Performance:** 4GB+ RAM, 2+ CPU cores
  - Suitable for moderate production
  - Queue processes: CPU cores
  
- **Basic:** < 4GB RAM or < 2 CPU cores
  - Recommended for development only
  - Queue processes: 2

### 5. System Inspection
Real-time status check for:
- Web servers (Nginx/Apache)
- PHP versions
- Databases (MySQL/PostgreSQL)
- Redis
- Monitoring stack (Prometheus/Grafana/Node Exporter)

## Usage

### Basic Usage
```bash
sudo ./setup-v2.sh
```

### What Happens
1. **System Analysis** - Detects OS, CPU, RAM, Disk
2. **Main Menu** - Choose what to install
3. **Profile Selection** - Pick environment type
4. **Recommendations** - Review and accept/customize
5. **Installation** - Automated setup with progress tracking
6. **Post-Install** - Health check and configuration summary

## Setup Options Explained

### Option 1: Full Laravel Stack
Installs:
- Web server (Nginx or Apache)
- PHP 8.3 with all extensions
- Database (MySQL or PostgreSQL)
- Redis
- Supervisor
- Composer
- Laravel-specific configurations

### Option 4: Full Monitoring Stack
Installs:
- Prometheus (metrics collection)
- Node Exporter (system metrics)
- Grafana (visualization)
- Pre-configured dashboards

### Option 7: Complete Solution (Recommended)
Installs everything from options 1 and 4 for a production-ready server.

## Configuration Files

### Prometheus
- Config: `/etc/prometheus/prometheus.yml`
- Data: `/var/lib/prometheus`
- Service: `systemctl status prometheus`

### Grafana
- Config: `/etc/grafana/grafana.ini`
- Service: `systemctl status grafana-server`
- URL: `http://your-ip:3000`
- Default: admin/admin

### Node Exporter
- Service: `systemctl status node_exporter`
- Metrics: `http://your-ip:9100/metrics`

## Logs
- Installation log: `/var/log/server-setup-v2.log`
- View logs: `tail -f /var/log/server-setup-v2.log`

## Next Steps

To complete the implementation, the following can be added:
1. Full Laravel deployment workflow
2. SSL certificate installation
3. Backup and restore functionality
4. Auto-update mechanism
5. Remote monitoring configuration
6. Alert rules for Prometheus
7. Pre-built Grafana dashboards
8. Database migration tools
9. Git deployment hooks
10. Performance tuning scripts

## Design Principles

1. **Progressive Disclosure** - Information revealed as needed
2. **Smart Defaults** - Context-aware recommendations
3. **Clear Feedback** - Status messages at every step
4. **Error Recovery** - Graceful handling of failures
5. **Non-Destructive** - Checks before overwriting
6. **Accessible** - No emojis, terminal-safe characters
7. **Modular** - Install only what you need
8. **Documented** - Clear logs and summaries

## Original Scripts
- Laravel setup: `setup.sh`
- Monitoring setup: Included in Prometheus script provided
- Both original scripts preserved and unchanged

## Support
For issues or enhancements, check:
- Laravel: https://laravel.com/docs
- Prometheus: https://prometheus.io/docs
- Grafana: https://grafana.com/docs
