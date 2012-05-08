#!/bin/bash

# Installing MySQL server
function install_mysql() {
  echo 'Installing MySQL...' >&3
  env DEBIAN_FRONTEND=noninteractive apt-get -q -y install mysql-server & progress
}

