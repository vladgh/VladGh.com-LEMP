#!/bin/bash
### Ubuntu LEMP Install Script --- VladGh.com

###################
### DISCLAIMER: ###
###################
#All content provided here including the scripts is provided without
#any warranty. You use it at your own risk. I can not be held responsible
#for any damage that may occur because of it. By using the scripts I
#provide here you accept this terms.

### Program Versions:
NGINX_VER="1.0.4"
PHP_VER="5.3.6"
APC_VER="3.1.9"
SUHOSIN_VER="0.9.32.1"

### Directories
DSTDIR="/opt"
WEBDIR="/var/www"
SRCDIR=`dirname $(readlink -f $0)`
TMPDIR="$SRCDIR/sources"

### Log file
LOG_FILE="install.log"

### Active user
USER=$(who mom likes | awk '{print $1}')

### Essential Packages
ESSENTIAL_PACKAGES="htop vim-nox binutils cpp flex gcc libarchive-zip-perl libc6-dev libcompress-zlib-perl m4 libpcre3 libpcre3-dev libssl-dev libpopt-dev lynx make perl perl-modules openssl unzip zip autoconf2.13 gnu-standards automake libtool bison build-essential zlib1g-dev ntp ntpdate autotools-dev g++ bc subversion psmisc"

### PHP Libraries
PHP_LIBRARIES="install libmysqlclient-dev libcurl4-openssl-dev libgd2-xpm-dev libjpeg62-dev libpng3-dev libxpm-dev libfreetype6-dev libt1-dev libmcrypt-dev libxslt1-dev libbz2-dev libxml2-dev libevent-dev libltdl-dev libmagickwand-dev imagemagick"

function progress() {
# Simple progress indicator at the end of line (followed by "Done" when command is completed)
	while ps |grep $!; do
		echo -en "\b-" >&3; sleep 1
		echo -en "\b\\" >&3; sleep 1
		echo -en "\b|" >&3; sleep 1
		echo -en "\b/" >&3; sleep 1
	done
	echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3
}

function prepare_system() {
	# Upgrading APT-GET
	echo "Updating apt-get..." >&3
	apt-get -y update & progress

	# Install essential packages for Ubuntu
	echo "Installing dependencies..." >&3
	apt-get -y install $ESSENTIAL_PACKAGES & progress

	# Install all PHP Libraries
	echo "Installing the PHP libraries..." >&3
	apt-get -y $PHP_LIBRARIES & progress
	
	# Create temporary folder for the sources
	mkdir $TMPDIR
}

function check_download () {
# Simple function to check if the download and extraction finished successfully.
	if [ -e "$2" ] ; then
		echo  -e '\E[47;34m'"$1 download and extraction was successful." >&3
		tput sgr0 >&3
	else
		echo "Error: $1 Download was unsuccessful." >&3
		echo "Check the install.log for errors." >&3
		echo "Press any key to exit..." >&3
		read -n 1
		exit 1   
	fi
}

function install_mysql() {
# Installing MySQL server (this is escaped in order to be able to type the password in the initial dialog)
	echo "Installing the MySQL..." >&3
	apt-get -y install mysql-server mysql-client >&3
}

