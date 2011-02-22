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

CUR_DIR=$(pwd)

### Update the system
apt-get -y update

### Install Dependencies
apt-get -y install htop vim-nox binutils cpp flex gcc libarchive-zip-perl libc6-dev libcompress-zlib-perl m4 libpcre3 libpcre3-dev libssl-dev libpopt-dev lynx make perl perl-modules openssl unzip zip autoconf2.13 gnu-standards automake libtool bison build-essential zlib1g-dev ntp ntpdate autotools-dev g++ bc subversion psmisc

### Install PHP Libs
apt-get -y install libmysqlclient-dev libcurl4-openssl-dev libgd2-xpm-dev libjpeg62-dev libpng3-dev libxpm-dev libfreetype6-dev libt1-dev libmcrypt-dev libxslt1-dev libbz2-dev libxml2-dev libevent-dev libltdl-dev libmagickwand-dev imagemagick

### Install MySQL
apt-get -y install mysql-server mysql-client

### Download the packages
mkdir /var/www
mkdir $CUR_DIR/lemp_sources
cd $CUR_DIR/lemp_sources
wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz
wget http://us2.php.net/distributions/php-$PHP_VER.tar.gz
wget http://pecl.php.net/get/APC-$APC_VER.tgz
wget http://download.suhosin.org/suhosin-$SUHOSIN_VER.tar.gz
tar zxvf nginx-$NGINX_VER.tar.gz
tar xzvf php-$PHP_VER.tar.gz
tar xzvf APC-$APC_VER.tgz
tar zxvf suhosin-$SUHOSIN_VER.tar.gz

### Compile PHP
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

cd ../suhosin-$SUHOSIN_VER

/opt/php5/bin/phpize -clean
./configure --with-php-config=/opt/php5/bin/php-config --with-libdir=/opt/php5/lib/php
make
make install

echo '; Suhosin Extension
extension = suhosin.so' > /etc/php5/conf.d/suhosin.ini

### Compile NginX
cd ../nginx-$NGINX_VER/

apt-get -y install geoip-database libgeoip-dev

./configure --prefix=/opt/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_geoip_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module
make
make install

cp $CUR_DIR/init_files/nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
update-rc.d -f nginx defaults
cp $CUR_DIR/conf_files/nginx.conf /etc/nginx/nginx.conf

cp $CUR_DIR/web_files/* /var/www

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

/etc/init.d/php5-fpm restart
/etc/init.d/nginx restart
