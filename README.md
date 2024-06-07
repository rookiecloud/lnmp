# 快速搭建 lnmp 环境 

* 脚本适配主流的 Linux 发行版（Centos/RHEL/Debian/Ubuntu）

## 环境版本信息
```
OpenSSH 9.5p1
OpenSSL 3.1.4
Mysql 5.7.44
Nginx 1.24.0
PHP 8.3.8
 * PHP Extend
 ** Redis 6.0.2
Redis 7.2.4
```
## 使用
* 可以根据自身需要执行对应的脚本进行安装或升级
* 可以直接将shell文件和软件包放在/soft目录下，执行bash ***.sh , 方便中国大陆用户使用，如果无互联网环境，请自行配置本地仓库
* 在更新OpenSSH时，脚本会安装并开启 Telnet ，并且会关闭 Firewalld 和 Selinux ，安装成功后，Telnet 会被关闭并禁止开机启动

```shell
wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/shell/update_openssh.sh && bash update_openssh.sh
# 更新OpenSSH 和 OpenSSL
wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/shell/install_mysql.sh && bash install_mysql.sh
# 编译安装 Mysql 5.7.44
wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/shell/install_redis.sh && bash install_redis.sh
# 编译安装 Redis 7.2.4
wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/shell/install_php.sh && bash install_php.sh
# 编译安装 PHP 8.3.8 并开启扩展 Redis 6.0.2
wget --no-check-certificate https://raw.githubusercontent.com/rookiecloud/lnmp/main/shell/install_nginx.sh && bash install_nginx.sh
# 编译安装 Nginx 1.24.0
```
