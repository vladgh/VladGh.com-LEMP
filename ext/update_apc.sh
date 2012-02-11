#!/bin/bash
#
###################################################################
# Script to update APC to the latest version. 								  #
# February 11, 2012                            Douglas Greenbaum. #
###################################################################
#
# Needs to be called with the version number as argument and also
# with "sudo env PATH=$PATH" in front to preserve the paths.
#
# ex: $ sudo env PATH=$PATH bash update_apc.sh 5.3.8

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
		die "Must be run by root user. Use 'sudo env PATH=\$PATH bash ...'"
	fi

	# A single argument allowed
	[ "$#" -eq 1 ] || die "1 argument required, $# provided"

	# Check if version is sane
	echo $1 | grep -E -q '^[0-9].[0-9].[0-9]$' || die "Version number doesn't seem right; Please double check: $1"

	APC_VER="$1"
	DATE=`date +%Y.%m.%d`
	SRCDIR=/tmp/php_$APC_VER-$DATE
        # Get executable path
	PHP_CMD=$(type -p php) 
        # Get the PHP location prefix
        # This will likely need to be made tolerant of other versions (PHP4 | PHP6) of PHP.
        DSTDIR=$(type -p php | sed "s/\/php5\/bin\/php//g")
        # Store the configure args.
	CONFIGURE_ARGS=$("--enable-apc --with-php-config=$DSTDIR/php5/bin/php-config --with-libdir=$DSTDIR/php5/lib/php")
	if [ ! -n "$CONFIGURE_ARGS" ]; then 	# tests to see if the argument is non empty
		die "Previous arguments could not be loaded. You must run the command with 'sudo env PATH=\$PATH bash ...'"
	fi
	
	# Check if version is the same
	if [ $APC_VER == $($PHP_CMD -i 2>&1 | grep -m 2 "Version" | grep -v PHP | cut -d " " -f3) ]; then
		die "This version number is already installed."
	fi
}

get_apc() {

	# Download and extract source package
	echo "Getting APC"
	mkdir $SRCDIR; cd $SRCDIR
	wget "http://pecl.php.net/get/APC-$APC_VER.tgz"
	
	if [ ! -f "APC-$APC_VER.tar.gz" ]; then
		die "This version could not be found."
	fi	
	
	tar xzvf APC-$APC_VER.tgz; cd APC-$APC_VER
}

compile_apc() {

	# Configure and compile APC.
	echo "Configure APC with typical options..."
        $DSTDIR/php5/bin/phpize -clean
	./configure $CONFIGURE_ARGS
	make -j8
	make install

}

backup_conf() {
        # Move the current configuration to a safe place.
        echo "Backing up working config..."
        [ -e /etc/php5/conf.d/apc.ini ] && mv /etc/php5/conf.d/apc.ini /etc/php5/conf.d.bak/apc.ini
}

recover_conf() {
	# Send the new default configuration to /tmp
	[ -e /etc/php5/conf.d/apc.ini ] && mv /etc/php5/conf.d/apc.ini /tmp/apc.ini-$DATE
	
	# Recover previous configuration files
	echo "Restore working config..."
	[ -e /etc/php5/conf.d.bak/apc.ini  ] && mv /etc/php5/conf.d.bak/apc.ini /etc/php5/conf.d/apc.ini
}

restart_servers() {
	echo "Restart PHP"
	if [ $(ps -ef | grep -c "php") -gt 1 ]; then 
		ps -e | grep "php" | awk '{print $1}' | xargs sudo kill -INT
	fi
	sleep 2
	/etc/init.d/php5-fpm start
}

check_sanity $ARGS

backup_conf
get_apc
compile_apc
recover_conf
restart_servers

# Clean Sources
rm -r $SRCDIR