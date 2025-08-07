#!/bin/bash

# Advanced Azure HPC Instance Setup Script
# Enhanced configuration with monitoring, security, and performance optimizations

set -e

# Variables
NETAPP_MOUNT_POINT="${netapp_mount_point}"
NETAPP_PATH="${netapp_path}"
KEY_VAULT_NAME="${key_vault_name}"
APP_INSIGHTS_KEY="${app_insights_key}"
LOG_ANALYTICS_ID="${log_analytics_id}"
MOUNT_DIR="/mnt/netapp"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/hpc-setup.log
}

log "Starting advanced HPC instance setup..."

# Update system
log "Updating system packages..."
yum update -y

# Install essential packages
log "Installing essential packages..."
yum install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    git \
    wget \
    curl \
    htop \
    iotop \
    nfs-utils \
    infiniband-diags \
    perftest \
    mpi \
    openmpi \
    openmpi-devel \
    environment-modules \
    python3 \
    python3-pip \
    sysbench \
    stress-ng \
    numactl \
    tuned \
    tuned-utils

# Install Azure CLI and monitoring agent
log "Installing Azure monitoring tools..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
yum install -y azure-cli

# Install Azure Monitor Agent
curl -sL https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh | bash -s -- -w $LOG_ANALYTICS_ID -s $APP_INSIGHTS_KEY

# Install NVIDIA drivers and CUDA (if GPU instance)
if lspci | grep -i nvidia; then
    log "Installing NVIDIA drivers and CUDA..."
    # Add NVIDIA repository
    cat > /etc/yum.repos.d/nvidia.repo << EOF
[nvidia]
name=NVIDIA Repository
baseurl=https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64
enabled=1
gpgcheck=1
gpgkey=https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/D42D0685.pub
EOF

    # Install NVIDIA drivers and CUDA
    yum install -y cuda-drivers cuda-toolkit cuda-samples
fi

# Configure InfiniBand
if [ -d "/sys/class/infiniband" ]; then
    log "Configuring InfiniBand..."
    # Load InfiniBand modules
    modprobe ib_uverbs
    modprobe mlx4_ib
    modprobe mlx5_ib
    
    # Configure InfiniBand
    echo "options mlx4_core log_num_qp=17 log_num_srq=17 log_num_cq=17 log_num_eq=17" >> /etc/modprobe.d/mlx4.conf
    echo "options mlx5_core log_max_qp=17 log_max_srq=17 log_max_cq=17 log_max_eq=17" >> /etc/modprobe.d/mlx5.conf
fi

# Create mount directory
mkdir -p $MOUNT_DIR

# Mount Azure NetApp Files
if [ ! -z "$NETAPP_MOUNT_POINT" ] && [ ! -z "$NETAPP_PATH" ]; then
    log "Mounting Azure NetApp Files..."
    mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=4.1 $NETAPP_MOUNT_POINT:/$NETAPP_PATH $MOUNT_DIR
    
    # Add to fstab for persistence
    echo "$NETAPP_MOUNT_POINT:/$NETAPP_PATH $MOUNT_DIR nfs rw,hard,rsize=65536,wsize=65536,vers=4.1 0 0" >> /etc/fstab
fi

# Advanced system tuning
log "Applying advanced system tuning..."

# Configure tuned profile for HPC
tuned-adm profile throughput-performance

# Advanced sysctl configuration
cat > /etc/sysctl.conf << EOF
# Network tuning for HPC
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.core.netdev_max_backlog = 10000
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535

# Memory tuning
vm.swappiness = 1
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.nr_hugepages = 2048
vm.hugetlb_shm_group = 1001
vm.max_map_count = 2147483647

# File system tuning
fs.file-max = 2000000
fs.aio-max-nr = 2097152
fs.inotify.max_user_watches = 524288

# Kernel tuning
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.shmmni = 4096
kernel.msgmax = 65536
kernel.msgmnb = 65536
kernel.msgmni = 32768
kernel.sem = 250 32000 100 128
EOF

# Apply sysctl settings
sysctl -p

# Configure limits
cat > /etc/security/limits.conf << EOF
# HPC user limits
* soft nofile 2000000
* hard nofile 2000000
* soft nproc 65536
* hard nproc 65536
* soft memlock unlimited
* hard memlock unlimited
* soft stack 32768
* hard stack 32768
EOF

