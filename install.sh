#!/bin/bash
### Ubuntu LEMP Install Script --- VladGh.com
#
####################
###   LICENSE:   ###
####################
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
# or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
#
###################
### DISCLAIMER: ###
###################
# All content provided here including the scripts is provided without
# any warranty. You use it at your own risk. I can not be held responsible
# for any damage that may occur because of it. By using the scripts I
# provide here you accept this terms.
#
# Please bear in mind that this method is intended for development
# and testing purposes only. If you care about stability and security
# you should use the packages provided by your distribution.

### Program Versions:
NGINX_STABLE="1.0.15"
NGINX_DEV="1.1.19"
PHP_53="5.3.10"
PHP_54="5.4.0"
APC_VER="3.1.10"
SUHOSIN_VER="0.9.33"

### Directories
DSTDIR="/opt"
WEBDIR="/var/www"
SRCDIR=`dirname $(readlink -f $0)`
TMPDIR="${SRCDIR}/sources"
INSTALL_FILES="${SRCDIR}/install_files/*.sh"

### Log file
LOG_FILE="install.log"

### Active user
USER=$(who mom likes | awk '{print $1}')

# Load installation files
for file in ${INSTALL_FILES} ; do
  . ${file}
done

###################################################################################
### RUN ALL THE FUNCTIONS:

check_root
log2file

# Traps CTRL-C
trap ctrl_c INT
function ctrl_c() {
  tput bold >&3; tput setaf 1 >&3; echo -e '\nCancelled by user' >&3; echo -e '\nCancelled by user'; tput sgr0 >&3; if [ -n "$!" ]; then kill $!; fi; exit 1
}

clear >&3
echo '=========================================================================' >&3
echo 'This script will install the following:' >&3
echo '=========================================================================' >&3
echo "  - Nginx ${NGINX_DEV} (development) or ${NGINX_STABLE} (stable);" >&3
echo "  - PHP ${PHP_53} or ${PHP_54};" >&3
echo "  - APC ${APC_VER};" >&3
echo "  - Suhosin ${SUHOSIN_VER} (at this moment not available for PHP 5.4)" >&3
echo '=========================================================================' >&3
echo 'For more information please visit:' >&3
echo 'https://github.com/vladgh/VladGh.com-LEMP' >&3
echo '=========================================================================' >&3
echo 'Do you want to continue[Y/n]:' >&3
read  continue_install
case  $continue_install  in
  'n'|'N'|'No'|'no')
  echo -e "\nCancelled." >&3
  exit 1
  ;;
  *)
esac

echo 'Which of the following PHP releases do you want installed:' >&3
echo "1) Current PHP 5.3 Stable (${PHP_53})(default)" >&3
echo "2) Current PHP 5.4 Stable (${PHP_54})(at this moment without the Suhosin extension)" >&3
echo -n 'Enter your menu choice [1 or 2]: ' >&3
read nginxchoice
case $nginxchoice in
  1) PHP_VER=$PHP_53 ;;
  2) PHP_VER=$PHP_54 ;;
  *) PHP_VER=$PHP_53 ;
esac

echo 'Which of the following NginX releases do you want installed:' >&3
echo "1) Latest Development Release (${NGINX_DEV})(default)" >&3
echo "2) Latest Stable Release (${NGINX_STABLE})" >&3
echo -n 'Enter your menu choice [1 or 2]: ' >&3
read nginxchoice
case $nginxchoice in
  1) NGINX_VER=$NGINX_DEV ;;
  2) NGINX_VER=$NGINX_STABLE ;;
  *) NGINX_VER=$NGINX_DEV ;
esac

prepare_system

install_mysql

install_php
install_apc
if [ $PHP_VER == $PHP_54 ]; then
  tput bold >&3; tput setaf 1 >&3; echo 'At this moment the Suhosin extension is not available for PHP 5.4' >&3; tput sgr0 >&3
else
  install_suhosin
fi
check_php

install_nginx
check_nginx

set_paths
restart_servers

chown -R $USER:$USER $SRCDIR
rm -r $TMPDIR

sleep 5

### Final check
if [ -e "/var/run/nginx.pid" ] && [ -e "/var/run/php-fpm.pid" ] ; then
  echo '=========================================================================' >&3
  echo 'All the components were successfully installed.' >&3
  echo 'If your hosts are setup correctly you should be able to see some stats at:' >&3
  echo "- http://$(hostname -f)/index.php (PHP Status page)" >&3
  echo "- http://$(hostname -f)/apc.php (APC Status page)" >&3
  echo "- http://$(hostname -f)/nginx_status (NginX Status page)" >&3
  echo "- http://$(hostname -f)/status?html (FPM Status page)" >&3
  tput bold >&3; tput setaf 1 >&3; echo 'DO NOT FORGET TO SET THE MYSQL ROOT PASSWORD:' >&3;
  echo '"sudo mysqladmin -u root password MYPASSWORD"' >&3; tput sgr0 >&3
  echo 'Press any key to exit...' >&3
  read -n 1
  exit 0
else
  echo '=========================================================================' >&3
  echo 'Errors encountered. Check the install.log.' >&3
  echo 'Press any key to exit...' >&3
  read -n 1
  exit 1
fi
