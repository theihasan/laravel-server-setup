#!/bin/bash

#############################################################################
# DATABASE MODULE
# Supports: MySQL, PostgreSQL (Local or Remote)
#############################################################################

configure_and_install_database() {
    print_section "🗄️ Database Configuration"
    
    echo -e "${BOLD}Database Setup Options:${NC}"
    echo ""
    
    print_box_start
    print_box_item "  ${GREEN}1)${NC} ${BOLD}Install MySQL Locally${NC}"
    print_box_item "     → Full MySQL server on this machine"
    print_box_item ""
    print_box_item "  ${GREEN}2)${NC} ${BOLD}Install PostgreSQL Locally${NC}"
    print_box_item "     → Full PostgreSQL server on this machine"
    print_box_item ""
    print_box_item "  ${GREEN}3)${NC} ${BOLD}Use Remote Database${NC}"
    print_box_item "     → Connect to existing external database"
    print_box_item ""
    print_box_item "  ${GREEN}4)${NC} ${BOLD}Skip Database Setup${NC}"
    print_box_item "     → Configure manually later"
    print_box_end
    echo ""
    
    get_input "Select option [1-4]" "1" db_choice
    
    case $db_choice in
        1)
            DATABASE_TYPE="mysql"
            DATABASE_MODE="local"
            install_mysql_local
            configure_mysql_database
            ;;
        2)
            DATABASE_TYPE="postgresql"
            DATABASE_MODE="local"
            install_postgresql_local
            configure_postgresql_database
            ;;
        3)
            configure_remote_database
            ;;
        4)
            log_info "Skipping database setup"
            DATABASE_TYPE="none"
            DATABASE_MODE="skip"
            return 0
            ;;
        *)
            log_warning "Invalid selection, defaulting to MySQL"
            DATABASE_TYPE="mysql"
            DATABASE_MODE="local"
            install_mysql_local
            configure_mysql_database
            ;;
    esac
}

#############################################################################
# MYSQL LOCAL INSTALLATION
#############################################################################

install_mysql_local() {
    log_step "Installing MySQL Server..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y mysql-server mysql-client || error_exit "Failed to install MySQL"
            ;;
        centos|rhel|fedora)
            yum install -y mysql-server mysql || error_exit "Failed to install MySQL"
            ;;
    esac
    
    systemctl enable mysql 2>/dev/null || systemctl enable mysqld
    systemctl start mysql 2>/dev/null || systemctl start mysqld
    
    log_success "MySQL Server installed and started"
}

configure_mysql_database() {
    log_step "Configuring MySQL database..."
    
    # Get database credentials
    echo ""
    get_input "Database name" "laravel_db" DB_NAME
    get_input "Database username" "laravel_user" DB_USER
    get_password "Database password (leave empty for auto-generate)" DB_PASS
    
    # Generate password if empty
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(openssl rand -base64 16)
        log_info "Generated password: $DB_PASS"
        echo "$DB_PASS" > /root/.mysql_laravel_password
        chmod 600 /root/.mysql_laravel_password
        log_success "Password saved to /root/.mysql_laravel_password"
    fi
    
    DB_HOST="127.0.0.1"
    DB_PORT="3306"
    
    # Create database and user
    log_step "Creating MySQL database and user..."
    
    mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" || error_exit "Failed to create database"
    mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" || error_exit "Failed to create user"
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';" || error_exit "Failed to grant privileges"
    mysql -e "FLUSH PRIVILEGES;" || error_exit "Failed to flush privileges"
    
    log_success "MySQL database configured successfully"
    log_info "Database: $DB_NAME"
    log_info "Username: $DB_USER"
    log_info "Host: $DB_HOST"
    log_info "Port: $DB_PORT"
}

#############################################################################
# POSTGRESQL LOCAL INSTALLATION
#############################################################################

install_postgresql_local() {
    log_step "Installing PostgreSQL Server..."
    
    case $OS in
        ubuntu|debian)
            apt-get install -y postgresql postgresql-contrib || error_exit "Failed to install PostgreSQL"
            ;;
        centos|rhel|fedora)
            yum install -y postgresql-server postgresql-contrib || error_exit "Failed to install PostgreSQL"
            postgresql-setup --initdb || true
            ;;
    esac
    
    systemctl enable postgresql
    systemctl start postgresql
    
    log_success "PostgreSQL Server installed and started"
}

