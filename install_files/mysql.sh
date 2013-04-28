#!/bin/bash

# Installing MySQL server
install_mysql() {
  if [ $INSTALL_MYSQL == 'yes' ]; then
    echo 'Installing MySQL...' >&3
    env DEBIAN_FRONTEND=noninteractive apt-get -q -y install mysql-server & progress
  fi
}

