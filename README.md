# Vlad's LEMP install script

This script installs the latest NginX, MySQL and PHP (with APC and
Memcache extensions).

*Note APC is not yet available for PHP 5.5+.

Optionally you can install the Memcached Server and Postfix.

You can install your preferred versions for any of the programs.
Just edit the OPTIONS file and change them accordingly.

It is highly recommended to run this installer on a fresh installed system.

This is tested automatically on the following distributions (i386 & amd64):
 * Ubuntu Server 12.04 (Precise Pangolin)
 * Ubuntu Server 13.04 (Raring Ringtail)
 * Debian Server 6.0.7 (Squeeze) (amd64 only)
 * Debian Server 7.1 (Wheezy) (amd64 only)

## Usage
Make sure you have Git installed on your Ubuntu System:

    sudo apt-get install git-core screen

Clone this repository, and get the latest stable version of this script:

    git clone git://github.com/vladgh/VladGh.com-LEMP.git
    cd VladGh.com-LEMP

Start a screen session:

    screen

I recommend running everything inside a screen session because in case your
connection drops you can easily come back with `screen -rad`. If you use
something else (ex: byobu) you can skip this step.

Take a look at the OPTIONS file. This is were you can choose to install the
MySQL Server or modify the versions for any of the programs, as well as the
paths.

Run the installer:

    sudo bash install.sh

After the installer is finished (this will take a long time depending on your
server specifications), you MUST set your mysql root password:

    sudo mysqladmin -u root password 'MYPASSWORD'

You can go to your server's address and you will see the PHP info page.
Also, if you go to:

  * **http://example.com/nginx_status** - for the NginX statistics;
  * **http://example.com/status?html**  - for the FPM statistics;
  * **http://example.com/status.html**  - for the FPM real-time status page;
  * **http://example.com/apc.php**      - for the APC Cache information page.

In order to have immediate access to new paths you should also execute
`source /etc/environment`. This command reloads the new environment variables.

## Utilities
In the "ext" folder you will also find some utilities:

* `nxmksite` to generate a basic, but functional, vhost.
* `nxensite` and `nxdissite` commands to enable or disable sites in NginX.
(similar to a2ensite and a2dissite in Apache).
* `update_nginx.sh` - upgrades or modifies NginX (`sudo ext/update_nginx.sh 1.3.2`).
* `update_php.sh`   - upgrades or modifies PHP (`sudo ext/update_php.sh 5.4.4`).
* `update_apc.sh`   - upgrades or modifies APC (`sudo ext/update_apc.sh 3.1.10`).

NOTES:
  * The update_* scripts above can be used to upgrade the software, or change
  current configure arguments.
  * You can only have one argument in a strict form x.x.x.
  * The `CONFIGURE_ARGS` variable inside can be modified, but make sure the
  installation directory (`--prefix`) is the same.

## Bugs
Please report any bugs to https://github.com/vladgh/VladGh.com-LEMP/issues

## Contribute
1. Open an issue to discuss proposed changes
2. Fork the repository
3. Create your feature branch: `git checkout -b my-new-feature`
4. Commit your changes: `git commit -am 'Add some feature'`
5. Push to the branch: `git push origin my-new-feature`
6. Submit a pull request :D

## License
Licensed under the Apache License, Version 2.0.
