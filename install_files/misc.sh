#!/bin/bash

# Essential Packages
ESSENTIAL_PACKAGES="htop vim-nox binutils cpp flex gcc libarchive-zip-perl libc6-dev m4 libpcre3 libpcre3-dev libssl-dev libpopt-dev curl make perl perl-modules openssl unzip zip autoconf2.13 gnu-standards automake libtool bison build-essential zlib1g-dev ntp ntpdate autotools-dev g++ bc subversion psmisc re2c"

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
    exit 1
  fi
}

function check_php () {
  # Check if the PHP executable exists and has the APC and Suhosin modules compiled.
  if [[ $PHP_VERSION != 5.4* ]] && [ -x "${DESTINATION_DIR}/php5/bin/php" ] && [ $(${DESTINATION_DIR}/php5/bin/php -m | grep apc) ] && [ $(${DESTINATION_DIR}/php5/bin/php -m | grep suhosin) ] ; then
    echo '===============================================================================' >&3
    echo "PHP ${PHP_VERSION} with APC and Suhosin was successfully installed." >&3
    ${DESTINATION_DIR}/php5/bin/php -v >&3
    echo '===============================================================================' >&3
  elif [[ $PHP_VERSION = 5.4* ]] && [ -x "${DESTINATION_DIR}/php5/bin/php" ] && [ $(${DESTINATION_DIR}/php5/bin/php -m | grep apc) ] ; then
    echo '===============================================================================' >&3
    echo "PHP ${PHP_VERSION} with APC was successfully installed." >&3
    ${DESTINATION_DIR}/php5/bin/php -v >&3
    echo '===============================================================================' >&3
  else
    echo 'Error: PHP installation was unsuccessful.' >&3
    echo 'Check the install.log for errors.' >&3
    exit 1
  fi
}

function check_nginx () {
  # Check if Nginx exists and is executable and display the version.
  if [ -x "${DESTINATION_DIR}/nginx/sbin/nginx" ] ; then
    echo '===============================================================================' >&3
    echo 'NginX was successfully installed.' >&3
    ${DESTINATION_DIR}/nginx/sbin/nginx -v >&3
    echo '===============================================================================' >&3
  else
    echo 'Error: NginX installation was unsuccessful.' >&3
    echo 'Check the install.log for errors.' >&3
    exit 1
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

function check_root() {
  # Check if you are root
  if [ $(id -u) != "0" ]; then
    echo 'Error: You must be root to run this installer.'
    echo "Error: Please use 'sudo'."
    exit 1
  fi
}

function check_options() {
  # Check the sanity of the options file
  # Check if enabled
  if [ $ENABLED == 'no' ]; then
    echo 'Error: This script is not enabled. To enabled it open the'
    echo "       OPTIONS file and modify ENABLED='yes'. Also please make sure"
    echo '       you check the rest of the file and adjust appropriately.'
    exit 1
  fi

  # Check if version numbers are sane
  echo $NGINX_VERSION | grep -E -q '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "NginX version number doesn't seem right; Please double check: ${NGINX_VERSION}"
  echo $PHP_VERSION | grep -E -q '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "PHP version number doesn't seem right; Please double check: ${PHP_VERSION}"
  echo $APC_VERSION | grep -E -q '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "APC version number doesn't seem right; Please double check: ${APC_VERSION}"
  echo $SUHOSIN_VERSION | grep -E -q '^[0-9]+\.[0-9]+\.[0-9]+$' || echo "SUHOSIN version number doesn't seem right; Please double check: ${SUHOSIN_VERSION}"
}

function log2file() {
  # Logging everything to LOG_FILE
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>${LOG_FILE} 2>&1
}

