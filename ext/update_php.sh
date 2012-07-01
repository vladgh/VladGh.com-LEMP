#!/bin/bash
#
###################################################################
# Script to change PHP version.                                   #
# January 19, 2012                                   Vlad Ghinea. #
###################################################################
#
# ex: $ sudo ext/update_php.sh 5.4.4

# Configure arguments:
CONFIGURE_ARGS='--prefix=/opt/php5
  --with-config-file-path=/etc/php5
  --with-config-file-scan-dir=/etc/php5/conf.d
  --with-curl
  --with-pear
  --with-gd
  --with-jpeg-dir
  --with-png-dir
  --with-zlib
  --with-xpm-dir
  --with-freetype-dir
  --with-t1lib
  --with-mcrypt
  --with-mhash
  --with-mysql
  --with-mysqli
  --with-pdo-mysql
  --with-openssl
  --with-xmlrpc
  --with-xsl
  --with-bz2
  --with-gettext
  --with-readline
  --with-fpm-user=www-data
  --with-fpm-group=www-data
  --with-imap
  --with-imap-ssl
  --with-kerberos
  --with-snmp
  --disable-debug
  --enable-fpm
  --enable-cli
  --enable-inline-optimization
  --enable-exif
  --enable-wddx
  --enable-zip
  --enable-bcmath
  --enable-calendar
  --enable-ftp
  --enable-mbstring
  --enable-soap
  --enable-sockets
  --enable-shmop
  --enable-dba
  --enable-sysvsem
  --enable-sysvshm
  --enable-sysvmsg'

# Get PHP Version as a argument
ARGS="$@"

# Traps CTRL-C
trap ctrl_c INT
function ctrl_c() {
  echo -e '\nCancelled by user'; if [ -n "$!" ]; then kill $!; fi; exit 1
}

die() {
  echo "ERROR: $1" > /dev/null 1>&2
  exit 1
}

check_sanity() {

  # Check if the script is run as root.
  if [ $(/usr/bin/id -u) != "0" ]
  then
    die "Must be run by root user. Use 'sudo ext/update_php.sh ...'"
  fi

  # A single argument allowed
  [ "$#" -eq 1 ] || die "1 argument required, $# provided"

  # Check if version is sane
  echo $1 | grep -E -q '^[0-9]+\.[0-9]+\.[0-9]+$' || die "Version number doesn't seem right; Please double check: $1"

  PHP_VER="$1"
  DATE=`date +%Y.%m.%d`
  SRCDIR=/tmp/php_${PHP_VER-$DATE}

  if [ -z "$CONFIGURE_ARGS" ]; then
    die "Configure arguments are missing ..."
  fi
}

get_php() {

  # Download and extract source package
  echo 'Getting PHP'
  [ -d $SRCDIR ] && rm -r $SRCDIR
  mkdir $SRCDIR && cd $SRCDIR
  wget "http://us.php.net/distributions/php-${PHP_VER}.tar.gz"

  if [ ! -f "php-${PHP_VER}.tar.gz" ]; then
    die 'This version could not be found on php.net/distributions.'
  fi

  tar zxvf php-${PHP_VER}.tar.gz
  if [ ! -d "php-${PHP_VER}" ]; then
    die 'The archive could not be decompressed.'
  fi
  cd php-${PHP_VER}
}

compile_php() {

  # Configure and compile NginX with previous options
  echo 'Configuring...'
  ./buildconf --force
  ./configure $CONFIGURE_ARGS
  make -j8
  make install

}

backup_conf() {
  # Move the current configuration to a safe place.
  echo 'Backing up working config...'
  [ -d /etc/php5 ] && mv /etc/php5 /etc/php5.original
}

recover_conf() {
  # Send the new default configuration to /tmp
  [ -d /etc/php5 ] && mv /etc/php5 /tmp/php5-$(date +%s)

  # Recover previous configuration files
  echo 'Restore working config...'
  [ -d /etc/php5.original ] && mv /etc/php5.original /etc/php5
}

restart_servers() {
  echo 'Restarting PHP...'
  for pid in $(ps -eo pid,cmd | grep '[p]hp-fpm: master' | awk '{print $1}'); do
    kill -INT $pid
  done
  sleep 2
  invoke-rc.d php5-fpm start
}

check_sanity $ARGS

backup_conf
get_php
compile_php
recover_conf
restart_servers

# Clean Sources
rm -r $SRCDIR

exit 0

