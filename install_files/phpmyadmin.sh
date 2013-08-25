#!/bin/bash

# Installing phpMyAdmin
install_phpmyadmin() {
  if [ $INSTALL_PHPMYADMIN == 'yes' ]; then
    echo 'Installing phpMyAdmin...' >&3
    env DEBIAN_FRONTEND=noninteractive apt-get -q -y install phpmyadmin & progress
    env DEBIAN_FRONTEND=noninteractive apt-get -q -y remove apache2* & progress
  fi
}