configure_postgresql_database() {
    log_step "Configuring PostgreSQL database..."
    
    # Get database credentials
    echo ""
    get_input "Database name" "laravel_db" DB_NAME
    get_input "Database username" "laravel_user" DB_USER
    get_password "Database password (leave empty for auto-generate)" DB_PASS
    
    # Generate password if empty
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(openssl rand -base64 16)
        log_info "Generated password: $DB_PASS"
        echo "$DB_PASS" > /root/.pgsql_laravel_password
        chmod 600 /root/.pgsql_laravel_password
        log_success "Password saved to /root/.pgsql_laravel_password"
    fi
    
    DB_HOST="127.0.0.1"
    DB_PORT="5432"
    
    # Create database and user
    log_step "Creating PostgreSQL database and user..."
    
    sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME};" 2>/dev/null || log_warning "Database may already exist"
    sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';" 2>/dev/null || log_warning "User may already exist"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || error_exit "Failed to grant privileges"
    
    # Configure PostgreSQL to allow password authentication
    local pg_version=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+' | head -1)
    local pg_hba_conf="/etc/postgresql/${pg_version}/main/pg_hba.conf"
    
    if [ -f "$pg_hba_conf" ]; then
        # Backup original
        cp "$pg_hba_conf" "${pg_hba_conf}.backup"
        
        # Add md5 authentication for local connections
        if ! grep -q "host.*${DB_NAME}.*${DB_USER}.*md5" "$pg_hba_conf"; then
            echo "host    ${DB_NAME}    ${DB_USER}    127.0.0.1/32    md5" >> "$pg_hba_conf"
            systemctl reload postgresql
        fi
    fi
    
    log_success "PostgreSQL database configured successfully"
    log_info "Database: $DB_NAME"
    log_info "Username: $DB_USER"
    log_info "Host: $DB_HOST"
    log_info "Port: $DB_PORT"
}

#############################################################################
# REMOTE DATABASE CONFIGURATION
#############################################################################

configure_remote_database() {
    log_step "Configuring remote database connection..."
    
    DATABASE_MODE="remote"
    USE_REMOTE_DB="true"
    
    echo ""
    echo -e "${BOLD}Remote Database Information:${NC}"
    echo ""
    
    # Ask for database type
    echo "Database Type:"
    echo "  1) MySQL/MariaDB"
    echo "  2) PostgreSQL"
    echo ""
    get_input "Select type [1-2]" "1" remote_db_type
    
    case $remote_db_type in
        1)
            DATABASE_TYPE="mysql"
            DB_PORT="3306"
            ;;
        2)
            DATABASE_TYPE="postgresql"
            DB_PORT="5432"
            ;;
        *)
            DATABASE_TYPE="mysql"
            DB_PORT="3306"
            ;;
    esac
    
    # Get connection details
    get_input "Database host (e.g., db.example.com)" "" DB_HOST
    get_input "Database port" "$DB_PORT" DB_PORT
    get_input "Database name" "" DB_NAME
    get_input "Database username" "" DB_USER
    get_password "Database password" DB_PASS
    
    # Test connection
    if confirm "Test database connection now?" "y"; then
        test_database_connection
    fi
    
    log_success "Remote database configuration saved"
    log_info "Database: $DB_NAME @ $DB_HOST:$DB_PORT"
}

#############################################################################
# DATABASE CONNECTION TEST
#############################################################################

test_database_connection() {
    log_step "Testing database connection..."
    
    local test_result=1
    
    case $DATABASE_TYPE in
        "mysql")
            if command -v mysql >/dev/null 2>&1; then
                mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1
                test_result=$?
            else
                # Install mysql client for testing
                log_info "Installing MySQL client for testing..."
                case $OS in
                    ubuntu|debian)
                        apt-get install -y mysql-client >/dev/null 2>&1
                        ;;
                    centos|rhel|fedora)
                        yum install -y mysql >/dev/null 2>&1
                        ;;
                esac
                mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1
                test_result=$?
            fi
            ;;
        "postgresql")
            if command -v psql >/dev/null 2>&1; then
                PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1
                test_result=$?
            else
                # Install postgresql client for testing
                log_info "Installing PostgreSQL client for testing..."
                case $OS in
                    ubuntu|debian)
                        apt-get install -y postgresql-client >/dev/null 2>&1
                        ;;
                    centos|rhel|fedora)
                        yum install -y postgresql >/dev/null 2>&1
                        ;;
                esac
                PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1
                test_result=$?
            fi
            ;;
    esac
    
    if [ $test_result -eq 0 ]; then
        log_success "Database connection successful!"
    else
        log_error "Database connection failed!"
        log_warning "Please verify your credentials and network connectivity"
        
        if ! confirm "Continue anyway?"; then
            error_exit "Database connection test failed"
        fi
    fi
}

#############################################################################
# UPDATE LARAVEL .ENV FILE
#############################################################################

update_laravel_env_database() {
    local env_file=$1
    
    if [ ! -f "$env_file" ]; then
        log_warning ".env file not found: $env_file"
        return 0
    fi
    
    log_step "Updating Laravel .env with database credentials..."
    
    # Determine DB_CONNECTION value
    local db_connection=""
    case $DATABASE_TYPE in
        "mysql") db_connection="mysql" ;;
        "postgresql") db_connection="pgsql" ;;
        *) db_connection="mysql" ;;
    esac
    
    # Update or add database configuration
    sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=${db_connection}/" "$env_file" || echo "DB_CONNECTION=${db_connection}" >> "$env_file"
    sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" "$env_file" || echo "DB_HOST=${DB_HOST}" >> "$env_file"
    sed -i "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" "$env_file" || echo "DB_PORT=${DB_PORT}" >> "$env_file"
    sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" "$env_file" || echo "DB_DATABASE=${DB_NAME}" >> "$env_file"
    sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" "$env_file" || echo "DB_USERNAME=${DB_USER}" >> "$env_file"
    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" "$env_file" || echo "DB_PASSWORD=${DB_PASS}" >> "$env_file"
    
    log_success "Database configuration updated in .env"
}

# Redis installation moved to dedicated redis.sh module
