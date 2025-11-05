#!/bin/bash
# filepath: apply_postgres_config.sh
# Apply PostgreSQL configuration profiles
# Includes: Default (stock), Minimal (pool only), Tuned (16GB/6vCPU)

set -e

# Detect PostgreSQL version and paths
PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | head -n1)

# If PostgreSQL not found, offer to install it
if [ -z "$PG_VERSION" ]; then
    echo "=========================================="
    echo "PostgreSQL Not Found"
    echo "=========================================="
    echo ""
    echo "PostgreSQL is not installed on this system."
    echo ""
    read -p "Would you like to install PostgreSQL now? (y/n): " install_choice
    
    if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
        echo ""
        echo "Installing PostgreSQL..."
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib
        
        # Wait for PostgreSQL to start
        echo "Waiting for PostgreSQL to start..."
        sleep 5
        
        # Detect version again
        PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | head -n1)
        
        if [ -z "$PG_VERSION" ]; then
            echo "❌ Installation failed. Please install manually:"
            echo "   sudo apt update && sudo apt install -y postgresql postgresql-contrib"
            exit 1
        fi
        
        echo "✅ PostgreSQL ${PG_VERSION} installed successfully!"
        echo ""
    else
        echo "❌ PostgreSQL installation cancelled."
        echo ""
        echo "To install manually, run:"
        echo "   sudo apt update && sudo apt install -y postgresql postgresql-contrib"
        exit 1
    fi
fi

POSTGRES_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
BACKUP_DIR="/var/backups/postgresql"

echo "=========================================="
echo "PostgreSQL Configuration Manager"
echo "=========================================="
echo "Detected PostgreSQL version: $PG_VERSION"
echo "Config file: $POSTGRES_CONF"
echo ""
echo "Which configuration do you want to apply?"
echo ""
echo "0) Default  - Stock PostgreSQL (restore original)"
echo "1) Minimal  - Pool increase only (max_connections=300)"
echo "2) Tuned    - Full optimization (16GB RAM / 6 vCPU)"
echo ""
read -p "Enter choice (0, 1, or 2): " choice

# Create backup directory if it doesn't exist
sudo mkdir -p $BACKUP_DIR

# Always backup current config
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo ""
echo "Creating backup: ${BACKUP_DIR}/postgresql.conf.${TIMESTAMP}"
sudo cp $POSTGRES_CONF ${BACKUP_DIR}/postgresql.conf.${TIMESTAMP}

if [ "$choice" = "0" ]; then
    echo ""
    echo "=========================================="
    echo "Restoring DEFAULT PostgreSQL configuration"
    echo "=========================================="
    
    # Find the original backup (first backup or package default)
    ORIGINAL_BACKUP=$(ls -t ${BACKUP_DIR}/postgresql.conf.* 2>/dev/null | tail -n1)
    
    if [ -n "$ORIGINAL_BACKUP" ] && [ -f "$ORIGINAL_BACKUP" ]; then
        echo "Found original backup: $ORIGINAL_BACKUP"
        read -p "Restore from this backup? (y/n): " restore
        if [ "$restore" = "y" ]; then
            sudo cp $ORIGINAL_BACKUP $POSTGRES_CONF
            echo "✅ Restored from backup"
        fi
    else
        echo "No backup found. Reinstalling PostgreSQL with defaults..."
        read -p "Reinstall PostgreSQL? This will DELETE all data! (yes/no): " reinstall
        if [ "$reinstall" = "yes" ]; then
            # Run cleanup script
            if [ -f "./cleanup_postgres.sh" ]; then
                ./cleanup_postgres.sh
            else
                echo "⚠️  cleanup_postgres.sh not found. Manual cleanup required."
                exit 1
            fi
            
            # Reinstall
            sudo apt update
            sudo apt install -y postgresql postgresql-contrib
            echo "✅ Fresh PostgreSQL installed with defaults"
        else
            echo "❌ Cancelled"
            exit 0
        fi
    fi

elif [ "$choice" = "1" ]; then
    echo ""
    echo "=========================================="
    echo "Applying MINIMAL configuration"
    echo "=========================================="
    
    # Remove any existing benchmark settings
    sudo sed -i '/# BENCHMARK SETTINGS/,/^$/d' $POSTGRES_CONF
    
    # Append minimal configuration
    sudo tee -a $POSTGRES_CONF > /dev/null <<'EOF'

#------------------------------------------------------------------------------
# BENCHMARK SETTINGS - MINIMAL (Pool Increase Only)
#------------------------------------------------------------------------------
max_connections = 300

EOF
    echo "✅ Minimal config applied (max_connections = 300)"

elif [ "$choice" = "2" ]; then
    echo ""
    echo "=========================================="
    echo "Applying TUNED configuration"
    echo "=========================================="
    
    # Check if tuned config file exists
    if [ ! -f "./postgresql_tuned.conf" ]; then
        echo "❌ postgresql_tuned.conf not found in current directory"
        exit 1
    fi
    
    # Remove any existing benchmark settings
    sudo sed -i '/# BENCHMARK SETTINGS/,/^$/d' $POSTGRES_CONF
    
    # Append tuned configuration
    cat postgresql_tuned.conf | sudo tee -a $POSTGRES_CONF > /dev/null
    
    echo "✅ Tuned config applied (16GB RAM / 6 vCPU)"

else
    echo "❌ Invalid choice"
    exit 1
fi

# Restart PostgreSQL
echo ""
echo "Restarting PostgreSQL..."
sudo systemctl restart postgresql

# Verify it started successfully
sleep 3
if sudo systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL restarted successfully"
    
    # Show applied settings
    echo ""
    echo "=========================================="
    echo "Verifying Configuration"
    echo "=========================================="
    sudo -u postgres psql -c "SHOW max_connections;"
    sudo -u postgres psql -c "SHOW shared_buffers;"
    sudo -u postgres psql -c "SHOW effective_cache_size;"
    sudo -u postgres psql -c "SHOW work_mem;"
    sudo -u postgres psql -c "SHOW max_parallel_workers;"
    echo ""
    echo "✅ Configuration applied successfully!"
else
    echo "❌ PostgreSQL failed to start!"
    echo ""
    echo "Check logs with:"
    echo "  sudo journalctl -u postgresql -n 50 --no-pager"
    echo ""
    echo "Restore from backup:"
    echo "  sudo cp ${BACKUP_DIR}/postgresql.conf.${TIMESTAMP} $POSTGRES_CONF"
    echo "  sudo systemctl restart postgresql"
    exit 1
fi

echo ""
echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo "Active config: $([ "$choice" = "0" ] && echo "DEFAULT" || [ "$choice" = "1" ] && echo "MINIMAL" || echo "TUNED")"
echo "Backup saved: ${BACKUP_DIR}/postgresql.conf.${TIMESTAMP}"
echo "=========================================="