#!/bin/bash
#
###################################################################
# Script to update Nginx to the latest version. 								  #
# June 3rd 2011                                      Vlad Ghinea. #
###################################################################
#
# Needs to be called with the version number as argument
# ex: .scripts/update_nginx.sh 1.0.3

# Get NginX Version as a argument
ARGS="$@"

die() {
    echo "ERROR: $1" > /dev/null 1>&2
    exit 1
}

check_sanity() {

	# Check if the script is run as root.
	if [ $(/usr/bin/id -u) != "0" ]
	then
		die "Must be run by root user. Use 'sudo ...'"
	fi

	# A single argument allowed
	[ "$#" -eq 1 ] || die "1 argument required, $# provided"

	# Check if version is sane
	echo $1 | grep -E -q '^[0-9].[0-9].[0-9]$' || die "Version number doesn't seem right; Please double check: $1"

	NGINX_VER="$1"
	DATE=`date +%Y.%m.%d`
	SRCDIR=/tmp/nginx_$NGINX_VER-$DATE
	NGINX_CMD=$(which nginx) # Get executable path
	echo $NGINX_CMD
	CONFIGURE_ARGS=$($NGINX_CMD -V 2>&1 | grep "configure arguments:" | cut -d " " -f4-) # Get original configure options
	echo $CONFIGURE_ARGS
	
}

get_nginx() {

	# Download and extract source package
	echo "Getting NginX"
	mkdir $SRCDIR; cd $SRCDIR
	wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz
	tar zxvf nginx-$NGINX_VER.tar.gz; cd nginx-$NGINX_VER

}

compile_nginx() {
	# Configure and compile NginX with previous options
	echo "Configure with previous options..."
	echo "./configure $CONFIGURE_ARGS"
	#make
	#make install

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
	/usr/bin/pkill nginx
	wait 2
	/etc/init.d/nginx start
}

check_sanity $ARGS

# Move original configuration
mv /etc/nginx /etc/nginx.original

get_nginx
compile_nginx
recover_conf
restart_servers

# Clean Sources
rm -r $SRCDIR
