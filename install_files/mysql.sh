#!/bin/bash

# Installing MySQL server
install_mysql() {
  echo 'Installing MySQL...' >&3
  env DEBIAN_FRONTEND=noninteractive apt-get -q -y install mysql-server & progress
}

