#!/bin/bash
#
###################################################################
# Script to change APC version.                                   #
# February 12, 2012                                  Vlad Ghinea. #
###################################################################
#
# ex: $ sudo ext/update_apc.sh 3.1.10

# Configure arguments:
CONFIGURE_ARGS='--enable-apc
  --with-php-config=/opt/php5/bin/php-config
  --with-libdir=/opt/php5/lib/php'

# Get APC Version as a argument
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
    die "Must be run by root user. Use 'sudo ext/update_apc.sh ...'"
  fi

  # A single argument allowed
  [ "$#" -eq 1 ] || die "1 argument required, $# provided"

  # Check if version is sane
  echo $1 | grep -E -q '^[0-9]+\.[0-9]+\.[0-9]+$' || die "Version number doesn't seem right; Please double check: $1"

  APC_VER="$1"
  DATE=`date +%Y.%m.%d`
  SRCDIR=/tmp/apc_${APC_VER-$DATE}
  # Get php executable's path
  PHP_CMD=$(type -p php)
  # Get phpize's path
  PHPIZE=$(type -p phpize)
  # Get php-config's path
  PHP_CONFIG=$(type -p php-config)
  # Get libraries' path
  LIBDIR=$(php -i | grep include_path | cut -d ' ' -f3 | sed 's/^\.\://')

  # Store the configure args.

  if [ ! -n "$CONFIGURE_ARGS" ]; then   # tests to see if the argument is non empty
    die "The paths for your previous instalation could not be loaded. You must run the command with 'sudo env PATH=\$PATH bash ...'"
  fi

  # Check if version is the same
  if [ $APC_VER == $($PHP_CMD -i 2>&1 | grep -m 2 "Version" | grep -v PHP | cut -d " " -f3) ]; then
    die 'This version number is already installed.'
  fi
}

get_apc() {

  # Download and extract source package
  echo 'Getting APC'
  [ -d $SRCDIR ] && rm -r $SRCDIR
  mkdir $SRCDIR && cd $SRCDIR
  wget "http://pecl.php.net/get/APC-${APC_VER}.tgz"

  if [ ! -f "APC-${APC_VER}.tgz" ]; then
    die 'This version could not be found.'
  fi

  tar xzvf APC-${APC_VER}.tgz; cd APC-${APC_VER}
}

compile_apc() {

  # Configure and compile APC.
  echo 'Configuring...'
  $PHPIZE -clean
  ./configure $CONFIGURE_ARGS
  make -j8
  make install

}

restart_servers() {
  echo 'Restarting PHP...'
  /etc/init.d/php5-fpm start
}

check_sanity $ARGS
get_apc
compile_apc
restart_servers

# Clean Sources
rm -r $SRCDIR

exit 0

