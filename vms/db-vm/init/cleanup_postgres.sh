#!/bin/bash
# filepath: cleanup_postgres.sh
# helper file, run setup_postgres.sh for (re)installations
# Complete PostgreSQL cleanup and uninstall script
# ⚠️ WARNING: This will DELETE all PostgreSQL data and configurations

set -e

echo "=========================================="
echo "PostgreSQL Complete Cleanup & Uninstall"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will:"
echo "   - Stop PostgreSQL service"
echo "   - Uninstall all PostgreSQL packages"
echo "   - DELETE all databases and data"
echo "   - DELETE all configuration files"
echo "   - Remove PostgreSQL user and group"
echo ""
read -p "Are you ABSOLUTELY sure? Type 'DELETE' to confirm: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "[1/7] Stopping PostgreSQL service..."
sudo systemctl stop postgresql 2>/dev/null || echo "  Service not running"
sudo systemctl disable postgresql 2>/dev/null || echo "  Service not enabled"

echo "[2/7] Removing PostgreSQL packages..."
sudo apt-get --purge remove -y postgresql* 2>/dev/null || echo "  No packages found"

echo "[3/7] Removing data directories..."
sudo rm -rf /var/lib/postgresql/
sudo rm -rf /var/log/postgresql/
sudo rm -rf /etc/postgresql/

echo "[4/7] Removing postgres user and group..."
sudo deluser postgres 2>/dev/null || echo "  User already removed"
sudo delgroup postgres 2>/dev/null || echo "  Group already removed"

echo "[5/7] Cleaning apt cache..."
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "[6/7] Removing leftover configuration..."
sudo rm -rf /root/.postgresql
sudo rm -rf /home/*/.postgresql 2>/dev/null || true

echo "[7/7] Final cleanup..."
# Remove any systemd overrides
sudo rm -rf /etc/systemd/system/postgresql.service.d/ 2>/dev/null || true
sudo systemctl daemon-reload

echo ""
echo "=========================================="
echo "✅ PostgreSQL completely removed!"
echo "=========================================="
echo ""
echo "To reinstall fresh PostgreSQL, run:"
echo "  sudo apt update"
echo "  sudo apt install -y postgresql postgresql-contrib"
echo ""