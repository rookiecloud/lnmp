#!/bin/bash
#########################################################
# Function :openssh-9.5p1 update                        #
# Version  :3.0                                         #
# Date     :2023-11-23                                  #     
#########################################################

export LANG="en_US.UTF-8"

#版本号
zlib_version="zlib-1.3.1"
openssl_version="openssl-3.1.4"
openssh_version="openssh-9.5p1"

#安装包地址
file="/root/OpenSSH"

#默认编译路径
default="/usr/local" 
date_time=`date +%Y-%m-%d—%H:%M`

#安装目录
file_install="$file/openssh_install"
file_backup="$file/openssh_backup"
file_log="$file/openssh_log"

#创建目录
mkdir -p $file_install
mkdir -p $file_backup
mkdir -p $file_log
mkdir -p $file_backup/zlib
mkdir -p $file_backup/ssl
mkdir -p $file_backup/ssh
mkdir -p $file_log/zlib
mkdir -p $file_log/ssl
mkdir -p $file_log/ssh

#源码包链接
zlib_download="https://rookiecloud.com/Downloads/tools/soft/$zlib_version.tar.gz"
openssl_download="https://rookiecloud.com/Downloads/tools/soft/$openssl_version.tar.gz"
openssh_download="https://rookiecloud.com/Downloads/tools/soft/$openssh_version.tar.gz"


if [ -e /root/$zlib_version.tar.gz ] ;then
		mv $zlib_version.tar.gz $file
		echo -e "\033[33m Move $zlib_version.tar.gz to $file............ \033[0m "
	else
		echo -e "\033[33m The zlib local source code package was not found and will be downloaded automatically later............ \033[0m "
	sleep 1
fi
if [ -e /root/$openssl_version.tar.gz ] ;then
		mv $openssl_version.tar.gz $file
		echo -e "\033[33m Move $openssl_version.tar.gz to $file............ \033[0m "
	else
		echo -e "\033[33m The openssl local source code package was not found and will be downloaded automatically later............ \033[0m "
	sleep 1
fi  
if [ -e /root/$openssh_version.tar.gz ] ;then
		mv $openssh_version.tar.gz $file
		echo -e "\033[33m Move $openssh_version.tar.gz to $file............ \033[0m "
	else
		echo -e "\033[33m The openssh local source code package was not found and will be downloaded automatically later............ \033[0m "
	sleep 1
fi
Install_telnet()
{
	#备份文件securetty
	cp /etc/securetty /etc/securetty_$date_time.bak
	#配置telnet登录的终端类型,增加一些pts终端
	pts=$'pts/0\npts/1\npts/2\npts/3' && echo "$pts" >> /etc/securetty
	echo Disable SElinux and Firewalld...
	sleep 2s
	setenforce 0
	sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
	cat /etc/selinux/config
	systemctl stop firewalld.service
	systemctl disable firewalld.service
echo ""
	if ! type telnet >/dev/null 2>&1; then
		echo Install telnet...
		yum install -y xinetd telnet-server telnet
		sleep 2s
        echo Success,start telnet...
        systemctl restart telnet.socket &&  systemctl restart xinetd
        systemctl enable telnet.socket
        systemctl enable xinetd
        sleep 1s
	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " Start telnet..." "\033[32m Please continue\033[0m"
		systemctl restart telnet.socket &&  systemctl restart xinetd
        systemctl enable telnet.socket
        systemctl enable xinetd
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	fi

	telnet_status=$(systemctl is-active telnet.socket)

	if [ "$telnet_status" == "active" ]; then
		echo "Telnet is running."
	else
		echo -e "\033[33m--------------------------------------------------------------- \033[0m"
			echo -e " Telnet startup failed ,esxit......" "\033[31m Error\033[0m"
		echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo ""
		sleep 4
		exit
	fi
}