# Create HPC user
useradd -m -s /bin/bash hpcuser
echo "hpcuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up environment for HPC user
cat > /home/hpcuser/.bashrc << 'EOF'
# Advanced HPC Environment Configuration
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# MPI Configuration
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include=mlx5_0:1
export OMPI_MCA_btl_openib_warn_default_gid_prefix=0

# Performance tuning
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

# InfiniBand Configuration
export IBV_DEVICE_NAME=mlx5_0
export HCOLL_ENABLE_MCAST_ALL=0
export HCOLL_ENABLE_SHARP=0

# Storage mount point
export HPC_STORAGE="/mnt/netapp"
export HPC_DATA="$HPC_STORAGE/data"
export HPC_MODELS="$HPC_STORAGE/models"
export HPC_LOGS="$HPC_STORAGE/logs"
export HPC_CACHE="$HPC_STORAGE/cache"

# Create directories
mkdir -p $HPC_DATA $HPC_MODELS $HPC_LOGS $HPC_CACHE

# Performance monitoring
export HPC_MONITOR_LOG="$HPC_LOGS/performance.log"
export HPC_BENCHMARK_LOG="$HPC_LOGS/benchmark.log"
EOF

# Set proper permissions
chown -R hpcuser:hpcuser /home/hpcuser

# Install Python packages for monitoring
pip3 install azure-mgmt-monitor azure-identity azure-keyvault-secrets psutil numpy pandas

# Create advanced monitoring script
cat > /usr/local/bin/hpc-monitor-advanced.sh << 'EOF'
#!/bin/bash
# Advanced HPC Monitoring Script

LOG_FILE="/var/log/hpc-monitor-advanced.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Advanced HPC Monitor Check" >> $LOG_FILE

# System information
echo "=== System Information ===" >> $LOG_FILE
uname -a >> $LOG_FILE 2>&1
cat /proc/cpuinfo | grep "model name" | head -1 >> $LOG_FILE 2>&1
free -h >> $LOG_FILE 2>&1
df -h >> $LOG_FILE 2>&1
uptime >> $LOG_FILE 2>&1

# Network information
echo "=== Network Information ===" >> $LOG_FILE
ip addr show >> $LOG_FILE 2>&1
ss -tuln >> $LOG_FILE 2>&1

# Check InfiniBand status
if [ -d "/sys/class/infiniband" ]; then
    echo "=== InfiniBand Status ===" >> $LOG_FILE
    ibstat >> $LOG_FILE 2>&1
    ibv_devinfo >> $LOG_FILE 2>&1
fi

# Check storage mount
echo "=== Storage Status ===" >> $LOG_FILE
df -h /mnt/netapp >> $LOG_FILE 2>&1
mount | grep netapp >> $LOG_FILE 2>&1

# Check GPU status (if available)
if command -v nvidia-smi &> /dev/null; then
    echo "=== GPU Status ===" >> $LOG_FILE
    nvidia-smi >> $LOG_FILE 2>&1
    nvidia-smi topo -m >> $LOG_FILE 2>&1
fi

# Performance metrics
echo "=== Performance Metrics ===" >> $LOG_FILE
iostat -x 1 1 >> $LOG_FILE 2>&1
vmstat 1 1 >> $LOG_FILE 2>&1

# Process information
echo "=== Top Processes ===" >> $LOG_FILE
ps aux --sort=-%cpu | head -10 >> $LOG_FILE 2>&1
ps aux --sort=-%mem | head -10 >> $LOG_FILE 2>&1

# Memory usage
echo "=== Memory Usage ===" >> $LOG_FILE
cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached)" >> $LOG_FILE 2>&1
EOF

chmod +x /usr/local/bin/hpc-monitor-advanced.sh

# Set up cron job for advanced monitoring
echo "*/2 * * * * /usr/local/bin/hpc-monitor-advanced.sh" | crontab -

# Create advanced performance test script
cat > /usr/local/bin/hpc-benchmark-advanced.sh << 'EOF'
#!/bin/bash
# Advanced HPC Performance Benchmark Script

LOG_FILE="/var/log/hpc-benchmark-advanced.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting Advanced HPC Performance Benchmarks..." | tee -a $LOG_FILE

# Network performance test
if [ -d "/sys/class/infiniband" ]; then
    echo "Testing InfiniBand performance..." | tee -a $LOG_FILE
    ib_write_bw -d mlx5_0 -s 65536 -n 1000 -t 4 >> $LOG_FILE 2>&1 &
    sleep 2
    ib_read_bw -d mlx5_0 -s 65536 -n 1000 -t 4 >> $LOG_FILE 2>&1
    ib_send_bw -d mlx5_0 -s 65536 -n 1000 -t 4 >> $LOG_FILE 2>&1
