#!/bin/bash
# High-Performance Networking User Data Script
# Optimized for EFA, GPUDirect, and distributed training workloads

set -e

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/hpc-setup.log
}

log "Starting HPC networking setup..."

# Update system packages
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install essential packages
log "Installing essential packages..."
apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    htop \
    iotop \
    nvme-cli \
    numactl \
    libnuma-dev \
    iperf3 \
    netperf \
    ethtool \
    sysstat \
    python3 \
    python3-pip \
    awscli \
    jq

# Install NVIDIA drivers and CUDA (if GPU instance)
if [[ "${instance_type}" == *"p5"* ]] || [[ "${instance_type}" == *"p4"* ]] || [[ "${instance_type}" == *"g5"* ]]; then
    log "Installing NVIDIA drivers and CUDA..."
    
    # Add NVIDIA repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
    
    apt-get update -y
    apt-get install -y nvidia-docker2 nvidia-container-toolkit
    
    # Install CUDA toolkit
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
    dpkg -i cuda-keyring_1.0-1_all.deb
    apt-get update -y
    apt-get install -y cuda-toolkit-12-0
fi

# EFA Installation and Configuration
if [[ "${enable_efa}" == "true" ]]; then
    log "Installing and configuring EFA..."
    
    # Install EFA kernel module
    curl -O https://efa-installer.amazonaws.com/aws-efa-installer-1.24.1.tar.gz
    tar -xf aws-efa-installer-1.24.1.tar.gz
    cd aws-efa-installer
    
    # Install EFA with GPUDirect support
    if [[ "${enable_gdr}" == "true" ]]; then
        ./efa_installer.sh -y --skip-kmod --skip-limit-conf --enable-gdrcopy
    else
        ./efa_installer.sh -y --skip-kmod --skip-limit-conf
    fi
    
    cd ..
    rm -rf aws-efa-installer*
    
    # Verify EFA installation
    if command -v fi_info &> /dev/null; then
        log "EFA installation verified"
        fi_info -l
    else
        log "ERROR: EFA installation failed"
        exit 1
    fi
fi

# Network Performance Tuning
log "Applying network performance tuning..."

# TCP optimization
cat >> /etc/sysctl.conf << EOF
# TCP optimization for high-performance networking
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_slow_start_after_idle = 0

# Network buffer optimization
net.core.netdev_max_backlog = 500000
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000
net.core.somaxconn = 65535

# NUMA optimization
kernel.numa_balancing = 0

# File descriptor limits
fs.file-max = 2097152
EOF

# Apply sysctl settings
sysctl -p

# Configure jumbo frames if enabled
if [[ "${enable_jumbo_frames}" == "true" ]]; then
    log "Configuring jumbo frames (MTU ${mtu_size})..."
    
    # Find EFA interface
    EFA_INTERFACE=$(ip link show | grep -E "efa|mlx5" | head -1 | cut -d: -f2 | tr -d ' ')
    if [[ -n "$EFA_INTERFACE" ]]; then
        ip link set dev $EFA_INTERFACE mtu ${mtu_size}
        echo "MTU ${mtu_size} configured on $EFA_INTERFACE"
    fi
fi

# NUMA optimization
if [[ "${numa_optimization}" == "true" ]]; then
    log "Applying NUMA optimization..."
    
    # Set NUMA policy
    echo 0 > /proc/sys/kernel/numa_balancing
    
    # Configure CPU affinity for network interrupts
    for irq in $(cat /proc/interrupts | grep mlx5 | awk '{print $1}' | sed 's/://'); do
        echo 0 > /proc/irq/$irq/smp_affinity_list
    done
fi

# Set environment variables for EFA optimization
log "Setting EFA environment variables..."
cat >> /etc/environment << EOF

# EFA and NCCL optimization
FI_EFA_FORK_SAFE=1
FI_EFA_USE_DEVICE_RDMA=1
NCCL_NET_GDR_LEVEL=2
NCCL_ALGO=Ring
NCCL_DEBUG=INFO
NCCL_IB_DISABLE=1
NCCL_P2P_DISABLE=1
NCCL_SHM_DISABLE=1
NCCL_IB_HCA=mlx5_0
NCCL_IB_TIMEOUT=23
NCCL_IB_RETRY_CNT=7
NCCL_IB_SL=0
NCCL_IB_TC=41
NCCL_IB_AR_THRESHOLD=8192
NCCL_IB_CUDA_SUPPORT=1

