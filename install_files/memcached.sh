#!/bin/bash

# Memcached
install_memcached() {
  if [ $INSTALL_MEMCACHED_SERVER == 'yes' ]; then
    echo 'Installing Memcached Server...' >&3
    env DEBIAN_FRONTEND=noninteractive apt-get -q -y install memcached libmemcached-dev & progress
  fi

  echo 'Installing Memcache PECL extension...' >&3
  ${DESTINATION_DIR}/php5/bin/pecl install memcache & progress
  echo 'extension=memcache.so' > /etc/php5/conf.d/memcache.ini

}