Install_make()
{
# Check if user is root
	if [ $(id -u) != "0" ]; then
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " You must use root ,esxit......" "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	sleep 4
	exit
	fi

#判断是否安装wget
echo -e "\033[33m Install Wget...... \033[0m"
sleep 2
echo ""
	if ! type wget >/dev/null 2>&1; then
		yum install -y wget
	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " wget is already installed" "\033[32m Please continue\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	fi

#判断是否安装tar
echo -e "\033[33m Install TAR...... \033[0m"
sleep 2
echo ""
	if ! type tar >/dev/null 2>&1; then
		yum install -y tar
	else
	echo ""
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " tar is already installed" "\033[32m Please continue\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	fi
	echo ""

#安装相关依赖包
echo -e "\033[33m Installing dependency packages...... \033[0m"
sleep 3
echo ""
		yum install -y gcc gcc-c++ perl glibc make autoconf openssl openssl-devel pcre-devel pam-devel zlib-devel tcp_wrappers-devel tcp_wrappers
	if [ $? -eq 0 ];then
	echo ""
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
   		echo -e " Installation of software dependency packages successful " "\033[32m Success\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	else
   	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
   		echo -e " Failed to decompress the source package and the script is exiting......." "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	sleep 4
	exit
	fi
	echo ""
}


Install_backup()
{

#备份文件（可修改）
cp -rf /usr/bin/openssl  $file_backup/ssl/openssl_$date_time.bak > /dev/null
if [ -f  "/etc/init.d/sshd" ];then
		cp -rf /etc/init.d/sshd  $file_backup/ssh/sshd_$date_time.bak > /dev/null
	else
		echo -e " /etc/init.d/sshd NOT Found " "\033[31m Not backed up(Ignorable)\033[0m"
fi
cp -rf /etc/ssh  $file_backup/ssh/ssh_$date_time.bak > /dev/null
cp -rf /usr/lib/systemd/system/sshd.service  $file_backup/ssh/sshd_$date_time.service.bak > /dev/null

if [ -f  "/etc/pam.d/sshd.pam" ];then
		cp -rf /etc/pam.d/sshd.pam  $file_backup/ssh/sshd_$date_time.pam.bak > /dev/null
	else
		echo -e " /etc/pam.d/sshd.pam NOT Found " "\033[31m Not backed up(Ignorable)\033[0m"
fi
}

Remove_openssh()
{
##并卸载原有的openssh（可修改）
rpm -e --nodeps `rpm -qa | grep ^openssh` > /dev/null 2>&1
}

Install_tar()
{

#zlib
echo -e "\033[33m Downloading Zlib...... \033[0m"
sleep 3
echo ""
	if [ -e $file/$zlib_version.tar.gz ] ;then
		echo -e " The downloaded software source code package already exists  " "\033[32m  Please continue\033[0m"
	else
		echo -e "\033[33m The zlib local source code package was not found, and the link check is being obtained............ \033[0m "
	sleep 1
	echo ""
	cd $file
	wget --no-check-certificate  $zlib_download
	echo ""
	fi
#openssl
echo -e "\033[33m Downloading Openssl...... \033[0m"
sleep 3
echo ""
	if  [ -e $file/$openssl_version.tar.gz ]  ;then
		echo -e " The downloaded software source code package already exists  " "\033[32m  Please continue\033[0m"
	else
		echo -e "\033[33m The openssl local source code package was not found, and the link check is being obtained........... \033[0m "
	echo ""
	sleep 1
	cd $file
	wget --no-check-certificate  $openssl_download
	echo ""
	fi
#openssh
echo -e "\033[33m Downloading Openssh...... \033[0m"
sleep 3
echo ""
	if [ -e /$file/$openssh_version.tar.gz ];then
		echo -e " The downloaded software source code package already exists  " "\033[32m  Please continue\033[0m"
	else
		echo -e "\033[33m The openssh local source code package was not found, and the link check is being obtained........... \033[0m "
	echo ""
	sleep 1
	cd $file
	wget --no-check-certificate  $openssh_download
	fi
}

