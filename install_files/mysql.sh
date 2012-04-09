#!/bin/bash

# Installing MySQL server (this is escaped in order to be able to type the password in the initial dialog)
function install_mysql() {
  echo 'Installing MySQL...' >&3
  env DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server mysql-client & progress
  mysql_secure_installation >&3
}

