#!/bin/bash

# PHP Libraries
PHP_LIBRARIES="libcurl4-openssl-dev libgd2-xpm-dev libjpeg-dev libpng3-dev libxpm-dev libfreetype6-dev libt1-dev libmcrypt-dev libxslt1-dev bzip2 libbz2-dev libxml2-dev libevent-dev libltdl-dev libmagickwand-dev libmagickcore-dev imagemagick libreadline-dev libc-client-dev libsnmp-dev snmpd snmp libpq-dev"

# MariaDB ships with its own client that conflicts with the standard one.
[ $INSTALL_MARIADB = 'no' ] && PHP_LIBRARIES="mysql-client libmysqlclient-dev $PHP_LIBRARIES"
[ $INSTALL_MARIADB = 'yes' ] && PHP_LIBRARIES="libmariadbclient-dev $PHP_LIBRARIES"

install_php() {
  # Install all PHP Libraries
  echo 'Installing PHP libraries...' >&3
  apt-get -y install $PHP_LIBRARIES & progress

  # Get PHP package
  echo "Downloading and extracting PHP-${PHP_VERSION}..." >&3
  wget -O ${TMPDIR}/php-${PHP_VERSION}.tar.gz "http://us1.php.net/distributions/php-${PHP_VERSION}.tar.gz" & progress
  cd $TMPDIR
  tar xzvf php-${PHP_VERSION}.tar.gz
  check_download "PHP5" "${TMPDIR}/php-${PHP_VERSION}.tar.gz" "${TMPDIR}/php-${PHP_VERSION}/configure"

  ### Fix Ubuntu 11.04 & 12.10 LIB PATH ###
  if [ $(arch) == 'i686' ]; then
    arch=i386-linux-gnu
  else
    arch=$(arch)-linux-gnu
  fi

  [ -f /usr/lib/${arch}/libjpeg.so ] && ln -fs /usr/lib/${arch}/libjpeg.so /usr/lib/
  [ -f /usr/lib/${arch}/libpng.so ] && ln -fs /usr/lib/${arch}/libpng.so /usr/lib/
  [ -f /usr/lib/${arch}/libXpm.so ] && ln -fs /usr/lib/${arch}/libXpm.so /usr/lib/
  [ -f /usr/lib/${arch}/libmysqlclient.so ] && ln -fs /usr/lib/${arch}/libmysqlclient.so /usr/lib/
  [ -d /usr/lib/${arch}/mit-krb5 ] && ln -fs /usr/lib/${arch}/mit-krb5/lib*.so /usr/lib/
  ##################################

  # Compile php source
  cd ${TMPDIR}/php-${PHP_VERSION}
  ./buildconf --force
  echo 'Configuring PHP (Please be patient, this will take a while...)' >&3
  ./configure $PHP_CONFIGURE_ARGS & progress

  echo 'Compiling PHP (Please be patient, this will take a while...)' >&3
  make -j8 & progress
  echo 'Installing PHP...' >&3
  make install & progress

  # Copy configuration files
  echo 'Setting up PHP...' >&3
  sed -i "s~@DESTINATION_DIR@~${DESTINATION_DIR}~" ${SRCDIR}/init_files/php5-fpm
  mkdir -p /etc/php5/conf.d /var/log/php5-fpm
  cp -f php.ini-production /etc/php5/php.ini
  cp ${SRCDIR}/conf_files/php-fpm.conf /etc/php5/php-fpm.conf
  cp ${SRCDIR}/init_files/php5-fpm /etc/init.d/php5-fpm

  # Copy status page to web path
  [ ! -d $WEB_DIR ] && mkdir $WEB_DIR
  cp ${DESTINATION_DIR}/php5/php/fpm/status.html $WEB_DIR

  # Prepare service
  chmod +x /etc/init.d/php5-fpm
  update-rc.d -f php5-fpm defaults

  # The newer versions of php complain if a time zone is not set on php.ini (so we grab the system's one)
  TIMEZONE=$([ -f /etc/timezone ] && cat /etc/timezone | sed "s/\//\\\\\//g")
  sed -i "s/^\;date\.timezone.*$/date\.timezone = \"${TIMEZONE}\" /g" /etc/php5/php.ini

  chown -R www-data:www-data /var/log/php5-fpm & progress

  # Create log rotation script
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

}

