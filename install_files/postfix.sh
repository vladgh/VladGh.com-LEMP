#!/bin/bash

# Installing Postfix
function install_postfix() {
  echo 'Installing Postfix...' >&3
  env DEBIAN_FRONTEND=noninteractive apt-get -q -y install postfix mailutils libsasl2-modules postfix-pcre ca-certificates & progress

  # Get configuration files
  echo 'Setting up Postfix (existing main.cf has been saved to main.cf.original)...' >&3
  mv /etc/postfix/main.cf /etc/postfix/main.cf.original
  cp ${SRCDIR}/conf_files/main.cf /etc/postfix/main.cf

  # Modify configuration files
  FQDN=$(hostname -f)
  DOMAIN=$(hostname -d)
  sed -i "s/<fqdn>/$FQDN/g" /etc/postfix/main.cf
  sed -i "s/<domain>/$DOMAIN/g" /etc/postfix/main.cf

  echo -e '\E[47;34m\b\b\b\b'"Done" >&3; tput sgr0 >&3

  # Restart service
  invoke-rc.d postfix restart

}

