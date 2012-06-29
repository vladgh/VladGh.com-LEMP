#!/bin/bash

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

function check_postfix () {
  # Check if Postfix was installed correctly.
  if [ -x '/usr/sbin/postconf' ] ; then
    echo '===============================================================================' >&3
    echo 'Postfix was successfully installed.' >&3
    echo "Postfix version:$(/usr/sbin/postconf -d | grep 'mail_version = ' | cut -d '=' -f2)." >&3
    echo '===============================================================================' >&3
  else
    echo 'Error: Postfix installation was unsuccessful.' >&3
    echo 'Check the install.log for errors.' >&3
    exit 1
  fi
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