fi

# Storage performance test
echo "Testing storage performance..." | tee -a $LOG_FILE
dd if=/dev/zero of=/mnt/netapp/testfile bs=1G count=10 oflag=direct 2>> $LOG_FILE
dd if=/mnt/netapp/testfile of=/dev/null bs=1G count=10 iflag=direct 2>> $LOG_FILE
rm -f /mnt/netapp/testfile

# CPU performance test
echo "Testing CPU performance..." | tee -a $LOG_FILE
sysbench --test=cpu --cpu-max-prime=20000 --num-threads=32 run >> $LOG_FILE 2>&1

# Memory performance test
echo "Testing memory performance..." | tee -a $LOG_FILE
sysbench --test=memory --memory-block-size=1K --memory-total-size=10G --num-threads=32 run >> $LOG_FILE 2>&1

# MPI performance test
echo "Testing MPI performance..." | tee -a $LOG_FILE
mpirun -np 4 --mca btl_base_warn_component_unused 0 --mca btl ^openib --mca btl_tcp_if_include eth0 hostname >> $LOG_FILE 2>&1

# Stress test
echo "Running stress test..." | tee -a $LOG_FILE
stress-ng --cpu 4 --io 2 --vm 2 --vm-bytes 1G --timeout 60s >> $LOG_FILE 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Advanced benchmark completed." | tee -a $LOG_FILE
EOF

chmod +x /usr/local/bin/hpc-benchmark-advanced.sh

# Create Azure monitoring integration script
cat > /usr/local/bin/azure-monitor.sh << 'EOF'
#!/bin/bash
# Azure Monitoring Integration Script

# Send custom metrics to Azure Monitor
python3 << 'PYTHON_SCRIPT'
import psutil
import time
from azure.monitor import MonitorClient
from azure.identity import DefaultAzureCredential

try:
    # Get system metrics
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/mnt/netapp')
    
    # Log metrics
    with open('/var/log/azure-metrics.log', 'a') as f:
        f.write(f"{time.time()},{cpu_percent},{memory.percent},{disk.percent}\n")
        
except Exception as e:
    with open('/var/log/azure-metrics-error.log', 'a') as f:
        f.write(f"{time.time()}: {str(e)}\n")
PYTHON_SCRIPT
EOF

chmod +x /usr/local/bin/azure-monitor.sh

# Set up cron job for Azure monitoring
echo "*/5 * * * * /usr/local/bin/azure-monitor.sh" | crontab -

# Configure firewall
systemctl enable firewalld
systemctl start firewalld

# Configure firewall for HPC
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=2049/tcp
firewall-cmd --permanent --add-port=1024-65535/tcp
firewall-cmd --reload

# Create systemd service for HPC monitoring
cat > /etc/systemd/system/hpc-monitor.service << 'EOF'
[Unit]
Description=HPC Monitoring Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hpc-monitor-advanced.sh
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Enable and start monitoring service
systemctl enable hpc-monitor.service
systemctl start hpc-monitor.service

# Final configuration
log "Finalizing configuration..."

# Set up log rotation
cat > /etc/logrotate.d/hpc-logs << 'EOF'
/var/log/hpc-*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

# Create performance tuning script
cat > /usr/local/bin/hpc-tune.sh << 'EOF'
#!/bin/bash
# HPC Performance Tuning Script

echo "Applying HPC performance optimizations..."

# Set CPU governor to performance
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable transparent hugepages
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# Optimize NUMA settings
echo 0 > /proc/sys/vm/zone_reclaim_mode

# Set I/O scheduler to deadline for NVMe
for device in /sys/block/nvme*; do
    if [ -d "$device" ]; then
        echo deadline > "$device/queue/scheduler"
    fi
done

echo "Performance tuning completed."
EOF

chmod +x /usr/local/bin/hpc-tune.sh

# Run performance tuning
/usr/local/bin/hpc-tune.sh

log "Advanced Azure HPC instance setup completed successfully."
log "Storage mounted at: $MOUNT_DIR"
log "HPC user created: hpcuser"
log "Advanced monitoring enabled with systemd service"
log "Performance benchmark available at: /usr/local/bin/hpc-benchmark-advanced.sh"
log "Azure monitoring integration enabled"
log "Performance tuning applied" 