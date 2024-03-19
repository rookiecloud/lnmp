#!/bin/bash

sudo yum -y update
sudo yum -y install gcc gcc-c++ kernel-devel make

cd /root/

if [ -e /root/redis-7.2.4.tar.gz ] ;then
		tar -zxf redis-7.2.4.tar.gz
	else
		wget --no-check-certificate https://github.com/rookiecloud/lnmp/raw/main/soft/redis-7.2.4.tar.gz
        tar -zxf redis-7.2.4.tar.gz
fi

cd /root/redis-7.2.4

make MALLOC=libc -j$(nproc) && make install PREFIX=/usr/local/redis

(cat <<-EOF
REDIS_HOME=/tools/redis
PATH=$PATH:$REDIS_HOME/bin
EOF
) >> ~/.bash_profile

source ~/.bash_profile

mkdir -p /usr/local/redis/conf

cp /root/redis-7.2.4/redis.conf /usr/local/redis/conf/redis.conf

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
) > /usr/lib/systemd/system/redis.service

systemctl daemon-reload

systemctl enable redis.service

systemctl start redis.service

systemctl status redis.service

rm -rf /root/redis-7.2.4
rm -rf /root/redis-7.2.4.tar.gz
rm -rf /root/install_redis.sh
