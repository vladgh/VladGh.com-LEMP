#!/bin/bash

# Installing phpMyAdmin
install_phpmyadmin() {
  if [ $INSTALL_PHPMYADMIN == 'yes' ]; then
  	echo "Checking phpMyAdmin dependencies..." >&3
  	if [ ! -e /usr/bin/unzip ]; then
  		echo "Installing unzip..." >&3
  		env DEBIAN_FRONTEND=noninteractive apt-get -q -y install unzip & progress
  	fi
    echo "Downloading and extracting phpmyadmin-${PHPMYADMIN_VERSION}..." >&3
 	wget -O ${TMPDIR}/phpmyadmin-${PHPMYADMIN_VERSION}.zip "http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.zip" & progress
 	cd $TMPDIR
 	unzip phpmyadmin-${PHPMYADMIN_VERSION}.zip
 	cd $TMPDIR/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages
 	mkdir ${DESTINATION_DIR}/phpmyadmin
 	cp -R * ${DESTINATION_DIR}/phpmyadmin
 	# Make a config directory.
 	mkdir ${DESTINATION_DIR}/phpmyadmin/config
 	chmod o+rw ${DESTINATION_DIR}/phpmyadmin/config
  fi
}