# Performance tuning
OMP_NUM_THREADS=1
MKL_NUM_THREADS=1
OPENBLAS_NUM_THREADS=1
VECLIB_MAXIMUM_THREADS=1
NUMEXPR_NUM_THREADS=1
EOF

# Source environment variables
source /etc/environment

# Install and configure monitoring tools
log "Installing monitoring tools..."

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/hpc-setup.log",
                        "log_group_name": "/aws/hpc-networking/${project_name}",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "/aws/hpc-networking/${project_name}/syslog",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": ["tcp_established", "tcp_time_wait"],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": ["swap_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Create performance testing script
log "Creating performance testing script..."
cat > /usr/local/bin/hpc-benchmark.sh << 'EOF'
#!/bin/bash
# HPC Performance Benchmark Script

echo "=== HPC Performance Benchmark ==="
echo "Date: $(date)"
echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)"
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

# Network performance test
echo "=== Network Performance ==="
EFA_INTERFACE=$(ip link show | grep -E "efa|mlx5" | head -1 | cut -d: -f2 | tr -d ' ')
if [[ -n "$EFA_INTERFACE" ]]; then
    echo "EFA Interface: $EFA_INTERFACE"
    ethtool $EFA_INTERFACE | grep -E "Speed|Duplex|Link detected"
    ethtool -S $EFA_INTERFACE | grep -E "rx_packets|tx_packets|rx_bytes|tx_bytes"
fi

# Memory bandwidth test
echo "=== Memory Bandwidth ==="
if command -v numactl &> /dev/null; then
    numactl --hardware
fi

# CPU performance test
echo "=== CPU Performance ==="
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core"

# GPU information (if available)
echo "=== GPU Information ==="
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader,nounits
fi

# EFA information
echo "=== EFA Information ==="
if command -v fi_info &> /dev/null; then
    fi_info -l
fi

echo "=== Benchmark Complete ==="
EOF

chmod +x /usr/local/bin/hpc-benchmark.sh

# Create systemd service for periodic benchmarks
cat > /etc/systemd/system/hpc-benchmark.service << EOF
[Unit]
Description=HPC Performance Benchmark
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hpc-benchmark.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/hpc-benchmark.timer << EOF
[Unit]
Description=Run HPC benchmark every hour
Requires=hpc-benchmark.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl enable hpc-benchmark.timer
systemctl start hpc-benchmark.timer

# Custom user data script (if provided)
%{ if custom_user_data != "" ~}
log "Executing custom user data script..."
${custom_user_data}
%{ endif ~}

# Final system optimization
log "Performing final system optimization..."

# Set CPU governor to performance
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable transparent hugepages for better performance
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# Optimize I/O scheduler
echo deadline > /sys/block/nvme0n1/queue/scheduler

# Set readahead for better I/O performance
blockdev --setra 65536 /dev/nvme0n1

# Create performance monitoring dashboard
log "Setting up performance monitoring..."

# Install additional monitoring tools
apt-get install -y \
    hwloc \
    likwid \
    stress-ng \
    fio

# Create system information script
cat > /usr/local/bin/system-info.sh << 'EOF'
#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "CPU Cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"
echo "Network Interfaces:"
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1"
echo "EFA Interfaces:"
ip link show | grep -E "efa|mlx5"
EOF

chmod +x /usr/local/bin/system-info.sh

# Run initial benchmark
log "Running initial performance benchmark..."
/usr/local/bin/hpc-benchmark.sh

# Create completion marker
echo "$(date): HPC networking setup completed successfully" > /var/log/hpc-setup-complete.log

log "HPC networking setup completed successfully!"
log "System is ready for high-performance computing workloads."

# Display final system information
/usr/local/bin/system-info.sh

# Reboot if required (for kernel modules)
if [[ "${enable_efa}" == "true" ]]; then
    log "Rebooting to ensure all optimizations are applied..."
    reboot
fi 