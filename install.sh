#!/bin/bash
### Ubuntu LEMP Install Script --- VladGh.com
#
# Directories
SRCDIR=`dirname $(readlink -f $0)`
OPTIONSFILE="${SRCDIR}/OPTIONS"
TMPDIR="${SRCDIR}/sources"
INSTALL_FILES="${SRCDIR}/install_files/*.sh"
LOG_FILE="${SRCDIR}/install.log"

# Active user
USER=$(who mom likes | awk '{print $1}')

# Load options and installation files
. $OPTIONSFILE
for file in ${INSTALL_FILES} ; do
  . ${file}
done

###############################################################################
### RUN ALL THE FUNCTIONS:

check_root
check_options
log2file

# Traps CTRL-C
trap ctrl_c INT
ctrl_c() {
  tput bold >&3; tput setaf 1 >&3; echo -e '\nCancelled by user' >&3; echo -e '\nCancelled by user'; tput sgr0 >&3; if [ -n "$!" ]; then kill $!; fi; exit 1
}

clear >&3
echo '===============================================================================' >&3
echo 'This script will install the following:' >&3
echo '===============================================================================' >&3
echo "  - Nginx ${NGINX_VERSION};" >&3
echo "  - PHP ${PHP_VERSION};" >&3
if [[ $PHP_VERSION = 5.5.* ]]; then
  echo "  - Memcache PECL Extension;" >&3
else
  echo "  - APC & Memcache PECL Extensions;" >&3
fi
[ $INSTALL_MYSQL = 'yes' ] && echo "  - MySQL (packaged version);" >&3
[ $INSTALL_MARIADB = 'yes' ] && echo "  - MariaDB (packaged version);" >&3
[ $INSTALL_PHPMYADMIN = 'yes' ] && echo "  - phpMyAdmin ${PHPMYADMIN_VERSION};" >&3
[ $INSTALL_MEMCACHED_SERVER = 'yes' ] && echo "  - Memcached Server (packaged version);" >&3
[ $INSTALL_POSTFIX = 'yes' ] && echo "  - Postfix (packaged version);" >&3
echo '===============================================================================' >&3
echo 'For more information please visit:' >&3
echo 'https://github.com/vladgh/VladGh.com-LEMP' >&3
echo '===============================================================================' >&3

prepare_system
identify_system

# MySQL
install_mysql

# MariaDB
install_mariadb

# Install phpMyAdmin
install_phpmyadmin

# PHP
install_php
[[ $PHP_VERSION = 5.5.* ]] || install_apc
install_memcached
check_php

# Nginx
install_nginx
check_nginx

# Postfix
if [ $INSTALL_POSTFIX = 'yes' ]; then
  install_postfix
  check_postfix
fi

# Clean-up
set_paths
restart_servers
chown -R $USER:$USER $SRCDIR
rm -r $TMPDIR
sleep 5

# Final check
if [ -e "/var/run/nginx.pid" ] && [ -e "/var/run/php-fpm.pid" ] ; then
  echo '===============================================================================' >&3
  echo 'All the components were successfully installed.' >&3
  echo 'You should be able to see some stats when you visit the following URLs:' >&3
  echo "- http://example.com/index.php (PHP Status page)" >&3
  [[ $PHP_VERSION = 5.5.* ]] || echo "- http://example.com/apc.php (APC Status page)" >&3
  echo "- http://example.com/nginx_status (NginX Status page)" >&3
  echo "- http://example.com/status?html (FPM Status page)" >&3
  if [ $INSTALL_MYSQL = 'yes' || $INSTALL_MYARIADB = 'yes']; then
    tput bold >&3; tput setb 4 >&3; tput setf 7 >&3
    echo 'DO NOT FORGET TO SET THE MYSQL ROOT PASSWORD:' >&3;
    tput smul >&3;
    echo '"EX: sudo mysqladmin -u root password MYPASSWORD"' >&3
    tput smul >&3;
    echo 'IF THE ABOVE FAILS, TRY YOUR ROOT PASSWORD' >&3
    tput sgr0 >&3
  fi
  if [ $INSTALL_PHPMYADMIN == 'yes' ]; then
    tput bold >&3; tput setb 4 >&3; tput setf 7 >&3
    echo 'PHPMYADMIN STILL NEEDS CONFIGURATION:' >&3;
    tput smul >&3;
    echo '"GOTO: http://domain.tld/phpmyadmin/setup"' >&3
    tput sgr0 >&3
  fi
  exit 0
else
  echo '===============================================================================' >&3
  echo 'Errors encountered. Check the install.log.' >&3
  exit 1
fi
