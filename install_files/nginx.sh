#!/bin/bash

function install_nginx() {
  #Get NginX package
  echo "Downloading and extracting nginx-$NGINX_VER..." >&3
  mkdir $WEBDIR;
  cd $TMPDIR
  wget "http://nginx.org/download/nginx-$NGINX_VER.tar.gz" & progress
  tar zxvf nginx-$NGINX_VER.tar.gz
  check_download "NginX" "$TMPDIR/nginx-$NGINX_VER.tar.gz"

  cd $TMPDIR/nginx-$NGINX_VER/

  # Compile php source
  echo 'Configuring NginX...' >&3
  ./configure --prefix=$DSTDIR/nginx \
--conf-path=/etc/nginx/nginx.conf \
--http-log-path=/var/log/nginx/access.log \
--error-log-path=/var/log/nginx/error.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_gzip_static_module \
--without-mail_pop3_module \
--without-mail_imap_module \
--without-mail_smtp_module & progress

  echo 'Compiling NginX...' >&3
  make -j8 & progress

  echo 'Installing NginX...' >&3
  make install

  # Copy configuration files
  sed -i "s~^INSTALL_DIR=.$~INSTALL_DIR=\"$DSTDIR/nginx\"~" $SRCDIR/init_files/nginx
  cp $SRCDIR/init_files/nginx /etc/init.d/nginx
  chmod +x /etc/init.d/nginx
  update-rc.d -f nginx defaults
  cp $SRCDIR/conf_files/nginx.conf /etc/nginx/nginx.conf
  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  cp $SRCDIR/conf_files/default /etc/nginx/sites-available/default
  ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

  cp $SRCDIR/ext/nxensite $DSTDIR/nginx/sbin/nxensite
  cp $SRCDIR/ext/nxdissite $DSTDIR/nginx/sbin/nxdissite
  chmod +x $DSTDIR/nginx/sbin/*

  cp $SRCDIR/web_files/* $WEBDIR

  echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3

  # Create log rotation script
  echo 'Creating logrotate script...' >&3
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