function install_php() {
	# Get PHP package
	echo "Downloading and extracting PHP-$PHP_VER..." >&3
	cd $TMPDIR
	wget "http://us2.php.net/distributions/php-$PHP_VER.tar.gz" & progress
	tar xzvf php-$PHP_VER.tar.gz
	check_download "PHP5" "$TMPDIR/php-$PHP_VER.tar.gz"
	
	### Fix Ubuntu 11.04 LIB PATH ###
	[ -f /usr/lib/x86_64-linux-gnu/libjpeg.so ] && ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib/libjpeg.so
	[ -f /usr/lib/x86_64-linux-gnu/libpng.so ] && ln -s /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib/libpng.so
	[ -f /usr/lib/i386-linux-gnu/libjpeg.so ] && ln -s /usr/lib/i386-linux-gnu/libjpeg.so /usr/lib/libjpeg.so
	[ -f /usr/lib/i386-linux-gnu/libpng.so ] && ln -s /usr/lib/i386-linux-gnu/libpng.so /usr/lib/libpng.so
	##################################
	
	# Compile php source
	cd $TMPDIR/php-$PHP_VER
	./buildconf --force
	echo "Configuring PHP (Please be patient, this will take a while...)" >&3
	./configure \
--prefix=$DSTDIR/php5 \
--with-config-file-path=/etc/php5 \
--with-config-file-scan-dir=/etc/php5/conf.d \
--with-curl \
--with-pear \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-xpm-dir \
--with-freetype-dir \
--with-t1lib \
--with-mcrypt \
--with-mhash \
--with-mysql \
--with-mysqli \
--with-pdo-mysql \
--with-openssl \
--with-xmlrpc \
--with-xsl \
--with-bz2 \
--with-gettext \
--with-fpm-user=www-data \
--with-fpm-group=www-data \
--disable-debug \
--enable-fpm \
--enable-exif \
--enable-wddx \
--enable-zip \
--enable-bcmath \
--enable-calendar \
--enable-ftp \
--enable-mbstring \
--enable-soap \
--enable-sockets \
--enable-sqlite-utf8 \
--enable-shmop \
--enable-dba \
--enable-sysvsem \
--enable-sysvshm \
--enable-sysvmsg & progress
	
	echo "Compiling PHP (Please be patient, this will take a while...)" >&3
	make & progress
	echo "Installing PHP..." >&3
	make install & progress

	# Copy configuration files
	echo 'Setting up PHP...' >&3
	sed -i "s~^INSTALL_DIR=.$~INSTALL_DIR=\"$DSTDIR/php5\"~" $SRCDIR/init_files/php5-fpm
	mkdir -p /etc/php5/conf.d /var/log/php5-fpm
	cp -f php.ini-production /etc/php5/php.ini
	cp $SRCDIR/conf_files/php-fpm.conf /etc/php5/php-fpm.conf
	cp $SRCDIR/init_files/php5-fpm /etc/init.d/php5-fpm
	chmod +x /etc/init.d/php5-fpm
	update-rc.d -f php5-fpm defaults
	chown -R www-data:www-data /var/log/php5-fpm

	# Create log rotation script 
	echo 'Creating logrotate script...' >&3
	echo '/var/log/php5-fpm/*.log {
weekly
missingok
rotate 52
compress
delaycompress
notifempty
create 640 www-data www-data
sharedscripts
postrotate
	[ ! -f /var/run/php5-fpm.pid ] || kill -USR1 `cat /var/run/php5-fpm.pid`
endscript
}' > /etc/logrotate.d/php5-fpm
	
	echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3
}

function install_apc() {
	# Get APC package
	echo "Downloading and extracting APC-$APC_VER..." >&3
	cd $TMPDIR
	wget "http://pecl.php.net/get/APC-$APC_VER.tgz" & progress
	tar xzvf APC-$APC_VER.tgz
	check_download "APC" "$TMPDIR/APC-$APC_VER.tgz"

	cd $TMPDIR/APC-$APC_VER
	
	# Compile APC source
	echo 'Configuring APC...' >&3
	$DSTDIR/php5/bin/phpize -clean
	./configure --enable-apc --with-php-config=$DSTDIR/php5/bin/php-config --with-libdir=$DSTDIR/php5/lib/php & progress

	echo 'Compiling APC...' >&3
	make & progress
	
	echo 'Installing APC...' >&3
	make install

	# Copy configuration files
	echo 'extension = apc.so
apc.enabled = 1
apc.shm_size = 128M
apc.shm_segments=1
apc.write_lock = 1
apc.rfc1867 = On
apc.ttl=7200
apc.user_ttl=7200
apc.num_files_hint=1024
apc.mmap_file_mask=/tmp/apc.XXXXXX
apc.enable_cli=1
; Optional, for "[apc-warning] Potential cache slam averted for key... errors"
; apc.slam_defense = Off
' > /etc/php5/conf.d/apc.ini
	
	echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3
}

