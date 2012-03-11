#!/bin/bash

function install_suhosin() {
  #Get Suhosin packages
  echo "Downloading and extracting Suhosin-$SUHOSIN_VER..." >&3
  cd $TMPDIR
  wget "http://download.suhosin.org/suhosin-$SUHOSIN_VER.tgz" & progress
  tar zxvf suhosin-$SUHOSIN_VER.tgz
  check_download "Suhosin" "$TMPDIR/suhosin-$SUHOSIN_VER.tgz"

  cd $TMPDIR/suhosin-$SUHOSIN_VER

  # Compile Suhosin source
  echo 'Configuring Suhosin...' >&3
  $DSTDIR/php5/bin/phpize -clean
  ./configure --with-php-config=$DSTDIR/php5/bin/php-config --with-libdir=$DSTDIR/php5/lib/php & progress

  echo 'Compiling Suhosin...' >&3
  make -j8 & progress

  echo 'Installing Suhosin...' >&3
  make install

  # Copy configuration files
  echo '; Suhosin Extension
extension = suhosin.so' > /etc/php5/conf.d/suhosin.ini

  echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3
}

