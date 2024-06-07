#!/bin/bash

set -e

# 检测操作系统类型和版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "无法检测操作系统类型和版本"
    exit 1
fi

# 安装必要的依赖项
if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ]; then
    sudo yum -y update
    sudo yum -y install gcc gcc-c++ kernel-devel make wget
elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y gcc g++ linux-headers-$(uname -r) make wget
else
    echo "不支持的操作系统类型: $OS"
    exit 1
fi

cd /soft/

# 下载并解压 redis
if [ -e /soft/redis-7.2.4.tar.gz ]; then
    tar -zxf redis-7.2.4.tar.gz
else
    wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/redis-7.2.4.tar.gz
    tar -zxf redis-7.2.4.tar.gz
fi

cd /soft/redis-7.2.4

# 编译并安装 redis
make MALLOC=libc -j$(nproc) && make install PREFIX=/usr/local/redis

# 配置环境变量
(cat <<-EOF
export REDIS_HOME=/usr/local/redis
export PATH=\$PATH:\$REDIS_HOME/bin
EOF
) >> ~/.bash_profile

source ~/.bash_profile

# 创建配置目录
mkdir -p /usr/local/redis/conf

# 复制配置文件
cp /soft/redis-7.2.4/redis.conf /usr/local/redis/conf/redis.conf

# 创建 systemd 单元文件
(cat <<-EOF
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/conf/redis.conf
ExecStop=/usr/local/redis/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOF
) > /etc/systemd/system/redis.service

# 重新加载 systemd，启用并启动 Redis 服务
systemctl daemon-reload
systemctl enable redis.service
systemctl start redis.service
systemctl status redis.service
