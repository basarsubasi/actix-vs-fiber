#!/bin/bash
# filepath: /home/basar/repositories/actix-vs-fiber/scripts/optimize_database_kernel.sh

set -e

echo "=========================================="
echo "Optimizing Database VM Kernel Parameters"
echo "=========================================="

# Backup existing sysctl.conf
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d_%H%M%S)

# Append optimizations
sudo tee -a /etc/sysctl.conf > /dev/null <<'EOF'

#------------------------------------------------------------------------------
# HIGH-PERFORMANCE DATABASE SERVER KERNEL TUNING
#------------------------------------------------------------------------------

# Shared Memory (critical for PostgreSQL)
kernel.shmmax = 17179869184              # 16GB in bytes
kernel.shmall = 4194304                  # 16GB / page size (4096)
kernel.shmmni = 4096

# Semaphores (PostgreSQL uses these)
kernel.sem = 250 32000 100 128

# Network Core Settings
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144

# TCP Settings
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Port Range
net.ipv4.ip_local_port_range = 1024 65535

# File Descriptors
fs.file-max = 2097152

# Memory Management for Database
vm.swappiness = 1                        # Avoid swap (critical for DB)
vm.dirty_ratio = 10
vm.dirty_background_ratio = 3
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.overcommit_memory = 2                 # Don't overcommit (DB safety)
vm.overcommit_ratio = 95

# Huge Pages (PostgreSQL benefits from this)
vm.nr_hugepages = 1024                   # For 2GB shared_buffers (2048MB / 2MB pages)

EOF

# Apply settings
echo ""
echo "Applying kernel parameters..."
sudo sysctl -p

echo ""
echo "=========================================="
echo "✅ Database VM kernel optimized!"
echo "=========================================="
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi