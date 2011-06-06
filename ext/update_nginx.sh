#!/bin/bash
#
###################################################################
# Script to update Nginx to the latest version. 								  #
# June 3rd 2011                                      Vlad Ghinea. #
###################################################################
#
# Needs to be called with the version number as argument and also
# with "sudo env PATH=$PATH" in front to preserve the paths.
#
# ex: $ sudo env PATH=$PATH bash update_nginx.sh 1.0.4

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
		die "Must be run by root user. Use 'sudo env PATH=\$PATH bash ...'"
	fi

	# A single argument allowed
	[ "$#" -eq 1 ] || die "1 argument required, $# provided"

	# Check if version is sane
	echo $1 | grep -E -q '^[0-9].[0-9].[0-9]$' || die "Version number doesn't seem right; Please double check: $1"

	NGINX_VER="$1"
	DATE=`date +%Y.%m.%d`
	SRCDIR=/tmp/nginx_$NGINX_VER-$DATE
	NGINX_CMD=$(type -p nginx) # Get executable path
	CONFIGURE_ARGS=$($NGINX_CMD -V 2>&1 | grep "configure arguments:" | cut -d " " -f4-) # Get original configure options
	if [ ! -n "$CONFIGURE_ARGS" ]; then 	# tests to see if the argument is non empty
		die "Previous arguments could not be loaded. You must run the command with 'sudo env PATH=$PATH bash ...'"
	fi
	
	# Check if version is the same
	if [ $NGINX_VER == $($NGINX_CMD -v 2>&1 | cut -d "/" -f2) ]; then
		die "This version number is already installed."
	fi
}

get_nginx() {

	# Download and extract source package
	echo "Getting NginX"
	mkdir $SRCDIR; cd $SRCDIR
	wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz
	
	if [ ! -f "nginx-$NGINX_VER.tar.gz" ]; then
		die "This version could not be found on nginx.org/download."
	fi	
	
	tar zxvf nginx-$NGINX_VER.tar.gz; cd nginx-$NGINX_VER

}

compile_nginx() {

	# Configure and compile NginX with previous options
	echo "Configure with previous options..."
	./configure $CONFIGURE_ARGS
	make
	make install

}

recover_conf() {
	# Send the new default configuration to /tmp
	[ -d /etc/nginx ] && mv /etc/nginx /tmp/nginx-$DATE
	
	# Recover previous configuration files
	echo "Restore working Config..."
	[ -d /etc/nginx.original  ] && mv /etc/nginx.original /etc/nginx
}

restart_servers() {
	echo "Restart NginX"
	if [ $(ps -ef | grep -c "nginx") -gt 1 ]; then 
		ps -e | grep "nginx" | awk '{print $1}' | xargs sudo kill -INT
	fi
	sleep 2
	/etc/init.d/nginx start
}

check_sanity $ARGS

# Move original configuration
[ -d /etc/nginx ] && mv /etc/nginx /etc/nginx.original

get_nginx
compile_nginx
recover_conf
restart_servers

# Clean Sources
rm -r $SRCDIR
