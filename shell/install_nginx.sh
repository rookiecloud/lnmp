#!/bin/bash

sudo yum -y update
sudo yum -y install gcc gcc-c++ gd-devel autogen autoconf kernel-devel bzip2 make perl-Module-Load-Conditional perl-Locale-Maketext-Simple perl-Params-Check perl-ExtUtils-MakeMaker perl-CPAN perl-IPC-Cmd

cd /root

if [ -e /root/jemalloc-5.3.0.tar.bz2  ] ;then
		 tar -jxf jemalloc-5.3.0.tar.bz2 -C /usr/local/
	else
		wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/jemalloc-5.3.0.tar.bz2
         tar -jxf jemalloc-5.3.0.tar.bz2 -C /usr/local/
fi

if [ -e /root/pcre-8.45.tar.gz  ] ;then
		tar -zxf pcre-8.45.tar.gz -C /usr/local/
	else
		wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/pcre-8.45.tar.gz
        tar -zxf pcre-8.45.tar.gz -C /usr/local/
fi
if [ -e /root/zlib-1.3.1.tar.gz  ] ;then
		tar -zxf zlib-1.3.1.tar.gz -C /usr/local/
	else
		wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/zlib-1.3.1.tar.gz
        tar -zxf zlib-1.3.1.tar.gz -C /usr/local/
fi
if [ -e /root/openssl-3.1.4.tar.gz  ] ;then
		tar -zxf openssl-3.1.4.tar.gz -C /usr/local/
	else
		wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/openssl-3.1.4.tar.gz
        tar -zxf openssl-3.1.4.tar.gz -C /usr/local/
fi
if [ -e /root/nginx-1.24.0.tar.gz  ] ;then
		tar -zxf nginx-1.24.0.tar.gz -C /usr/local/
	else
		wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/soft/nginx-1.24.0.tar.gz
        tar -zxf nginx-1.24.0.tar.gz -C /usr/local/
fi

if ! grep -q "^www:" /etc/group; then
    echo "Creating www group..."
    groupadd -r www
fi


if ! id -u www &>/dev/null; then
    echo "Creating www user..."
    useradd -g www -s /sbin/nologin -d /var/www -M www
fi

cd /usr/local/jemalloc-5.3.0
./autogen.sh && make -j$(nproc) && make install && ldconfig

(cat <<-EOF
/usr/local/jemalloc-5.3.0/lib
EOF
) >> /etc/ld.so.conf.d/other.conf

cd /usr/local/pcre-8.45
./configure && make -j$(nproc) && make install

cd /usr/local/zlib-1.3.1
./configure && make -j$(nproc) && make install

cd /usr/local/openssl-3.1.4
./config && make -j$(nproc) && make install

cd /usr/local/nginx-1.24.0
./configure --prefix=/usr/local/nginx \
            --user=www \
            --group=www \
			--with-openssl=/usr/local/openssl-3.1.4 \
			--with-pcre=/usr/local/pcre-8.45 \
			--with-zlib=/usr/local/zlib-1.3.1 \
			--with-http_v2_module \
			--with-stream \
			--with-stream_ssl_module \
			--with-stream_ssl_preread_module \
			--with-http_stub_status_module \
			--with-http_ssl_module \
			--with-http_image_filter_module \
			--with-http_gzip_static_module \
			--with-http_gunzip_module \
			--with-ipv6 \
			--with-http_sub_module \
			--with-http_flv_module \
			--with-http_addition_module \
			--with-http_realip_module \
			--with-http_mp4_module \
			--with-ld-opt=-Wl,-E \
			--with-cc-opt=-Wno-error \
			--with-ld-opt=-ljemalloc \
			--with-http_dav_module 

make -j$(nproc) && make install

cd /root

echo "Start Nginx"

(cat <<-EOF
[Unit]
Description=Nginx HTTP Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
) > /etc/systemd/system/nginx.service

mkdir -p /usr/local/nginx/tcp
mkdir -p /usr/local/nginx/server.conf/

(cat <<-EOF
user  www www;
worker_processes auto;
error_log  /usr/local/nginx/logs/nginx_error.log  crit;
pid    /usr/local/nginx/logs/nginx.pid;
worker_rlimit_nofile 51200;

stream{
    log_format tcp_format '\$time_local|\$remote_addr|\$protocol|\$status|\$bytes_sent|\$bytes_received|\$session_time|\$upstream_addr|\$upstream_bytes_sent|\$upstream_bytes_received|\$upstream_connect_time';
    access_log /usr/local/nginx/logstcp-access.log tcp_format;
    error_log /usr/local/nginx/logstcp-error.log;
    include /usr/local/nginx/tcp/*.conf;
}

events{
    use epoll;
    worker_connections 51200;
    multi_accept on;
}

http{
    include       mime.types;

    default_type  application/octet-stream;

    server_names_hash_bucket_size 512;
    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;
    client_max_body_size 50m;

    sendfile   on;
    tcp_nopush on;

    keepalive_timeout 60;

    tcp_nodelay on;

	fastcgi_connect_timeout 300;
	fastcgi_send_timeout 300;
	fastcgi_read_timeout 300;
	fastcgi_buffer_size 64k;
	fastcgi_buffers 4 64k;
	fastcgi_busy_buffers_size 128k;
	fastcgi_temp_file_write_size 256k;
	fastcgi_intercept_errors on;

    gzip on;
    gzip_min_length  1k;
    gzip_buffers     4 16k;
    gzip_http_version 1.1;
    gzip_comp_level 2;
    gzip_types     text/plain application/javascript application/x-javascript text/javascript text/css application/xml;
    gzip_vary on;
    gzip_proxied   expired no-cache no-store private auth;
    gzip_disable   "MSIE [1-6]\.";

	include /usr/local/nginx/server.conf/*.conf;
}
EOF
) > /usr/local/nginx/conf/nginx.conf

systemctl daemon-reload

systemctl enable nginx

systemctl start nginx

rm -rf /root/jemalloc-5.3.0.tar.bz2
rm -rf /root/pcre-8.45.tar.gz
rm -rf /root/zlib-1.3.1.tar.gz
rm -rf /root/openssl-3.1.4.tar.gz
rm -rf /root/nginx-1.24.0.tar.gz
rm -rf /root/install_nginx.sh
