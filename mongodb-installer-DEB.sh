#!/bin/bash
# MongoDB installer for PHP && DEB based servers

# CPR : Jd Daniel :: Ehime-ken
# MOD : 2013-10-17 @ 13:03:31
# VER : Version 1.03

clear
stty erase '^?'

# If the user is not root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# install key
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10

# create DEB source list
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list

# install package
apt-get update && apt-get install -y mongodb-10gen

: <<'END'
  Configuring MongoDB

  These packages configure MongoDB using the /etc/mongodb.conf file in conjunction 
  with the control script. You will find the control script is at /etc/init.d/mongodb.
  
  This MongoDB instance will store its data files in the /var/lib/mongodb and its log 
  files in /var/log/mongodb, and run using the mongodb user account.

  Note: If you change the user that runs the MongoDB process, you will need to modify 
  the access control rights to the /var/lib/mongodb and /var/log/mongodb directories.
END

service mongodb restart

: <<'END'
  PHP Installation
END

hash foo 2>/dev/null || {
  # test or make pecl
  packages=(make php5-dev php-pear libcurl3-openssl-dev)

  for package in "${packages[@]}"; do

    # if missing dependancies $package, prep for installation...
    [ -z `dpkg --get-selections |awk '{print $1}' |grep -x $package` ] && apt-get install -y $package

  done

  pecl install mongo
}

# test mongodb's so was installed correctly, AKA php_dir was not declared
INI=`php -i |grep 'Loaded Configuration File' |awk '{print $5}'` 
if [ -z `cat $INI |grep 'extension="mongo.so"'` ]; then
  echo -e '\n# MongoDB Installation SO\nextension="mongo.so"' >> $INI
fi

# graceful restart
apache2ctl graceful

php -r 'phpinfo();' |grep -q 'mongo'
if [ $? == 0 ]; then
  echo -e '\n\E[37;42m'"\033[1mInstallation successful!\033[0m\n"
else
    echo -e '\n\E[37;41m'"\033[1mShit broke somewhere..\033[0m\n"
fi

exit 0