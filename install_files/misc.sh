#!/bin/bash

# Essential Packages
ESSENTIAL_PACKAGES="htop vim-nox binutils cpp flex gcc libarchive-zip-perl libc6-dev m4 libpcre3 libpcre3-dev libssl-dev libpopt-dev lynx make perl perl-modules openssl unzip zip autoconf2.13 gnu-standards automake libtool bison build-essential zlib1g-dev ntp ntpdate autotools-dev g++ bc subversion psmisc re2c"

# Simple progress indicator at the end of line (followed by "Done" when command is completed)
function progress() {
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
  echo 'Updating apt-get...' >&3
  apt-get -y update & progress

  # Install essential packages for Ubuntu
  echo 'Installing dependencies...' >&3
  apt-get -y install $ESSENTIAL_PACKAGES & progress

  # Create temporary folder for the sources
  if [ -d $TMPDIR ]; then
   rm -r $TMPDIR
  else
   mkdir $TMPDIR
  fi
}

function set_paths() {
  # Make the NginX and PHP paths global.
  echo 'Setting up paths...' >&3
  export PATH="${PATH}:${DESTINATION_DIR}/nginx/sbin:${DESTINATION_DIR}/php5/bin:${DESTINATION_DIR}/php5/sbin"
  echo "PATH=\"$PATH\"" > /etc/environment
}

function restart_servers() {
  # Restart both NginX and PHP daemons
  echo 'Restarting servers...' >&3
  for pid in $(ps -eo pid,cmd | egrep '(nginx|php-fpm): master' | awk '{print $1}'); do
    kill -INT $pid
  done
  sleep 2
  invoke-rc.d php5-fpm start
  invoke-rc.d nginx start
}

function log2file() {
  # Logging everything to LOG_FILE
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>${LOG_FILE} 2>&1
}

