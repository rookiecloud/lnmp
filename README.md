# 快速搭建 lnmp 环境 

* 目前系统只适用 CentOS Linux 7,其它系统请自行测试更改
* 由于 CentOS Linux 7 将于2024 年6 月30日停止维护，终止其生命周期，建议更改其他 Linux 系统

## 环境版本信息
```
OpenSSH 9.5p1
OpenSSL 3.1.4
Mysql 5.7.44
Nginx 1.24.0
PHP 7.4.33
PHP Extend
 ** Redis 6.0.2
Redis 7.2.4
```
## 使用
* 您可以根据自身需要执行对应的脚本进行安装或升级
```shell
wget --no-check-certificate https://github.com/rookiecloud/lnmp/raw/main/shell/update_openssh.sh && bash update_openssh.sh
# 更新OpenSSH 和 OpenSSL
wget --no-check-certificate https://github.com/rookiecloud/lnmp/raw/main/shell/install_mysql.sh && bash install_mysql.sh
# 编译安装 Mysql 5.7.44
wget --no-check-certificate https://github.com/rookiecloud/lnmp/raw/main/shell/install_redis.sh && bash install_redis.sh
# 编译安装 Redis 7.2.4
wget --no-check-certificate https://github.com/rookiecloud/lnmp/raw/main/shell/install_php.sh && bash install_php.sh
# 编译安装 PHP 7.4.33 并开启扩展 Redis 6.0.2
wget --no-check-certificate https://github.com/rookiecloud/lnmp/raw/main/shell/install_nginx.sh && bash install_nginx.sh
# 编译安装 Nginx 1.24.0
```
