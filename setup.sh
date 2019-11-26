#!/bin/bash


# # ########
# # Get user inputs
# # ########
# read -p 'Your name: ' namevar
# read -p 'Your Email address: ' emailvar


# # ########
# # Add repositories
# # ########
# add-apt-repository -y ppa:ondrej/php
# add-apt-repository -y ppa:phpmyadmin/ppa
# apt update
# apt upgrade -y

# # install general requirements
# apt install -y software-properties-common gdebi curl git libfreetype6-dev libjpeg-dev libmagickwand-dev libpng-dev libzip-dev


# # ########
# # Setup Apache, PHP, MySQL
# # ########

# # install apache2
# apt install -y apache2

# systemctl start apache2
# systemctl enable apache2

# setup permissions for /var/www
gpasswd -a "$(users)" www-data
chown -R "$(users)":www-data /var/www
find /var/www -type f -exec chmod 0660 {} \;
find /var/www -type d -exec chmod 2770 {} \;

# # install php 7.3
# apt install -y php7.3-fpm php7.3-common php7.3-zip php7.3-curl php7.3-xml php7.3-xmlrpc php7.3-json php7.3-mysql php7.3-pdo php7.3-gd php7.3-imagick php7.3-ldap php7.3-imap php7.3-mbstring php7.3-intl php7.3-cli php7.3-recode php7.3-tidy php7.3-bcmath php7.3-opcache php7.3-xdebug

# # configure php
# declare -A confs=(
# 	[max_execution_time]=180
# 	[max_input_time]=360
# 	[max_input_vars]=5000
# 	[memory_limit]=256M
# 	[upload_max_filesize]=128M
# 	[post_max_size]=128M
# 	[file_uploads]=On
# 	[allow_url_fopen]=On
# 	[cgi.fix_pathinfo]=0
# )

# for i in "${!confs[@]}"
# do
# 	search=$i
# 	replace=${confs[$i]}

# 	sed -i -E "s/.?(${search}).+/\1 = ${replace}/g" /etc/php/7.3/fpm/php.ini
# done

# # configure opcache
# echo "opcache.memory_consumption = 128
# opcache.interned_strings_buffer = 8
# opcache.max_accelerated_files = 4000
# opcache.revalidate_freq = 2
# opcache.fast_shutdown = 1" >> /etc/php/7.3/mods-available/opcache.ini

# # configure xdebug
# echo "xdebug.remote_autostart = 1
# xdebug.remote_enable = 1
# xdebug.remote_handler = dbgp
# xdebug.remote_host = 127.0.0.1
# xdebug.remote_log = /tmp/xdebug_remote.log
# xdebug.remote_mode = req
# xdebug.remote_port = 9000" >> /etc/php/7.3/mods-available/xdebug.ini

# # setup mysql and phpmyadmin
# apt install -y mysql-server
# apt install -y phpmyadmin

# # enable everything and restart apache
# a2enmod proxy_fcgi setenvif
# a2enconf php7.3-fpm

# systemctl restart apache2
# systemctl restart php7.3-fpm


# # ########
# # Setup DevTools
# # ########

# # install Composer
# curl -sS https://getcomposer.org/installer |php
# mv composer.phar /usr/local/bin/composer

# # install NVM
# curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.35.1/install.sh | bash

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# # setup Node.js and global npm modules
# nvm install 10.15.3
# npm i -g gulp-cli yarn

# # setup GIT
# sudo -u $(users) git config --global user.name "${namevar}"
# sudo -u $(users) git config --global user.email "${emailvar}"


# # ########
# # Install basic software
# # ########

# # code editors/IDEs
# snap install sublime-text --classic
# snap install code --classic
# snap install phpstorm --classic

# # Skype
# snap install skype --classic

# # Clipboard manager
# apt install -y copyq default-jre

# # Chrome
# echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >  /etc/apt/sources.list.d/google-chrome.list
# wget -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
# apt update
# apt install -y google-chrome-stable

# # git client GitEye
# wget -O giteye.zip https://www.collab.net/sites/default/files/downloads/GitEye-2.2.0-linux.x86_64.zip
# unzip -o giteye.zip -d /opt/giteye
# rm giteye.zip
# ln -sf /opt/giteye/GitEye /usr/bin/GitEye
# echo "[Desktop Entry]
# Version=2.2.0
# Name=GitEye
# Comment=GitEye
# Type=Application
# Categories=Development;IDE;
# Exec=/usr/bin/GitEye
# Terminal=false
# StartupNotify=true
# Icon=/opt/giteye/icon.xpm
# Name[en_US]=GitEye" > /usr/share/applications/giteye.desktop