function install_suhosin() {
	#Get Suhosin packages
	echo "Downloading and extracting Suhosin-$SUHOSIN_VER..." >&3
	cd $TMPDIR
	wget "http://download.suhosin.org/suhosin-$SUHOSIN_VER.tar.gz" & progress
	tar zxvf suhosin-$SUHOSIN_VER.tar.gz
	check_download "Suhosin" "$TMPDIR/suhosin-$SUHOSIN_VER.tar.gz"
	
	cd $TMPDIR/suhosin-$SUHOSIN_VER

	# Compile Suhosin source
	echo 'Configuring Suhosin...' >&3
	$DSTDIR/php5/bin/phpize -clean	
	./configure --with-php-config=$DSTDIR/php5/bin/php-config --with-libdir=$DSTDIR/php5/lib/php & progress

	echo 'Compiling Suhosin...' >&3
	make & progress
	
	echo 'Installing Suhosin...' >&3
	make install

	# Copy configuration files
	echo '; Suhosin Extension
extension = suhosin.so' > /etc/php5/conf.d/suhosin.ini

	echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3
}

function check_php () {
	# Check if the PHP executable exists and has the APC and Suhosin modules compiled.
	if [ -x "$DSTDIR/php5/bin/php" ] && [ $($DSTDIR/php5/bin/php -m | grep apc) ] && [ $($DSTDIR/php5/bin/php -m | grep suhosin) ] ; then
		echo "=========================================================================" >&3
		echo 'PHP with APC and Suhosin was successfully installed.' >&3
		$DSTDIR/php5/bin/php -v >&3
		echo "=========================================================================" >&3
	else
		echo 'Error: PHP installation was unsuccessful.' >&3
		echo "Check the install.log for errors." >&3
		echo 'Press any key to exit...' >&3
		read -n 1
		exit 1
	fi
}

