#!/bin/bash
#
###################################################################
# Script to change PHP version.                                   #
# January 19, 2012                                   Vlad Ghinea. #
###################################################################
#
# Needs to be called with the version number as argument and also
# with "sudo env PATH=$PATH" in front to preserve the paths.
#
# ex: $ sudo env PATH=$PATH bash update_php.sh 5.3.8

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
    die "Must be run by root user. Use 'sudo env PATH=\$PATH bash ...'"
  fi

  # A single argument allowed
  [ "$#" -eq 1 ] || die "1 argument required, $# provided"

  # Check if version is sane
  echo $1 | grep -E -q '^[0-9]+\.[0-9]+\.[0-9]+$' || die "Version number doesn't seem right; Please double check: $1"

  PHP_VER="$1"
  DATE=`date +%Y.%m.%d`
  SRCDIR=/tmp/php_${PHP_VER-$DATE}
  # Get executable path
  PHP_CMD=$(type -p php)
  # Get original configure options
  CONFIGURE_ARGS=$($PHP_CMD -i 2>&1 | grep "Configure Command =>" | cut -d " " -f7- | sed "s/'//g")
  if [ ! -n "$CONFIGURE_ARGS" ]; then   # tests to see if the argument is non empty
    die "Previous configure options could not be loaded. You must run the command with 'sudo env PATH=\$PATH bash ...'"
  fi

  # Check if version is the same
  if [ $PHP_VER == $($PHP_CMD -v 2>&1 | grep "built" | cut -d " " -f2) ]; then
    die 'This version number is already installed.'
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
  echo 'Configure with previous options...'
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
  [ -d /etc/php5 ] && mv /etc/php5 /tmp/php5-${DATE}

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

