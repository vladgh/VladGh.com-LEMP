#!/bin/bash
install_mariadb() {
  if [ $INSTALL_MARIADB == 'yes' ]; then
    echo 'Installing MariaDB dependancies...' >&3
    env DEBIAN_FRONTEND=noninteractive apt-get -q -y install python-software-properties & progress
    echo 'Adding MariaDB keys...' >&3
    env DEBIAN_FRONTEND=noninteractive apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db & progress
    echo 'Adding MariaDB repository...' >&3
    env DEBIAN_FRONTEND=noninteractive add-apt-repository "deb http://ftp.osuosl.org/pub/mariadb/repo/${MARIADB_VERSION}/${DISTRO} ${CODENAME} main" & progress
    echo 'Updating APT...' >&3
    env DEBIAN_FRONTEND=noninteractive apt-get -q -y update & progress
    echo 'Installing MariaDB...' >&3
    env DEBIAN_FRONTEND=noninteractive apt-get -q -y install mariadb-server & progress
  fi
}