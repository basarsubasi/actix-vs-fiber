#!/bin/bash
# filename: setup_client_kernel.sh

set -e

echo "==================================="
echo "Setting up Client VM Kernel Params (oha)"
echo "Ubuntu 24.04"
echo "==================================="

# Backup existing configurations
echo "[1/5] Backing up existing configurations..."
sudo cp /etc/security/limits.conf /etc/security/limits.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Configure limits.conf
echo "[2/5] Configuring /etc/security/limits.conf..."
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF

# High-performance benchmarking client settings
* soft nofile 1048576
* hard nofile 1048576
EOF

# Configure sysctl.conf
echo "[3/5] Configuring /etc/sysctl.conf..."
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF

# High-performance benchmarking client settings
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
fs.file-max = 2097152
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF

# Apply sysctl settings immediately
echo "[4/5] Applying sysctl settings..."
sudo sysctl -p

# Verify settings
echo "[5/5] Verifying configuration..."
echo ""
echo "Sysctl settings:"
sudo sysctl net.ipv4.ip_local_port_range
sudo sysctl net.ipv4.tcp_tw_reuse
sudo sysctl net.ipv4.tcp_fin_timeout
sudo sysctl fs.file-max
sudo sysctl net.core.rmem_max
sudo sysctl net.core.wmem_max
echo ""
echo "File descriptor limits (will take effect after reboot/relogin):"
cat /etc/security/limits.conf | grep nofile | grep -v "^#"

echo ""
echo "==================================="
echo " Client VM setup complete!"
echo "==================================="
echo ""
echo "  IMPORTANT: You must REBOOT or LOGOUT/LOGIN for limits.conf to take effect"
echo ""
echo "After reboot, verify with:"
echo "  ulimit -n    # Should show 1048576"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi