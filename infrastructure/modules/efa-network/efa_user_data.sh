#!/bin/bash
# EFA User Data Script for HPC Instances

set -euo pipefail

# Variables
CLUSTER_NAME="${cluster_name}"
EFA_DEVICE="${efa_device}"
MTU_SIZE="${mtu_size}"
ENABLE_GPUDIRECT="${enable_gpudirect}"

# Logging
exec > >(tee /var/log/efa-setup.log)
exec 2>&1

echo "Starting EFA setup for cluster: $CLUSTER_NAME"

# Update system packages
yum update -y

# Install EFA driver
yum install -y efa-driver

# Install libfabric
yum install -y libfabric

# Install EFA kernel modules
modprobe efa

# Configure EFA device
if [ -e "/dev/$EFA_DEVICE" ]; then
    echo "Configuring EFA device: $EFA_DEVICE"
    
    # Set MTU for EFA device
    ip link set dev $EFA_DEVICE mtu $MTU_SIZE
    
    # Bring up EFA device
    ip link set dev $EFA_DEVICE up
    
    # Configure EFA device with optimal settings
    echo "net.core.rmem_max = 134217728" >> /etc/sysctl.conf
    echo "net.core.wmem_max = 134217728" >> /etc/sysctl.conf
    echo "net.core.rmem_default = 134217728" >> /etc/sysctl.conf
    echo "net.core.wmem_default = 134217728" >> /etc/sysctl.conf
    echo "net.core.netdev_max_backlog = 5000" >> /etc/sysctl.conf
    echo "net.core.netdev_budget = 600" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_rmem = 4096 87380 134217728" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_wmem = 4096 65536 134217728" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    
    # Apply sysctl settings
    sysctl -p
    
    echo "EFA device configured successfully"
else
    echo "Warning: EFA device $EFA_DEVICE not found"
fi

# Install and configure MPI libraries
yum install -y openmpi openmpi-devel

# Configure OpenMPI for EFA
cat > /etc/openmpi-x86_64/openmpi-mca-params.conf << EOF
btl = ^openib
pml = ob1
btl_tcp_if_exclude = lo,docker0
btl_tcp_if_include = $EFA_DEVICE
EOF

# Install additional HPC tools
yum install -y hwloc hwloc-devel

# Configure NUMA topology
if command -v numactl &> /dev/null; then
    echo "NUMA topology:"
    numactl --hardware
fi

# Install performance monitoring tools
yum install -y perf htop iotop

# Configure CPU governor for performance
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable CPU frequency scaling
systemctl disable cpupower.service

# Install and configure EFA performance tools
yum install -y efa-utils

# Create EFA performance monitoring script
cat > /usr/local/bin/efa-monitor.sh << 'EOF'
#!/bin/bash
# EFA Performance Monitoring Script

EFA_DEVICE="${efa_device}"

if [ -e "/dev/$EFA_DEVICE" ]; then
    echo "EFA Device: $EFA_DEVICE"
    echo "Link Status: $(cat /sys/class/net/$EFA_DEVICE/operstate)"
    echo "MTU: $(cat /sys/class/net/$EFA_DEVICE/mtu)"
    echo "RX Packets: $(cat /sys/class/net/$EFA_DEVICE/statistics/rx_packets)"
    echo "TX Packets: $(cat /sys/class/net/$EFA_DEVICE/statistics/tx_packets)"
    echo "RX Bytes: $(cat /sys/class/net/$EFA_DEVICE/statistics/rx_bytes)"
    echo "TX Bytes: $(cat /sys/class/net/$EFA_DEVICE/statistics/tx_bytes)"
    echo "RX Errors: $(cat /sys/class/net/$EFA_DEVICE/statistics/rx_errors)"
    echo "TX Errors: $(cat /sys/class/net/$EFA_DEVICE/statistics/tx_errors)"
fi
EOF

chmod +x /usr/local/bin/efa-monitor.sh

# Create systemd service for EFA monitoring
cat > /etc/systemd/system/efa-monitor.service << 'EOF'
[Unit]
Description=EFA Performance Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/efa-monitor.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable efa-monitor.service

# Configure log rotation for EFA logs
cat > /etc/logrotate.d/efa << 'EOF'
/var/log/efa-setup.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 root root
}
EOF

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent for EFA metrics
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "HPC/EFA",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "diskio": {
                "measurement": ["io_time"],
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
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/efa-setup.log",
                        "log_group_name": "/aws/hpc/$CLUSTER_NAME/efa",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

echo "EFA setup completed successfully"
