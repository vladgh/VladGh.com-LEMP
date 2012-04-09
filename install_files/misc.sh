#!/bin/bash

# Essential Packages
ESSENTIAL_PACKAGES="htop vim-nox binutils cpp flex gcc libarchive-zip-perl libc6-dev libcompress-zlib-perl m4 libpcre3 libpcre3-dev libssl-dev libpopt-dev lynx make perl perl-modules openssl unzip zip autoconf2.13 gnu-standards automake libtool bison build-essential zlib1g-dev ntp ntpdate autotools-dev g++ bc subversion psmisc"

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

function check_download () {
# Simple function to check if the download and extraction finished successfully.
  if [ -f "$2" ] && [ -f "$3" ] ; then
    echo  -e '\E[47;34m'"${1} download and extraction was successful." >&3; tput sgr0 >&3
  else
    echo "Error: ${1} Download was unsuccessful." >&3
    echo 'Check the install.log for errors.' >&3
    echo 'Press any key to exit...' >&3
    read -n 1
    exit 1
  fi
}

function check_php () {
  # Check if the PHP executable exists and has the APC and Suhosin modules compiled.
  if [ $PHP_VER != $PHP_54 ] && [ -x "${DSTDIR}/php5/bin/php" ] && [ $(${DSTDIR}/php5/bin/php -m | grep apc) ] && [ $(${DSTDIR}/php5/bin/php -m | grep suhosin) ] ; then
    echo '=========================================================================' >&3
    echo "PHP ${PHP_VER} with APC and Suhosin was successfully installed." >&3
    ${DSTDIR}/php5/bin/php -v >&3
    echo '=========================================================================' >&3
  elif [ $PHP_VER == $PHP_54 ] && [ -x "${DSTDIR}/php5/bin/php" ] ; then
    echo '=========================================================================' >&3
    echo "PHP ${PHP_VER} was successfully installed." >&3
    ${DSTDIR}/php5/bin/php -v >&3
    echo '=========================================================================' >&3
  else
    echo 'Error: PHP installation was unsuccessful.' >&3
    echo 'Check the install.log for errors.' >&3
    echo 'Press any key to exit...' >&3
    read -n 1
    exit 1
  fi
}

function check_nginx () {
  # Check if Nginx exists and is executable and display the version.
  if [ -x "${DSTDIR}/nginx/sbin/nginx" ] ; then
    echo '=========================================================================' >&3
    echo 'NginX was successfully installed.' >&3
    ${DSTDIR}/nginx/sbin/nginx -v >&3
    echo '=========================================================================' >&3
  else
    echo 'Error: NginX installation was unsuccessful.' >&3
    echo 'Check the install.log for errors.' >&3
    echo 'Press any key to exit...' >&3
    read -n 1
    exit 1
  fi
}

function set_paths() {
  # Make the NginX and PHP paths global.
  echo 'Setting up paths...' >&3
  export PATH="${PATH}:${DSTDIR}/nginx/sbin:${DSTDIR}/php5/bin:${DSTDIR}/php5/sbin"
  echo "PATH=\"$PATH\"" > /etc/environment
  source /etc/environment
}

function restart_servers() {
  # Restart both NginX and PHP daemons
  echo 'Restarting servers...' >&3
  if [ $(ps -ef | egrep -c "(nginx|php-fpm)") -gt 1 ]; then
    ps -e | egrep "(nginx|php)" | awk '{print $1}' | xargs kill -INT
  fi
  sleep 2
  invoke-rc.d php5-fpm start
  invoke-rc.d nginx start
}

function check_root() {
  # Check if you are root
  if [ $(id -u) != "0" ]; then
    echo 'Error: You must be root to run this installer.'
    echo "Error: Please use 'sudo'."
    exit 1
  fi
}

function log2file() {
  # Logging everything to LOG_FILE
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>${LOG_FILE} 2>&1
}

