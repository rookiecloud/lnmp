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
    if [ "$VERSION" -ge 8 ]; then
        sudo dnf -y update
        sudo dnf -y install gcc gcc-c++ make openssl openssl-devel autoconf sqlite-devel krb5-devel libxml2 libxml2-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel readline readline-devel libxslt libxslt-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses curl gdbm-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel wget epel-release
        sudo dnf -y install oniguruma oniguruma-devel libmemcached libmemcached-devel
    else
        sudo yum -y update
        sudo yum -y install gcc gcc-c++ make openssl openssl-devel autoconf sqlite-devel krb5-devel libxml2 libxml2-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel readline readline-devel libxslt libxslt-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses curl gdbm-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel wget
    fi
    if [ -e /soft/oniguruma-6.7.0-1.el7.x86_64.rpm  ] ;then
		yum -y install /soft/oniguruma-6.7.0-1.el7.x86_64.rpm
	else
		wget --no-check-certificate -P /soft/ https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/oniguruma-6.7.0-1.el7.x86_64.rpm
		yum -y install /soft/oniguruma-6.7.0-1.el7.x86_64.rpm
    fi
    if [ -e /soft/oniguruma-devel-6.7.0-1.el7.x86_64.rpm  ] ;then
		tar -zxf php-7.4.33.tar.gz 
		yum -y install /soft/oniguruma-devel-6.7.0-1.el7.x86_64.rpm
	else
		wget --no-check-certificate -P /soft/ https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/oniguruma-devel-6.7.0-1.el7.x86_64.rpm
		yum -y install /soft/oniguruma-devel-6.7.0-1.el7.x86_64.rpm
fi
elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y gcc g++ make libssl-dev autoconf libsqlite3-dev libkrb5-dev libxml2 libxml2-dev bzip2 libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libfreetype6-dev libgmp-dev libreadline-dev libxslt1-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-dev libncurses5-dev curl libgdbm-dev libdb-dev libxpm-dev libx11-dev libgd-dev expat libexpat1-dev libicu-dev libmemcached-dev libonig-dev libxmlrpc-c++8-dev wget
else
    echo "不支持的操作系统类型: $OS"
    exit 1
fi

# 检查文件夹是否存在
if [ -d "/soft" ]; then
  echo "文件夹 /soft 已存在。"
else
  echo "文件夹 /soft 不存在，正在创建..."
  mkdir /soft
  if [ $? -eq 0 ]; then
    echo "文件夹 /soft 创建成功。"
  else
    echo "文件夹/soft 创建失败。"
  fi
fi

cd /soft/

# 获取 OpenSSL 版本号
OPENSSL_VERSION=$(openssl version | cut -d ' ' -f2)
OPENSSL_MAJOR_VERSION=$(echo $OPENSSL_VERSION | cut -d. -f1)

# 输出 OpenSSL 版本号
echo "OpenSSL version: $OPENSSL_VERSION"
echo "OpenSSL major version: $OPENSSL_MAJOR_VERSION"

# 判断 OpenSSL 主版本号并执行相应操作
if [ "$OPENSSL_MAJOR_VERSION" -eq 1 ]; then
    echo "OpenSSL 1.x detected"
    PHP_VERSION="php-7.4.33"
    PHP_PATH="/usr/local/php74"
elif [ "$OPENSSL_MAJOR_VERSION" -eq 3 ]; then
    echo "OpenSSL 3.x detected"
    PHP_VERSION="php-8.3.8"
    PHP_PATH="/usr/local/php83"
else
    echo "Unsupported OpenSSL version"
    exit 1
fi

# 下载并解压 PHP
if [ -e /soft/$PHP_VERSION.tar.gz ]; then
    tar -zxf $PHP_VERSION.tar.gz
else
    wget --no-check-certificate -P /soft/ https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/$PHP_VERSION.tar.gz
    tar -zxf $PHP_VERSION.tar.gz
fi

cd $PHP_VERSION

# 配置并编译 PHP
./configure --prefix=$PHP_PATH --with-fpm-user=www --with-fpm-group=www --with-curl --with-openssl --with-freetype --with-jpeg --enable-gd --with-gettext --with-iconv-dir --with-kerberos --with-libdir=lib64 --with-mysqli --with-pdo-mysql --with-pdo-sqlite --with-pear  --with-xmlrpc --with-xsl --with-zlib --with-bz2 --with-mhash --enable-gd --enable-fpm --enable-bcmath --enable-inline-optimization --enable-mbregex --enable-mbstring --enable-opcache --enable-pcntl --enable-shmop --enable-soap --enable-sockets --enable-sysvsem --enable-sysvshm --enable-xml --enable-mysqlnd

make -j$(nproc) && make install

# 配置 PHP
mkdir -p $PHP_PATH/lib
cp php.ini-development $PHP_PATH/lib/php.ini
ln -s $PHP_PATH/bin/php /usr/bin/php
ln -s $PHP_PATH/bin/php /usr/local/bin/php
ln -s $PHP_PATH/sbin/php-fpm /usr/local/sbin/php-fpm
cp $PHP_PATH/etc/php-fpm.conf.default $PHP_PATH/etc/php-fpm.conf
cp $PHP_PATH/etc/php-fpm.d/www.conf.default $PHP_PATH/etc/php-fpm.d/www.conf

sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' $PHP_PATH/lib/php.ini

# 创建 www 用户和组
if ! grep -q "^www:" /etc/group; then
    groupadd -r www
fi

if ! id -u www &>/dev/null; then
    useradd -g www -r -s /sbin/nologin -M -d /home/www www
fi

sed -i '18i pid = /var/run/php-fpm.pid' $PHP_PATH/etc/php-fpm.conf

# 创建 systemd 单元文件
(cat <<-EOF
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/php-fpm.pid
ExecStart=$PHP_PATH/sbin/php-fpm
ExecReload=/bin/kill -USR2 \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
) > /etc/systemd/system/php-fpm.service

systemctl daemon-reload
systemctl start php-fpm
systemctl enable php-fpm
systemctl status php-fpm

cd /soft

# 下载并解压 redis
if [ -e /soft/redis-6.0.2.tgz ]; then
    tar -zxf redis-6.0.2.tgz
else
    wget --no-check-certificate -P /soft/ https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/redis-6.0.2.tgz
    tar -zxf redis-6.0.2.tgz
fi

cd redis-6.0.2

$PHP_PATH/bin/phpize

./configure --with-php-config=$PHP_PATH/bin/php-config

make -j$(nproc) && make install

(cat <<-EOF
extension="redis.so"
EOF
) >> $PHP_PATH/lib/php.ini

systemctl restart php-fpm
