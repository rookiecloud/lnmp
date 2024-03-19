#!/bin/bash

yum install -y gcc gcc-c++ openssl openssl-devel autoconf sqlite-devel krb5-devel libxml2 libxml2-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses curl gdbm-devel db4-devel libXpm-devel libX11-devel gd-devel gmp-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel libmcrypt-devel libmemcached-devel

if [ -e /root/oniguruma-6.7.0-1.el7.x86_64.rpm  ] ;then
		yum -y install oniguruma-6.7.0-1.el7.x86_64.rpm
	else
		wget --no-check-certificate https://rookiecloud.com/Downloads/tools/soft/oniguruma-6.7.0-1.el7.x86_64.rpm
		yum -y install oniguruma-6.7.0-1.el7.x86_64.rpm
fi
if [ -e /root/oniguruma-devel-6.7.0-1.el7.x86_64.rpm  ] ;then
		tar -zxf php-7.4.33.tar.gz 
		yum -y install oniguruma-devel-6.7.0-1.el7.x86_64.rpm
	else
		wget --no-check-certificate https://rookiecloud.com/Downloads/tools/soft/oniguruma-devel-6.7.0-1.el7.x86_64.rpm
		yum -y install oniguruma-devel-6.7.0-1.el7.x86_64.rpm
fi
if [ -e /root/php-7.4.33.tar.gz  ] ;then
		tar -zxf php-7.4.33.tar.gz 
	else
		wget --no-check-certificate https://rookiecloud.com/Downloads/tools/soft/php-7.4.33.tar.gz 
        tar -zxf php-7.4.33.tar.gz 
fi

cd php-7.4.33

./configure --prefix=/usr/local/php74 --with-fpm-user=www --with-fpm-group=www --with-curl --with-openssl --with-freetype --with-jpeg --enable-gd --with-gettext --with-iconv-dir --with-kerberos --with-libdir=lib64 --with-mysqli --with-pdo-mysql --with-pdo-sqlite --with-pear  --with-xmlrpc --with-xsl --with-zlib --with-bz2 --with-mhash --enable-gd --enable-fpm --enable-bcmath --enable-inline-optimization --enable-mbregex --enable-mbstring --enable-opcache --enable-pcntl --enable-shmop --enable-soap --enable-sockets --enable-sysvsem --enable-sysvshm --enable-xml --enable-mysqlnd

make -j$(nproc) && make install

cp php.ini-development /usr/local/php74/lib/php.ini
ln -s /usr/local/php74/bin/php /usr/bin/php
ln -s /usr/local/php74/bin/php /usr/local/bin/php
ln -s /usr/local/php74/sbin/php-fpm /usr/local/sbin/php-fpm
cp /usr/local/php74/etc/php-fpm.conf.default /usr/local/php74/etc/php-fpm.conf
cp /usr/local/php74/etc/php-fpm.d/www.conf.default /usr/local/php74/etc/php-fpm.d/www.conf

sed 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php74/lib/php.ini


groupadd -r www
useradd -g www -r -s /sbin/nologin -M -d /home/www www

sed -i '18i pid = /var/run/php-fpm.pid' /usr/local/php74/etc/php-fpm.conf

(cat <<-EOF
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/php-fpm.pid
ExecStart=/usr/local/php74/sbin/php-fpm
ExecReload=/bin/kill -USR2 $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
) > /etc/systemd/system/php-fpm.service

systemctl daemon-reload
systemctl start php-fpm
systemctl enable php-fpm
systemctl status php-fpm

cd /root

if [ -e /root/redis-6.0.2.tgz  ] ;then
		tar -zxf redis-6.0.2.tgz
	else
		wget --no-check-certificate https://rookiecloud.com/Downloads/tools/soft/redis-6.0.2.tgz
        tar -zxf redis-6.0.2.tgz
fi

cd redis-6.0.2

/usr/local/php74/bin/phpize

./configure -with-php-config=/usr/local/php74/bin/php-config

make -j$(nproc) && make install

(cat <<-EOF
extension="redis.so"
EOF
) >> /usr/local/php74/lib/php.ini

systemctl restart php-fpm

rm -rf /root/oniguruma-6.7.0-1.el7.x86_64.rpm
rm -rf /root/oniguruma-devel-6.7.0-1.el7.x86_64.rpm
rm -rf /root/php-7.4.33.tar.gz
rm -rf /root/redis-6.0.2.tgz
rm -rf /root/php-7.4.33
rm -rf /root/redis-6.0.2
rm -rf /root/install_php.sh
rm -rf /root/package.xml
