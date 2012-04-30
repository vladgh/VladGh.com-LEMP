#!/bin/bash

function install_suhosin() {
  #Get Suhosin packages
  echo "Downloading and extracting Suhosin-$SUHOSIN_VERSION..." >&3
  wget -O ${TMPDIR}/suhosin-${SUHOSIN_VERSION}.tgz "http://download.suhosin.org/suhosin-${SUHOSIN_VERSION}.tgz" & progress
  cd $TMPDIR
  tar zxvf suhosin-${SUHOSIN_VERSION}.tgz
  check_download "Suhosin" "${TMPDIR}/suhosin-${SUHOSIN_VERSION}.tgz" "${TMPDIR}/suhosin-${SUHOSIN_VERSION}/config.m4"
  cd ${TMPDIR}/suhosin-${SUHOSIN_VERSION}

  # Compile Suhosin source
  echo 'Configuring Suhosin...' >&3
  ${DESTINATION_DIR}/php5/bin/phpize -clean
  ./configure --with-php-config=${DESTINATION_DIR}/php5/bin/php-config --with-libdir=${DESTINATION_DIR}/php5/lib/php & progress

  echo 'Compiling Suhosin...' >&3
  make -j8 & progress

  echo 'Installing Suhosin...' >&3
  make install

  # Copy configuration files
  echo '; Suhosin Extension
extension = suhosin.so' > /etc/php5/conf.d/suhosin.ini

  echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3
}

