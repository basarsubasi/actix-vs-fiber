#!/bin/bash
# filepath: /home/basar/repositories/actix-vs-fiber/postgres/setup_benchmark_db.sh
# Complete database setup script

set -e

echo "=========================================="
echo "Benchmark Database Setup"
echo "=========================================="

# Check if PostgreSQL is running
if ! sudo systemctl is-active --quiet postgresql; then
    echo "❌ PostgreSQL is not running. Start it first:"
    echo "   sudo systemctl start postgresql"
    exit 1
fi

# Check if setup_database.sql exists
if [ ! -f "./setup_database.sql" ]; then
    echo "❌ setup_database.sql not found in current directory"
    exit 1
fi

echo ""
echo "[1/3] Creating database and tables..."
sudo -u postgres psql -f setup_database.sql

echo ""
echo "[2/3] Verifying database..."
sudo -u postgres psql -d benchmark_database -c "\dt"

echo ""
echo "[3/3] Testing connection..."
sudo -u postgres psql -d benchmark_database -c "SELECT COUNT(*) as light_records FROM light_data;"
sudo -u postgres psql -d benchmark_database -c "SELECT COUNT(*) as heavy_records FROM heavy_data;"

echo ""
echo "=========================================="
echo "✅ Database setup complete!"
echo "=========================================="
echo ""
echo "Database Details:"
echo "  Name: benchmark_database"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  User: postgres"
echo ""
echo "Tables created:"
echo "  - light_data (for simple operations)"
echo "  - heavy_data (for complex JSON operations)"
echo ""
echo "Connection string:"
echo "  postgresql://postgres:postgres@localhost:5432/benchmark_database"
echo ""