function install_nginx() {
	#Get NginX package
	echo "Downloading and extracting nginx-$NGINX_VER..." >&3
	mkdir $WEBDIR;
	cd $TMPDIR
	wget "http://nginx.org/download/nginx-$NGINX_VER.tar.gz" & progress
	tar zxvf nginx-$NGINX_VER.tar.gz
	check_download "NginX" "$TMPDIR/nginx-$NGINX_VER.tar.gz"
	
	cd $TMPDIR/nginx-$NGINX_VER/
	
	# Compile php source
	echo 'Configuring NginX...' >&3
	./configure --prefix=$DSTDIR/nginx \
--conf-path=/etc/nginx/nginx.conf \
--http-log-path=/var/log/nginx/access.log \
--error-log-path=/var/log/nginx/error.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_realip_module \
--without-mail_pop3_module \
--without-mail_imap_module \
--without-mail_smtp_module & progress
		
	echo 'Compiling NginX...' >&3
	make & progress
	
	echo 'Installing NginX...' >&3
	make install

	# Copy configuration files
	sed -i "s~^INSTALL_DIR=.$~INSTALL_DIR=\"$DSTDIR/nginx\"~" $SRCDIR/init_files/nginx
	cp $SRCDIR/init_files/nginx /etc/init.d/nginx
	chmod +x /etc/init.d/nginx
	update-rc.d -f nginx defaults
	cp $SRCDIR/conf_files/nginx.conf /etc/nginx/nginx.conf
	mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
	cp $SRCDIR/conf_files/default /etc/nginx/sites-available/default
	ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

	cp $SRCDIR/ext/nxensite $DSTDIR/nginx/sbin/nxensite
	cp $SRCDIR/ext/nxdissite $DSTDIR/nginx/sbin/nxdissite
	chmod +x $DSTDIR/nginx/sbin/*

	cp $SRCDIR/web_files/* $WEBDIR
	
	echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3

	# Create log rotation script 
	echo 'Creating logrotate script...' >&3
	chown -R www-data:www-data /var/log/nginx
	echo '/var/log/nginx/*.log {
	weekly
	missingok
	rotate 52
	compress
	delaycompress
	notifempty
	create 640 root adm
	sharedscripts
	postrotate
		[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
	endscript
}' > /etc/logrotate.d/nginx	
	
}

function check_nginx () {
	# Check if Nginx exists and is executable and display the version.
	if [ -x "$DSTDIR/nginx/sbin/nginx" ] ; then
		echo "=========================================================================" >&3
		echo 'NginX was successfully installed.' >&3
		$DSTDIR/nginx/sbin/nginx -v >&3
		echo "=========================================================================" >&3
	else
		echo 'Error: NginX installation was unsuccessful.' >&3
		echo "Check the install.log for errors." >&3
		echo 'Press any key to exit...' >&3
		read -n 1
		exit 1
	fi
}

function set_paths() {
	# Make the NginX and PHP paths global.
	echo 'Setting up paths...' >&3
	export PATH="$PATH:$DSTDIR/nginx/sbin:$DSTDIR/php5/bin:$DSTDIR/php5/sbin"
	echo "PATH=\"$PATH\"" > /etc/environment
	source /etc/environment
}

function restart_servers() {
	# Restart both NginX and PHP daemons
	echo 'Restarting servers...' >&3
	if [ $(ps -ef | egrep -c "(nginx|php-fpm)") -gt 1 ]; then 
		ps -e | grep nginx | awk '{print $1}' | xargs sudo kill -INT
	fi
	sleep 2
	/etc/init.d/php5-fpm start
	/etc/init.d/nginx start
}

function check_root() {
	# Check if you are root
	if [ $(id -u) != "0" ]; then
		echo "Error: You must be root to run this installer."
		echo "Error: Please use 'sudo'."
		exit 1
	fi
}

function log2file() {
	# Logging everything to LOG_FILE 
	exec 3>&1 4>&2
	trap 'exec 2>&4 1>&3' 0 1 2 3
	exec 1>$LOG_FILE 2>&1
}

###################################################################################
### RUN ALL THE FUNCTIONS:

check_root
log2file

# Traps CTRL-C
trap ctrl_c INT
function ctrl_c() {
	echo -e '\nCancelled by user' >&3; echo -e '\nCancelled by user'; if [ -n "$!" ]; then kill $!; fi; exit 1
}

clear >&3
echo "=========================================================================" >&3
echo "This script will install the following:" >&3
echo "=========================================================================" >&3
echo "  - Nginx $NGINX_VER;" >&3
echo "  - PHP $PHP_VER;" >&3
echo "  - APC $APC_VER;" >&3
echo "  - Suhosin $SUHOSIN_VER;" >&3
echo "=========================================================================" >&3
echo "For more information please visit:" >&3
echo "https://github.com/vladgh/VladGh.com-LEMP" >&3
echo "=========================================================================" >&3
echo "Do you want to continue[Y/n]:" >&3
read  continue_install
case  $continue_install  in
  'n'|'N'|'No'|'no') 
  echo -e "\nCancelled." >&3
  exit 1
  ;;
  *)
esac

prepare_system

install_mysql

install_php
install_apc
install_suhosin
check_php

install_nginx
check_nginx

set_paths
restart_servers

chown -R $USER:$USER $SRCDIR
rm -r $TMPDIR

sleep 5

### Final check
if [ -e "/var/run/nginx.pid" ] && [ -e "/var/run/php-fpm.pid" ] ; then
  echo "=========================================================================" >&3
  echo 'NginX, PHP, APC and Suhosin were successfully installed.' >&3
  echo 'Press any key to exit...' >&3
  read -n 1
  exit 0
else
  echo "=========================================================================" >&3
  echo "Errors encountered. Check the install.log." >&3
  echo 'Press any key to exit...' >&3
  read -n 1
  exit 1
fi