echo ""
echo ""
#安装zlib
Install_zlib(){
echo -e "\033[33m 1.1-Unzip Zlib...... \033[0m"
sleep 3
echo ""
    cd $file && mkdir -p $file_install && tar -xzf zlib*.tar.gz -C $file_install > /dev/null
    if [ -d $file_install/$zilb_version ];then
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
              		echo -e " unzip zilb success" "\033[32m Success\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
        	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
              		echo -e " unzip zilb error ,exit......" "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
    echo ""
    sleep 4
    exit
    fi
echo -e "\033[33m 1.2-make Zlib.............. \033[0m"
sleep 3
echo ""
    cd $file_install/zlib*
	./configure --prefix=$default/$zlib_version > $file_log/zlib/zlib_configure_$date_time.txt  #> /dev/null 2>&1
	if [ $? -eq 0 ];then
	echo -e "\033[33m make -j$(nproc)... \033[0m"
		make -j$(nproc) > $file_log/zlib/zlib_make_$date_time.txt
	echo $?
	echo -e "\033[33m make test... \033[0m"
		make test > $file_log/zlib/zlib_make-test_$date_time.txt
	echo $?
	echo -e "\033[33m make install... \033[0m"
		make install > $file_log/zlib/zlib_make-install_$date_time.txt
	echo $?
	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e "  make error ,exit..." "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	sleep 4
	exit
	fi

	if [ -e $default/$zlib_version/lib/libz.so ];then
	sed -i '/zlib/'d /etc/ld.so.conf
	echo "$default/$zlib_version/lib" >> /etc/ld.so.conf
	echo "$default/$zlib_version/lib" >> /etc/ld.so.conf.d/zlib.conf
	ldconfig -v > $file_log/zlib/zlib_ldconfig_$date_time.txt > /dev/null 2>&1
	/sbin/ldconfig
	fi
}

