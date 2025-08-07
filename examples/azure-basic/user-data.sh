#!/bin/bash

# Azure HPC Instance Setup Script
# This script configures HPC-optimized instances for machine learning workloads

set -e

# Variables
NETAPP_MOUNT_POINT="${netapp_mount_point}"
NETAPP_PATH="${netapp_path}"
MOUNT_DIR="/mnt/netapp"

# Update system
yum update -y

# Install essential packages
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
    environment-modules

# Install NVIDIA drivers and CUDA (if GPU instance)
if lspci | grep -i nvidia; then
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
    yum install -y cuda-drivers cuda-toolkit
fi

# Configure InfiniBand
if [ -d "/sys/class/infiniband" ]; then
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
    echo "Mounting Azure NetApp Files..."
    mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=4.1 $NETAPP_MOUNT_POINT:/$NETAPP_PATH $MOUNT_DIR
    
    # Add to fstab for persistence
    echo "$NETAPP_MOUNT_POINT:/$NETAPP_PATH $MOUNT_DIR nfs rw,hard,rsize=65536,wsize=65536,vers=4.1 0 0" >> /etc/fstab
fi

# Configure system for HPC workloads
cat > /etc/sysctl.conf << EOF
# Network tuning
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_mtu_probing = 1

# Memory tuning
vm.swappiness = 1
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.nr_hugepages = 1024

# File system tuning
fs.file-max = 1000000
fs.aio-max-nr = 1048576
EOF

# Apply sysctl settings
sysctl -p

# Configure limits
cat > /etc/security/limits.conf << EOF
# HPC user limits
* soft nofile 1000000
* hard nofile 1000000
* soft nproc 32768
* hard nproc 32768
* soft memlock unlimited
* hard memlock unlimited
EOF

# Create HPC user
useradd -m -s /bin/bash hpcuser
echo "hpcuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up environment for HPC user
cat > /home/hpcuser/.bashrc << 'EOF'
# HPC Environment Configuration
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# MPI Configuration
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Performance tuning
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

# InfiniBand Configuration
export IBV_DEVICE_NAME=mlx5_0
export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include=mlx5_0:1

# Storage mount point
export HPC_STORAGE="/mnt/netapp"
export HPC_DATA="$HPC_STORAGE/data"
export HPC_MODELS="$HPC_STORAGE/models"
export HPC_LOGS="$HPC_STORAGE/logs"

# Create directories
mkdir -p $HPC_DATA $HPC_MODELS $HPC_LOGS
EOF

# Set proper permissions
chown -R hpcuser:hpcuser /home/hpcuser

# Install and configure monitoring
yum install -y python3 python3-pip

# Install Azure monitoring agent
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Create monitoring script
cat > /usr/local/bin/hpc-monitor.sh << 'EOF'
#!/bin/bash
# HPC Monitoring Script

LOG_FILE="/var/log/hpc-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] HPC Monitor Check" >> $LOG_FILE

# Check InfiniBand status
if [ -d "/sys/class/infiniband" ]; then
    ibstat >> $LOG_FILE 2>&1
fi

# Check storage mount
df -h /mnt/netapp >> $LOG_FILE 2>&1

# Check system resources
free -h >> $LOG_FILE 2>&1
uptime >> $LOG_FILE 2>&1

# Check GPU status (if available)
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi >> $LOG_FILE 2>&1
fi
EOF

chmod +x /usr/local/bin/hpc-monitor.sh

# Set up cron job for monitoring
echo "*/5 * * * * /usr/local/bin/hpc-monitor.sh" | crontab -

# Create performance test script
cat > /usr/local/bin/hpc-benchmark.sh << 'EOF'
#!/bin/bash
# HPC Performance Benchmark Script

echo "Running HPC Performance Benchmarks..."

# Network performance test
if [ -d "/sys/class/infiniband" ]; then
    echo "Testing InfiniBand performance..."
    ib_write_bw -d mlx5_0 -s 65536 -n 1000 &
    sleep 2
    ib_read_bw -d mlx5_0 -s 65536 -n 1000
fi

# Storage performance test
echo "Testing storage performance..."
dd if=/dev/zero of=/mnt/netapp/testfile bs=1G count=10 oflag=direct
dd if=/mnt/netapp/testfile of=/dev/null bs=1G count=10 iflag=direct
rm -f /mnt/netapp/testfile

# CPU performance test
echo "Testing CPU performance..."
sysbench --test=cpu --cpu-max-prime=20000 --num-threads=32 run

echo "Benchmark completed."
EOF

chmod +x /usr/local/bin/hpc-benchmark.sh

# Final system configuration
systemctl enable firewalld
systemctl start firewalld

# Configure firewall for HPC
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=2049/tcp
firewall-cmd --reload

echo "Azure HPC instance setup completed successfully."
echo "Storage mounted at: $MOUNT_DIR"
echo "HPC user created: hpcuser"
echo "Monitoring enabled with cron job"
echo "Performance benchmark available at: /usr/local/bin/hpc-benchmark.sh" 