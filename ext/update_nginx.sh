#!/bin/bash
#
###################################################################
# Script to change Nginx version.                                 #
# June 3rd 2011                                      Vlad Ghinea. #
###################################################################
#
# ex: $ sudo ext/update_nginx.sh 1.3.2

# Get NginX Version as a argument
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
    die "Must be run by root user. Use 'sudo ext/update_nginx.sh ...'"
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
  NGINX_VER="$1"
  DATE=`date +%Y.%m.%d`
  SRCDIR=/tmp/nginx_${NGINX_VER-$DATE}
}

get_nginx() {
  # Download and extract source package
  echo 'Getting NginX'
  if [ -d $SRCDIR ]; then
    rm -r $SRCDIR && mkdir $SRCDIR && cd $SRCDIR
  else
    mkdir $SRCDIR && cd $SRCDIR
  fi
  wget -O ${SRCDIR}/nginx-${NGINX_VER}.tar.gz http://nginx.org/download/nginx-${NGINX_VER}.tar.gz

  if [ -f ${SRCDIR}/nginx-${NGINX_VER}.tar.gz ]; then
    tar zxvf nginx-${NGINX_VER}.tar.gz
  else
    die 'This version could not be found on nginx.org/download.'
  fi

  if [ -d ${SRCDIR}/nginx-${NGINX_VER} ]; then
    cd ${SRCDIR}/nginx-${NGINX_VER}
  else
    die 'Could not extract the archive.'
  fi
}

compile_nginx() {
  # Configure and compile NginX with previous options
  echo 'Configuring...'
  ./configure $NGINX_CONFIGURE_ARGS
  make -j8
  make install
}

backup_conf() {
  # Backup the old configuration
  echo 'Backing up current config...'
  [ -d /etc/nginx ] && mv /etc/nginx /etc/nginx.original
}

recover_conf() {
  # Send the new default configuration to /tmp
  [ -d /etc/nginx ] && mv /etc/nginx /tmp/nginx-$(date +%s)

  # Recover previous configuration files
  echo 'Restore working config...'
  [ -d /etc/nginx.original ] && mv /etc/nginx.original /etc/nginx
}

restart_servers() {
  echo 'Restarting NginX...'
  /etc/init.d/nginx stop
  sleep 1
  /etc/init.d/nginx start
}

check_sanity $ARGS

backup_conf
get_nginx
compile_nginx
recover_conf
restart_servers

# Clean Sources
echo 'Cleaning sources...'
rm -r $SRCDIR

exit 0

