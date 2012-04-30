#!/bin/bash
### Ubuntu LEMP Install Script --- VladGh.com
#
####################
###   LICENSE:   ###
####################
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License. To view a copy of this license, visit
# http://creativecommons.org/licenses/by-sa/3.0/ or send a letter to
# CreativeCommons, 444 Castro Street, Suite 900
# Mountain View, California, 94041, USA.
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
function ctrl_c() {
  tput bold >&3; tput setaf 1 >&3; echo -e '\nCancelled by user' >&3; echo -e '\nCancelled by user'; tput sgr0 >&3; if [ -n "$!" ]; then kill $!; fi; exit 1
}

clear >&3
echo '===============================================================================' >&3
echo 'This script will install the following:' >&3
echo '===============================================================================' >&3
echo "  - Nginx ${NGINX_VERSION};" >&3
echo "  - PHP ${PHP_VERSION};" >&3
echo "  - APC ${APC_VERSION};" >&3
echo "  - Suhosin ${SUHOSIN_VERSION}." >&3
echo '===============================================================================' >&3
echo 'For more information please visit:' >&3
echo 'https://github.com/vladgh/VladGh.com-LEMP' >&3
echo '===============================================================================' >&3

prepare_system
install_mysql
install_php
install_apc

if [[ $PHP_VERSION = 5.4* ]]; then
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

# Get external IP if possible
wimi="http://automation.whatismyip.com/n09230945.asp"
if curl -s --head ${wimi} | grep "200 OK" > /dev/null
  then
    EXTIP=$(curl -s ${wimi})
  else
    EXTIP=$(hostname -f)
fi

### Final check
if [ -e "/var/run/nginx.pid" ] && [ -e "/var/run/php-fpm.pid" ] ; then
  echo '===============================================================================' >&3
  echo 'All the components were successfully installed.' >&3
  echo 'You should be able to see some stats when you visit the following URLs:' >&3
  echo "- http://${EXTIP}/index.php (PHP Status page)" >&3
  echo "- http://${EXTIP}/apc.php (APC Status page)" >&3
  echo "- http://${EXTIP}/nginx_status (NginX Status page)" >&3
  echo "- http://${EXTIP}/status?html (FPM Status page)" >&3
  tput bold >&3; tput setb 4 >&3; tput setf 7 >&3
  echo 'DO NOT FORGET TO SET THE MYSQL ROOT PASSWORD:' >&3;
  tput smul >&3;
  echo '"sudo mysqladmin -u root password MYPASSWORD"' >&3
  tput sgr0 >&3
  exit 0
else
  echo '===============================================================================' >&3
  echo 'Errors encountered. Check the install.log.' >&3
  exit 1
fi
