#!/bin/bash

# 设置 MySQL 版本和下载链接
mysql_version="5.7.44"
mysql_tar="mysql-boost-${mysql_version}.tar.gz"
mysql_url="https://rookiecloud.com/Downloads/tools/soft/${mysql_tar}"

MariaDB_packages=$(rpm -qa | grep mariadb)

# 检查列表是否为空
if [ -z "$MariaDB_packages" ]; then
    echo "未找到 MariaDB 相关软件包."
else
    # 提示即将卸载的软件包
    echo "以下软件包将被卸载："
    echo "$MariaDB_packages"
    # 逐个卸载软件包
    for MariaDB_package in $MariaDB_packages; do
    echo "正在卸载软件包: $MariaDB_package"
    sudo rpm -e --nodeps $MariaDB_package
    echo "卸载 MariaDB 完成."
done
fi

MySQL_packages=$(rpm -qa | grep mysql)

# 检查列表是否为空
if [ -z "$MySQL_packages" ]; then
    echo "未找到 MySQL 相关软件包."
else
    # 提示即将卸载的软件包
    echo "以下软件包将被卸载："
    echo "$MySQL_packages"

    # 逐个卸载软件包
    for MySQL_package in $MySQL_packages; do
        echo "正在卸载软件包: $MySQL_package"
        sudo rpm -e --nodeps $MySQL_package
    done
    rm -rf /etc/my.cnf
    echo "卸载 MySQL 完成."
fi

# 删除 MySQL 配置文件
if [ -e /etc/my.cnf ] ;then
	rm -rf /etc/my.cnf
fi

# 安装必要的依赖项
yum -y install make gcc-c++ cmake bison-devel ncurses-devel perl openssl-devel autoconf

# 下载 MySQL 源码包
if [ -e /root/$mysql_tar ] ;then
		tar -zxf $mysql_tar
	else
		wget --no-check-certificate $mysql_url
        tar -zxf $mysql_tar
fi

# 进入 MySQL 源码目录
cd mysql-$mysql_version

# 创建数据和编译目录
mkdir -p /data/mysql 
mkdir build
cd build

# 使用 CMake 配置 MySQL
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DMYSQL_DATADIR=/data/mysql \
        -DSYSCONFDIR=/etc \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_MEMORY_STORAGE_ENGINE=1 \
        -DWITH_READLINE=1 \
        -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
        -DMYSQL_TCP_PORT=3306 \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DEXTRA_CHARSETS=all \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_BOOST=../boost

# 编译和安装 MySQL
make -j$(nproc) && make install

# 添加 MySQL 用户和组
groupadd mysql
useradd mysql -g mysql -M -s /sbin/nologin

# 初始化 MySQL 数据库
/usr/local/mysql/bin/mysqld --initialize --explicit_defaults_for_timestamp --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql

# 设置 MySQL 目录权限
chown -R mysql:mysql /usr/local/mysql
chown -R mysql:mysql /data/mysql 

# 复制 MySQL 配置文件
(cat <<-EOF
[client] 
port = 3306 
socket = /usr/local/mysql/mysql.sock 
default-character-set = utf8mb4 
 
[mysqld] 
port = 3306 
socket = /usr/local/mysql/mysql.sock 
basedir = /usr/local/mysql 
datadir = /data/mysql 
character-set-server = utf8mb4 
collation-server = utf8mb4_general_ci 
init_connect = 'SET NAMES utf8mb4' 
server-id = 1 
log-slave-updates=true 
skip-external-locking 
skip-name-resolve 
back_log = 300 
table_open_cache = 128 
max_allowed_packet = 16M 
read_buffer_size = 8M 
read_rnd_buffer_size = 64M 
sort_buffer_size = 16M 
join_buffer_size = 8M 
key_buffer_size = 128M 
thread_cache_size = 16 
log-bin = mysql-bin 
binlog_format = row 
log-slave-updates = true 
slow_query_log = on 
long_query_time = 1 
slow_query_log_file = /data/mysql/db-slow.log 
gtid_mode = ON 
enforce_gtid_consistency = ON
expire_logs_days = 7    
default_storage_engine = InnoDB 
innodb_buffer_pool_size = 1G 
innodb_data_file_path = ibdata1:10M:autoextend 
innodb_file_per_table = on 
innodb_write_io_threads = 4 
innodb_read_io_threads = 4 
innodb_thread_concurrency = 8 
innodb_purge_threads = 1 
innodb_flush_log_at_trx_commit = 1 
innodb_log_buffer_size = 8M 
innodb_log_file_size = 512M 
innodb_log_files_in_group = 3 
innodb_max_dirty_pages_pct = 90 
innodb_lock_wait_timeout = 60 
max_connections = 5000 
interactive_timeout = 28800 
wait_timeout = 28800 
sql_mode = STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION 
symbolic-links=0 
log_timestamps=SYSTEM 
 
[mysqldump] 
quick 
max_allowed_packet = 512M 
 
[mysql] 
no-auto-rehash 
default-character-set = utf8mb4 
 
[myisamchk] 
key_buffer_size = 64M 
sort_buffer_size = 64M 
read_buffer = 8M 
write_buffer = 8M 
 
[mysqlhotcopy] 
interactive-timeout 
 
[mysqld_safe] 
log-error = /data/mysql/mysql_err.log 
pid-file = /data/mysql/mysqld.pid 
EOF
) > /etc/my.cnf 

# 启动 MySQL 服务

cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld 

/etc/init.d/mysqld start 
/usr/local/mysql/bin/mysql --version && echo -e  "\e[31m mysql install is OK\e[0m" 

echo "/etc/init.d/mysqld start" >> /etc/rc.local 

# 添加 MySQL 环境变量
ln -s  /usr/local/mysql/bin/mysql /usr/bin

# 输出安装完成信息
echo "MySQL $mysql_version 安装完成."

rm -rf /root/install_mysql.sh
rm -rf /root/mysql-$mysql_version
rm -rf /root/$mysql_tar
