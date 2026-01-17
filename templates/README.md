# Configuration Templates

This directory contains configuration file templates for various components of the Laravel Server Setup Script.

## 📁 Available Templates

### **Web Server Templates**

#### Nginx
- `nginx-laravel.conf.template` - Basic HTTP virtual host
- `nginx-laravel-ssl.conf.template` - HTTPS with Let's Encrypt SSL

**Variables:**
- `{{DOMAIN_NAME}}` - Server domain name
- `{{LARAVEL_PATH}}` - Full path to Laravel project
- `{{APP_NAME}}` - Application name for logs
- `{{PHP_VERSION}}` - PHP version (e.g., 8.3)

#### Apache
- `apache-laravel.conf.template` - Basic HTTP virtual host
- `apache-laravel-ssl.conf.template` - HTTPS with Let's Encrypt SSL

**Variables:**
- `{{DOMAIN_NAME}}` - Server domain name
- `{{LARAVEL_PATH}}` - Full path to Laravel project
- `{{APP_NAME}}` - Application name for logs
- `{{PHP_VERSION}}` - PHP version (e.g., 8.3)

#### Caddy
- `caddy-laravel.conf.template` - Caddyfile configuration (auto-HTTPS)

**Variables:**
- `{{DOMAIN_NAME}}` - Server domain name
- `{{LARAVEL_PATH}}` - Full path to Laravel project
- `{{APP_NAME}}` - Application name for logs
- `{{PHP_VERSION}}` - PHP version (e.g., 8.3)

---

### **Supervisor Templates**

#### Queue Workers
- `supervisor-queue.conf.template` - Laravel queue worker configuration
- `supervisor-horizon.conf.template` - Laravel Horizon configuration

**Variables:**
- `{{APP_NAME}}` - Application name
- `{{QUEUE_NAME}}` - Queue name (default, high, low, etc.)
- `{{LARAVEL_PATH}}` - Full path to Laravel project
- `{{QUEUE_DRIVER}}` - Queue driver (database, redis, sync)
- `{{WEB_USER}}` - Web server user (www-data)
- `{{NUM_PROCS}}` - Number of worker processes

---

## 🔧 Using Templates

### **Method 1: Using sed (Simple Variable Replacement)**

```bash
# Example: Generate Nginx configuration
sed -e "s|{{DOMAIN_NAME}}|example.com|g" \
    -e "s|{{LARAVEL_PATH}}|/var/www/html/myapp|g" \
    -e "s|{{APP_NAME}}|myapp|g" \
    -e "s|{{PHP_VERSION}}|8.3|g" \
    nginx-laravel.conf.template > /etc/nginx/sites-available/myapp.conf
```

### **Method 2: Using envsubst (Environment Variables)**

```bash
# Set environment variables
export DOMAIN_NAME="example.com"
export LARAVEL_PATH="/var/www/html/myapp"
export APP_NAME="myapp"
export PHP_VERSION="8.3"

# Generate configuration
envsubst < nginx-laravel.conf.template > /etc/nginx/sites-available/myapp.conf
```

### **Method 3: Using Bash Function (Recommended in Script)**

```bash
#!/bin/bash

generate_config() {
    local template_file="$1"
    local output_file="$2"
    
    cp "$template_file" "$output_file"
    
    sed -i "s|{{DOMAIN_NAME}}|$DOMAIN_NAME|g" "$output_file"
    sed -i "s|{{LARAVEL_PATH}}|$LARAVEL_PATH|g" "$output_file"
    sed -i "s|{{APP_NAME}}|$APP_NAME|g" "$output_file"
    sed -i "s|{{PHP_VERSION}}|$PHP_VERSION|g" "$output_file"
}

# Usage
generate_config "nginx-laravel.conf.template" "/etc/nginx/sites-available/myapp.conf"
```

---

## 📝 Template Guidelines

### **Creating New Templates**

1. **Use Clear Variable Names**
   - Use `{{VARIABLE_NAME}}` format for placeholders
   - Make variable names descriptive and uppercase
   - Document all variables in this README

2. **Follow Best Practices**
   - Security hardening enabled by default
   - Performance optimization included
   - Proper logging configuration
   - Error handling

3. **Include Comments**
   - Explain complex configurations
   - Document why specific settings are used
   - Provide examples for customization

4. **Test Thoroughly**
   - Test on multiple OS distributions
   - Verify all variables are replaced
   - Check syntax before using
   - Test with real Laravel applications

---

## 🔐 Security Considerations

All templates include:

- ✅ Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- ✅ Hidden file protection (.env, .git, etc.)
- ✅ Sensitive file protection (composer.json, package.json, etc.)
- ✅ Server signature hiding
- ✅ Modern TLS configuration (TLS 1.2+)
- ✅ Strong cipher suites
- ✅ OCSP stapling (SSL templates)
- ✅ HSTS header (SSL templates)

---

## 🎨 Customization Examples

### **Nginx: Increase Upload Limit**

Edit generated config and change:
```nginx
client_max_body_size 100M;  # Change to desired size
```

### **Apache: Enable Additional Modules**

Add to generated config:
```apache
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpg "access plus 1 year"
</IfModule>
```

### **Supervisor: Add Environment Variables**

Add to supervisor config:
```ini
environment=KEY1="value1",KEY2="value2"
```

---

## 📚 Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Apache Documentation](https://httpd.apache.org/docs/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Supervisor Documentation](http://supervisord.org/)
- [Laravel Deployment](https://laravel.com/docs/deployment)

---

## 🐛 Template Issues

If you find issues with templates:

1. Check variable replacement is complete
2. Verify file permissions (644 for configs)
3. Test configuration syntax:
   - Nginx: `nginx -t`
   - Apache: `apachectl configtest`
   - Caddy: `caddy validate`
4. Check service logs for errors

---

## 📈 Version History

- **v3.0** - Initial template collection
  - Nginx HTTP/HTTPS templates
  - Apache HTTP/HTTPS templates
  - Caddy template with auto-HTTPS
  - Supervisor queue worker templates
  - Laravel Horizon template

---

**Maintained by:** FIGLAB  
**Last Updated:** January 2026