echo ""
echo ""
Install_openssl(){
	yum update -y && yum -y install perl-Module-Load-Conditional perl-Locale-Maketext-Simple perl-Params-Check perl-ExtUtils-MakeMaker perl-CPAN perl-IPC-Cmd
echo -e "\033[33m 2.1-Unzip Openssl...... \033[0m"
sleep 3
echo ""
    cd $file  &&  tar -xvzf openssl*.tar.gz -C $file_install > /dev/null
	if [ -d $file_install/$openssl_version ];then
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
              		echo -e "  unzip OpenSSL success" "\033[32m Success\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
        	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
              		echo -e "  unzip OpenSSL error  ,exit......" "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
    echo ""
    sleep 4
    exit
    fi
	echo ""
echo -e "\033[33m 2.2-make Openssl...... \033[0m"
sleep 3
echo ""
	cd $file_install/$openssl_version
        ./config shared zlib --prefix=$default/$openssl_version >  $file_log/ssl/ssl_config_$date_time.txt  #> /dev/null 2>&1
	if [ $? -eq 0 ];then
	echo -e "\033[33m make clean... \033[0m"
		make clean > $file_log/ssl/ssl_make-clean_$date_time.txt
	echo $?
	echo -e "\033[33m make -j$(nproc)... \033[0m"
		make -j$(nproc) > $file_log/ssl/ssl_make_$date_time.txt
	echo $?
	echo -e "\033[33m make install... \033[0m"
		make install > $file_log/ssl/ssl_make-install_$date_time.txt
	echo $?
	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e "  make OpenSSL error ,exit..." "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	sleep 4
	exit
	fi

	mv /usr/bin/openssl /usr/bin/openssl_$date_time.bak    #先备份
	if [ -e $default/$openssl_version/bin/openssl ];then
	sed -i '/openssl/'d /etc/ld.so.conf
	echo "$default/$openssl_version/lib" >> /etc/ld.so.conf
	ln -s $default/$openssl_version/bin/openssl /usr/bin/openssl
	ln -s $default/$openssl_version/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1 
	ln -s $default/$openssl_version/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1 
	ln -s $default/$openssl_version/lib64/libssl.so.3 /usr/lib/libssl.so.3
	ln -s $default/$openssl_version/lib64/libcrypto.so.3 /usr/lib/libcrypto.so.3.3

	ldconfig -v > $file_log/ssl/ssl_ldconfig_$date_time.txt > /dev/null 2>&1
	/sbin/ldconfig
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " make OpenSSL " "\033[32m Success\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
echo -e "\033[33m 2.3-echo OpenSSL status.............. \033[0m"
sleep 3
echo ""
	echo -e "\033[32m====================== OpenSSL veriosn =====================  \033[0m"
	echo ""
		openssl version -a
	echo ""
	echo -e "\033[32m=======================================================  \033[0m"
	sleep 2
	else
	echo ""
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " OpenSSLThe soft connection failed and the script is exiting...." "\033[31m  Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	fi
}
echo ""
echo ""
Install_openssh(){
echo -e "\033[33m 3.1-Unzip OpenSSH...... \033[0m"
sleep 3
echo ""
	cd $file && tar -xvzf openssh*.tar.gz -C $file_install > /dev/null
	if [ -d $file_install/$openssh_version ];then
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
         echo -e "  Unzip OpenSSh Success" "\033[32m Success\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
        	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
         echo -e "  unzip OpenSSh error ,exit......" "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
    echo ""
    sleep 4
    exit
    fi
	echo ""
echo -e "\033[33m 3.2-make OpenSSH...... \033[0m"
sleep 3
echo ""
	mv /etc/ssh /etc/ssh_$date_time.bak     #先备份
	cd $file_install/$openssh_version
	./configure --prefix=$default/$openssh_version --sysconfdir=/etc/ssh --with-ssl-dir=$default/$openssl_version --with-zlib=$default/$zlib_version >  $file_log/ssh/ssh_configure_$date_time.txt
	if [ $? -eq 0 ];then
	echo -e "\033[33m make -j$(nproc)... \033[0m"
		make -j$(nproc) > $file_log/ssh/ssh_make_$date_time.txt
	echo $?
	echo -e "\033[33m make install... \033[0m"
		make install > $file_log/ssh/ssh_make-install_$date_time.txt
	echo $?
	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " make OpenSSH error,exit......" "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	sleep 4
	exit
	fi
	
	echo ""
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " make install OpenSSH " "\033[32m Success\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	sleep 2
	echo -e "\033[32m==================== OpenSSH-file veriosn =================== \033[0m"
	echo ""
		/usr/local/$openssh_version/bin/ssh -V
	echo ""
	echo -e "\033[32m======================================================= \033[0m"
	sleep 3
	echo ""

echo -e "\033[33m 3.3-move OpenSSH config file...... \033[0m"
sleep 3
echo ""
#迁移sshd
	if [ -f  "/etc/init.d/sshd" ];then
		mv /etc/init.d/sshd /etc/init.d/sshd_$date_time.bak
	else
		echo -e " /etc/init.d/sshd not fount " "\033[31m Not backed up(Ignorable)\033[0m"
	fi
	cp -rf $file_install/$openssh_version/contrib/redhat/sshd.init /etc/init.d/sshd;

	chmod u+x /etc/init.d/sshd;
	chkconfig --add sshd      ##自启动
	chkconfig --list |grep sshd;
	chkconfig sshd on
#备份启动脚本,不一定有
	if [ -f  "/usr/lib/systemd/system/sshd.service" ];then
		mv /usr/lib/systemd/system/sshd.service /usr/lib/systemd/system/sshd.service_$date_time.bak
	else
		echo -e " sshd.service not found" "\033[31m Not backed up(Ignorable)\033[0m"
	fi
#备份复制sshd.pam文件
	if [ -f "/etc/pam.d/sshd.pam" ];then
		mv /etc/pam.d/sshd.pam /etc/pam.d/sshd.pam_$date_time.bak 
	else
        echo -e " sshd.pam not found" "\033[31m Not backed up(Ignorable)\033[0m"
	fi
	cp -rf $file_install/$openssh_version/contrib/redhat/sshd.pam /etc/pam.d/sshd.pam
#迁移ssh_config	
	cp -rf $file_install/$openssh_version/sshd_config /etc/ssh/sshd_config
	sed -i 's/Subsystem/#Subsystem/g' /etc/ssh/sshd_config
	echo "Subsystem sftp $default/$openssh_version/libexec/sftp-server" >> /etc/ssh/sshd_config
	cp -rf $default/$openssh_version/sbin/sshd /usr/sbin/sshd
	cp -rf /$default/$openssh_version/bin/ssh /usr/bin/ssh
	cp -rf $default/$openssh_version/bin/ssh-keygen /usr/bin/ssh-keygen
	sed -i 's/#PasswordAuthentication\ yes/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config
	#grep -v "[[:space:]]*#" /etc/ssh/sshd_config  |grep "PubkeyAuthentication yes"
	echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

#重启sshd
	service sshd start > /dev/null 2>&1
	if [ $? -eq 0 ];then
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " start OpenSSH success" "\033[32m Success\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	echo ""
	sleep 2
	#删除源码包（可修改）
	rm -rf $file/*$zlib_version.tar.gz
	rm -rf $file/*$openssl_version.tar.gz
	rm -rf $file/*$openssh_version.tar.gz
	#rm -rf $file_install
echo -e "\033[33m 3.4-echo OpenSSH veriosn...... \033[0m"
sleep 3
echo ""
	echo -e "\033[32m==================== OpenSSH veriosn =================== \033[0m"
	echo ""
		ssh -V
	echo ""
	echo -e "\033[32m======================================================== \033[0m"
	else
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
		echo -e " start OpenSSH error......" "\033[31m Error\033[0m"
	echo -e "\033[33m--------------------------------------------------------------- \033[0m"
	sleep 4
	exit
	fi
	echo ""
}

End_install()
{

##sshd状态
	echo ""
	echo -e "\033[33m echo sshd status \033[33m"
	sleep 2
	echo ""
	systemctl status sshd
	# Check if SSH is running
	ssh_status=$(systemctl is-active sshd)
	if [ "$ssh_status" == "active" ]; then
    	echo SSH update success,disable telnet
        sleep 1s
		echo -e "\033[32m==================== OpenSSH-file veriosn =================== \033[0m"
		echo ""
			echo -e " SSH is running, disabling Telnet... " "\033[32m Success\033[0m"
		echo ""
        systemctl stop telnet.socket &&  systemctl stop xinetd
        systemctl disable telnet.socket &&  systemctl disable xinetd
		echo -e "\033[32m======================================================= \033[0m"
        sleep 1s
        rm -rf /root/update_openssh.sh
        rm -rf /root/OpenSSH
        echo -e " Openssl and OpenSSH update success! " "\033[32m Success\033[0m"
        sleep 5s
	else
    	echo SSH was not successfully installed or configured. The installation process is about to exit. Please check the logs...
        sleep 5s
	fi
}



#检查用户
if [ $(id -u) != 0 ]; then
echo -e "必须使用Root用户运行脚本" "\033[31m Failure\033[0m"
echo ""
exit
fi

#检查系统
if [ ! -e /etc/redhat-release ] || [ "$SYSTEM_VERSION" == "3" ] || [ "$SYSTEM_VERSION" == "4" ];then
clear
echo -e "脚本仅适用于RHEL和CentOS操作系统5.x-8.x版本" "\033[31m Failure\033[0m"
echo ""
exit
fi
Install_telnet
Install_make
Install_backup
Remove_openssh
Install_tar
Install_zlib
Install_openssl
Install_openssh
End_install
