#!/bin/bash
#
###################################################################
# Script to change PHP version.                                   #
# January 19, 2012                                   Vlad Ghinea. #
###################################################################
#
# ex: $ sudo ext/update_php.sh 5.4.4

# Get PHP Version as a argument
ARGS="$@"

# Traps CTRL-C
trap ctrl_c INT
ctrl_c() {
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

  # Load OPTIONS
  source $(dirname $(readlink -f $0))/../OPTIONS

  # Load environment path
  source /etc/environment

  # Variables
  PHP_VER="$1"
  DATE=`date +%Y.%m.%d`
  SRCDIR=/tmp/php_${PHP_VER-$DATE}
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
  ./configure $PHP_CONFIGURE_ARGS
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
  /etc/init.d/php5-fpm stop
  sleep 1
  /etc/init.d/php5-fpm start
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

