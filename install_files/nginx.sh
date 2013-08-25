#!/bin/bash

install_nginx() {
  # Create Web Directory
  [ ! -d $WEB_DIR ] && mkdir $WEB_DIR
  # Get NginX package
  echo "Downloading and extracting nginx-${NGINX_VERSION}..." >&3
  wget -O ${TMPDIR}/nginx-${NGINX_VERSION}.tar.gz "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" & progress
  cd $TMPDIR
  tar zxvf nginx-${NGINX_VERSION}.tar.gz
  check_download "NginX" "${TMPDIR}/nginx-${NGINX_VERSION}.tar.gz" "${TMPDIR}/nginx-${NGINX_VERSION}/configure"
  cd ${TMPDIR}/nginx-${NGINX_VERSION}

  # Compile php source
  echo 'Configuring NginX...' >&3
  ./configure $NGINX_CONFIGURE_ARGS & progress

  echo 'Compiling NginX...' >&3
  make -j8 & progress

  echo 'Installing NginX...' >&3
  make install & progress

  # Set-up init scripts
  sed -i "s~@DESTINATION_DIR@~${DESTINATION_DIR}~" ${SRCDIR}/init_files/nginx
  cp ${SRCDIR}/init_files/nginx /etc/init.d/nginx
  chmod +x /etc/init.d/nginx
  update-rc.d -f nginx defaults

  # Copy configuration files
  [ -d /etc/nginx ] && mv /etc/nginx /etc/nginx-backup
  cp -r ${SRCDIR}/conf_files/nginx /etc/nginx
  mkdir -p /etc/nginx/sites-enabled
  ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

  # Copy over some helper scripts.
  cp ${SRCDIR}/ext/nxensite ${DESTINATION_DIR}/nginx/sbin/nxensite
  cp ${SRCDIR}/ext/nxdissite ${DESTINATION_DIR}/nginx/sbin/nxdissite
  cp ${SRCDIR}/ext/nxmksite ${DESTINATION_DIR}/nginx/sbin/nxmksite
  chmod +x ${DESTINATION_DIR}/nginx/sbin/*

  # Make the helper scripts accessable on the path.
  ln -s ${DESTINATION_DIR}/nginx/sbin/nxensite /usr/sbin/nxensite
  ln -s ${DESTINATION_DIR}/nginx/sbin/nxdissite /usr/sbin/nxdissite
  ln -s ${DESTINATION_DIR}/nginx/sbin/nxmksite /usr/sbin/nxmksite

  cp ${SRCDIR}/web_files/* $WEB_DIR

  # Create log rotation script
  chown -R www-data:www-data /var/log/nginx
  echo '/var/log/nginx/*.log {
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  create 640 root adm
  sharedscripts
  postrotate
    [ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
  endscript
}' > /etc/logrotate.d/nginx

}

