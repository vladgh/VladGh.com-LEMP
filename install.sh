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
NGINX_VER="0.9.5"
PHP_VER="5.3.5"
APC_VER="3.1.7"
SUHOSIN_VER="0.9.32.1"
LOG_FILE="install.log"

# Check if you are root
if [ $(id -u) != "0" ]; then
  echo "Error: You must be root to run this installer."
  echo "Error: Please use 'sudo'."
  exit 1
fi

# Logging everything to LOG_FILE 
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$LOG_FILE 2>&1
# Traps CTRL-C
trap "echo -e '\nCancelled by user' >&3; echo -e '\nCancelled by user'; exit 1" 2

clear
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

CUR_DIR=$(pwd)

### Update the system
echo "Updating apt-get..." >&3
apt-get -y update

### Install Dependencies
echo "Installing dependencies..." >&3
apt-get -y install htop vim-nox binutils cpp flex gcc libarchive-zip-perl libc6-dev libcompress-zlib-perl m4 libpcre3 libpcre3-dev libssl-dev libpopt-dev lynx make perl perl-modules openssl unzip zip autoconf2.13 gnu-standards automake libtool bison build-essential zlib1g-dev ntp ntpdate autotools-dev g++ bc subversion psmisc

### Install PHP Libs
echo "Installing the PHP libraries..." >&3
apt-get -y install libmysqlclient-dev libcurl4-openssl-dev libgd2-xpm-dev libjpeg62-dev libpng3-dev libxpm-dev libfreetype6-dev libt1-dev libmcrypt-dev libxslt1-dev libbz2-dev libxml2-dev libevent-dev libltdl-dev libmagickwand-dev imagemagick

### Install MySQL
echo "Installing the MySQL..." >&3
apt-get -y install mysql-server mysql-client >&3

### Download the packages
echo "Downloading and extracting nginx-$NGINX_VER..." >&3
mkdir /var/www
mkdir $CUR_DIR/lemp_sources
cd $CUR_DIR/lemp_sources
wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz
tar zxvf nginx-$NGINX_VER.tar.gz

echo "Downloading and extracting PHP-$PHP_VER..." >&3
wget http://us2.php.net/distributions/php-$PHP_VER.tar.gz
tar xzvf php-$PHP_VER.tar.gz

echo "Downloading and extracting APC-$APC_VER..." >&3
wget http://pecl.php.net/get/APC-$APC_VER.tgz
tar xzvf APC-$APC_VER.tgz

echo "Downloading and extracting Suhosin-$SUHOSIN_VER..." >&3
wget http://download.suhosin.org/suhosin-$SUHOSIN_VER.tar.gz
tar zxvf suhosin-$SUHOSIN_VER.tar.gz

### Check download
if [ -d "$CUR_DIR/lemp_sources/nginx-$NGINX_VER" ] && [ -d "$CUR_DIR/lemp_sources/php-$PHP_VER" ] && [ -d "$CUR_DIR/lemp_sources/APC-$APC_VER" ] && [ -d "$CUR_DIR/lemp_sources/suhosin-$SUHOSIN_VER" ] ; then
  echo 'NginX, PHP, APC and Suhosin download and extraction successful.' >&3
else
  echo 'Error: Download was unsuccessful.' >&3
  echo "Check the install.log for errors." >&3
  echo 'Press any key to exit...' >&3
  read -n 1
  exit 1   
fi

### Compile PHP
echo "Installing PHP (Please be patient, this will take a while...)" >&3
cd php-$PHP_VER
./buildconf --force
./configure \
  --prefix=/opt/php5 \
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
  --enable-sysvmsg
make
make install

echo 'Configuring PHP...' >&3
echo '
if [ -d "/opt/php5/bin" ] && [ -d "/opt/php5/sbin" ]; then
    PATH="$PATH:/opt/php5/bin:/opt/php5/sbin"
fi' >> /etc/bash.bashrc

export PATH="$PATH:/opt/php5/bin:/opt/php5/sbin"

mkdir -p /etc/php5/conf.d /var/log/php5-fpm

cp -f php.ini-production /etc/php5/php.ini
cp $CUR_DIR/conf_files/php-fpm.conf /etc/php5/php-fpm.conf
cp $CUR_DIR/init_files/php5-fpm /etc/init.d/php5-fpm
chmod +x /etc/init.d/php5-fpm
update-rc.d -f php5-fpm defaults

chown -R www-data:www-data /var/log/php5-fpm

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

### Installing APC
echo 'Installing APC...' >&3
cd ../APC-$APC_VER
/opt/php5/bin/phpize -clean
./configure --enable-apc --with-php-config=/opt/php5/bin/php-config --with-libdir=/opt/php5/lib/php
make
make install

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

### Installing Suhosin
echo 'Installing Suhosin...' >&3
cd ../suhosin-$SUHOSIN_VER

/opt/php5/bin/phpize -clean
./configure --with-php-config=/opt/php5/bin/php-config --with-libdir=/opt/php5/lib/php
make
make install

echo '; Suhosin Extension
extension = suhosin.so' > /etc/php5/conf.d/suhosin.ini

### Check PHP installation
if [ -e "/opt/php5/bin/php" ] ; then
  echo "=========================================================================" >&3
  echo 'PHP was successfully installed.' >&3
  /opt/php5/bin/php -v >&3
  echo "=========================================================================" >&3
else
  echo 'Error: PHP installation was unsuccessful.' >&3
  echo "Check the install.log for errors." >&3
  echo 'Press any key to exit...' >&3
  read -n 1
  exit 1
fi

### Installing NginX
echo 'Installing NginX...' >&3
cd ../nginx-$NGINX_VER/

./configure --prefix=/opt/nginx \
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
    --without-mail_smtp_module
make
make install

echo 'Configuring NginX...' >&3
cp $CUR_DIR/init_files/nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
update-rc.d -f nginx defaults
cp $CUR_DIR/conf_files/nginx.conf /etc/nginx/nginx.conf
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
cp $CUR_DIR/conf_files/example.com /etc/nginx/sites-available/example.com
ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com

cp $CUR_DIR/web_files/* /var/www

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

### Check NginX installation
if [ -e "/opt/nginx/sbin/nginx" ] ; then
  echo "=========================================================================" >&3
  echo 'NginX was successfully installed.' >&3
  /opt/nginx/sbin/nginx -v >&3
  echo "=========================================================================" >&3
else
  echo 'Error: NginX installation was unsuccessful.' >&3
  echo "Check the install.log for errors." >&3
  echo 'Press any key to exit...' >&3
  read -n 1
  exit 1
fi

echo 'Restarting servers...' >&3
pkill nginx
pkill php-fpm
/etc/init.d/php5-fpm start
/etc/init.d/nginx start

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
