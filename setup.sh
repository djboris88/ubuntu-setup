#!/bin/bash

# prevent running if log file already exists, no need for running this twice
if [ -f "/home/$(users)/.ubuntu-setup" ]; then
  echo "Setup already run."
  exit 1
fi

echo "Setup run at $(date +"%Y-%m-%d %T")" > "/home/$(users)/.ubuntu-setup"

# ########
# Get user inputs
# ########
read -rp 'Your name: ' namevar
read -rp 'Your Email address: ' emailvar

# ########
# Add repositories
# ########
add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:phpmyadmin/ppa
apt update
apt upgrade -y

# install general requirements
apt install -y software-properties-common gdebi curl git libfreetype6-dev libjpeg-dev libmagickwand-dev libpng-dev libzip-dev

# ########
# Setup Apache, PHP, MySQL
# ########

# install apache2
apt install -y apache2

systemctl start apache2
systemctl enable apache2

# setup permissions for /var/www
gpasswd -a "$(users)" www-data
chown -R www-data:www-data /var/www
chmod -R 1775 /var/www
setfacl -Rdm g:www-data:rwx /var/www
setfacl -Rdm u:www-data:rwx /var/www
setfacl -Rdm "u:$(users):rwx" /var/www

# set root for 'localhost' to /var/www
sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/g" /etc/apache2/sites-available/000-default.conf

systemctl restart apache2

# setup vhost script
wget https://raw.githubusercontent.com/djboris88/ubuntu-setup/master/virtualhost.sh
mv virtualhost.sh /usr/bin/vhost
chmod +x /usr/bin/vhost

# install php 7.3
apt install -y php7.3-fpm php7.3-common php7.3-zip php7.3-curl php7.3-xml php7.3-xmlrpc php7.3-json php7.3-mysql php7.3-pdo php7.3-gd php7.3-imagick php7.3-ldap php7.3-imap php7.3-mbstring php7.3-intl php7.3-cli php7.3-recode php7.3-tidy php7.3-bcmath php7.3-opcache php7.3-xdebug

# configure php
declare -A confs=(
  [max_execution_time]=180
  [max_input_time]=360
  [max_input_vars]=5000
  [memory_limit]=256M
  [upload_max_filesize]=128M
  [post_max_size]=128M
  [file_uploads]=On
  [allow_url_fopen]=On
  [cgi.fix_pathinfo]=0
)

for i in "${!confs[@]}"; do
  search=$i
  replace=${confs[$i]}

  sed -i -E "s/.?(${search}).+/\1 = ${replace}/g" /etc/php/7.3/fpm/php.ini
done

# configure opcache
opcacheSettings="opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1"
! grep "${opcacheSettings}" -q /etc/php/7.3/mods-available/opcache.ini && echo "${opcacheSettings}" >>/etc/php/7.3/mods-available/opcache.ini

# configure xdebug
xdebugSettings="xdebug.remote_autostart = 1
xdebug.remote_enable = 1
xdebug.remote_handler = dbgp
xdebug.remote_host = 127.0.0.1
xdebug.remote_log = /tmp/xdebug_remote.log
xdebug.remote_mode = req
xdebug.remote_port = 9000"
! grep "${xdebugSettings}" -q /etc/php/7.3/mods-available/xdebug.ini && echo "${xdebugSettings}" >>/etc/php/7.3/mods-available/xdebug.ini

# enable everything and restart apache
a2enmod proxy_fcgi setenvif
a2enconf php7.3-fpm

systemctl restart apache2
systemctl restart php7.3-fpm

setup mysql and phpmyadmin
apt install -y mariadb-server mariadb-client
apt install -y phpmyadmin

# create dev:dev user for phpmyadmin
mysql --user=root mysql --execute="CREATE USER 'dev'@'%' IDENTIFIED BY 'dev';
GRANT ALL PRIVILEGES ON *.* TO 'dev'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;"

systemctl restart apache2

# ########
# Setup DevTools
# ########

# install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# install WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# install NVM
echo "Installing NVM, Node.js, npm and gulp..."
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.35.1/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# setup Node.js and global npm modules
nvm install 10.15.3
npm i -g gulp-cli yarn

# setup GIT
sudo -u "$(users)" git config --global user.name "${namevar}"
sudo -u "$(users)" git config --global user.email "${emailvar}"

# ########
# Install basic software
# ########

mkdir "/home/$(users)/.config/autostart"

# code editors/IDEs
snap install sublime-text --classic
snap install code --classic
snap install phpstorm --classic

# Skype
snap install skype --classic

# autostart
sudo -u "$(users)" echo "[Desktop Entry]
Name=skype
Icon=skype
Exec=skype
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > "/home/$(users)/.config/autostart/skype.desktop"

# Clipboard manager
apt install -y copyq default-jre xbindkeys

# autostart
sudo -u "$(users)" echo "[Desktop Entry]
Name=CopyQ
Icon=copyq
Exec=copyq
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > "/home/$(users)/.config/autostart/copyq.desktop"

# add keybinding
sudo -u "$(users)" echo '"copyq menu"
Control+Mod2 + grave' > "/home/$(users)/.xbindkeysrc"

# Screenshot tool
apt install -y flameshot

# autostart
sudo -u "$(users)" echo "[Desktop Entry]
Name=flameshot
Icon=flameshot
Exec=flameshot
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > "/home/$(users)/.config/autostart/flameshot.desktop"

# remove system keybinding and add custom
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot ['']
sudo -u "$(users)" echo '"flameshot gui"
Mod2 + Print' >> "/home/$(users)/.xbindkeysrc"

# Chrome
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >/etc/apt/sources.list.d/google-chrome.list
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
apt update
apt install -y google-chrome-stable

# git client GitEye
wget -O giteye.zip https://www.collab.net/sites/default/files/downloads/GitEye-2.2.0-linux.x86_64.zip
unzip -o giteye.zip -d /opt/giteye
rm -f giteye.zip
ln -sf /opt/giteye/GitEye /usr/bin/GitEye

echo "[Desktop Entry]
Version=2.2.0
Name=GitEye
Comment=GitEye
Type=Application
Categories=Development;IDE;
Exec=/usr/bin/GitEye
Terminal=false
StartupNotify=true
Icon=/opt/giteye/icon.xpm
Name[en_US]=GitEye" > /usr/share/applications/giteye.desktop

echo "Setup completed at $(date +"%Y-%m-%d %T")" > "/home/$(users)/.ubuntu-setup"
