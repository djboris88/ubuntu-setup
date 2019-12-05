#!/bin/bash

currentUser=$(whoami)

if [ "${currentUser}" == 'root' ]
  then
    echo 'Run without sudo.'
    exit 0
fi

# prevent running if log file already exists, no need for running this twice
if [ -f "$HOME/.ubuntu-setup" ]; then
  echo "Setup already run."
  exit 1
fi

echo "Setup run at $(date +"%Y-%m-%d %T")" > "$HOME/.ubuntu-setup"

# get user inputs
echo "Setting up your default user config for GIT."

echo "Your name:"
read namevar

echo "Your email:"
read emailvar

echo "Do you want Composer installed? (y/n)"
read composer

echo "Do you want to install WP-CLI? (y/n)"
read wpCli

echo "Do you want to install NVM, Node.js, NPM and Gulp globally? (y/n)"
read node

echo "Do you want to install Sublime Text (y/n)"
read sublime

echo "Do you want to install VSCode (y/n)"
read vscode

echo "Do you want to install PHPStorm (y/n)"
read phpstorm

# ########
# Add repositories
# ########
sudo add-apt-repository -y ppa:ondrej/php
sudo add-apt-repository -y ppa:phpmyadmin/ppa
sudo apt-get update
sudo apt-get upgrade -y

# install general requirements
sudo apt-get install -y software-properties-common gdebi curl git libfreetype6-dev libjpeg-dev libmagickwand-dev libpng-dev libzip-dev default-jre xbindkeys

# ########
# Setup Apache, PHP, MySQL
# ########

# install apache2
sudo apt-get install -y apache2

sudo systemctl start apache2
sudo systemctl enable apache2

# setup permissions for /var/www
sudo gpasswd -a "${currentUser}" www-data
sudo chown -R www-data:www-data /var/www
sudo chmod -R 1775 /var/www
sudo setfacl -Rdm g:www-data:rwx /var/www
sudo setfacl -Rdm u:www-data:rwx /var/www
sudo setfacl -Rdm "u:${currentUser}:rwx" /var/www

# set root for 'localhost' to /var/www
sudo sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/g" /etc/apache2/sites-available/000-default.conf

sudo systemctl restart apache2

# setup vhost script
wget https://raw.githubusercontent.com/djboris88/ubuntu-setup/master/virtualhost.sh
sudo mv virtualhost.sh /usr/bin/vhost
sudo chmod +x /usr/bin/vhost

# install php 7.3
sudo apt-get install -y php7.3-fpm php7.3-common php7.3-zip php7.3-curl php7.3-xml php7.3-xmlrpc php7.3-json php7.3-mysql php7.3-pdo php7.3-gd php7.3-imagick php7.3-ldap php7.3-imap php7.3-mbstring php7.3-intl php7.3-cli php7.3-recode php7.3-tidy php7.3-bcmath php7.3-opcache php7.3-xdebug

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

  sudo sed -i -E "s/.?(${search}).+/\1 = ${replace}/g" /etc/php/7.3/fpm/php.ini
done

# configure opcache
opcacheSettings="opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1"
! grep "${opcacheSettings}" -q /etc/php/7.3/mods-available/opcache.ini && echo "${opcacheSettings}" | sudo tee -a /etc/php/7.3/mods-available/opcache.ini

# configure xdebug
xdebugSettings="xdebug.remote_autostart = 1
xdebug.remote_enable = 1
xdebug.remote_handler = dbgp
xdebug.remote_host = 127.0.0.1
xdebug.remote_log = /tmp/xdebug_remote.log
xdebug.remote_mode = req
xdebug.remote_port = 9000"
! grep "${xdebugSettings}" -q /etc/php/7.3/mods-available/xdebug.ini && echo "${xdebugSettings}" | sudo tee -a /etc/php/7.3/mods-available/xdebug.ini

# enable everything and restart apache
sudo a2enmod proxy_fcgi setenvif rewrite
sudo a2enconf php7.3-fpm

sudo systemctl restart apache2
sudo systemctl restart php7.3-fpm

# setup mysql and phpmyadmin
sudo apt-get install -y mariadb-server mariadb-client
sudo apt-get install -y phpmyadmin

# create dev:dev user for phpmyadmin
sudo mysql --user=root mysql --execute="CREATE USER 'dev'@'%' IDENTIFIED BY 'dev';
GRANT ALL PRIVILEGES ON *.* TO 'dev'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;"

sudo systemctl restart apache2

# ########
# Setup DevTools
# ########

# install Composer
if [[ ${composer,,} == "y" ]]
  then
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
fi

# install WP-CLI
if [[ ${wpCli,,} == "y" ]]
  then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    sudo chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
fi

# install NVM
if [[ ${node,,} == "y" ]]
  then
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.35.1/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # setup Node.js and global npm modules
    nvm install 10.15.3
    npm i -g gulp-cli yarn
fi

# ########
# Install basic software
# ########

# code editors/IDEs
if [[ ${sublime,,} == "y" ]]
  then
    sudo snap install sublime-text --classic
fi

if [[ ${vscode,,} == "y" ]]
  then
    sudo snap install code --classic
fi

if [[ ${phpstorm,,} == "y" ]]
  then
    sudo snap install phpstorm --classic
fi

# Skype
sudo snap install skype --classic

# Clipboard manager
sudo apt-get install -y copyq

# Screenshot tool
sudo apt-get install -y flameshot

# Chrome
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y google-chrome-stable

# git client GitEye
wget -O giteye.zip https://www.collab.net/sites/default/files/downloads/GitEye-2.2.0-linux.x86_64.zip
sudo unzip -o giteye.zip -d /opt/giteye
rm -f giteye.zip
sudo ln -sf /opt/giteye/GitEye /usr/bin/GitEye

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
Name[en_US]=GitEye" | sudo tee /usr/share/applications/giteye.desktop

# keybindings
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot ['']

echo '"flameshot gui"
Mod2 + Print' >> "$HOME/.xbindkeysrc"

echo '"copyq menu"
Control+Mod2 + grave' >> "$HOME/.xbindkeysrc"

# autostart
mkdir "$HOME/.config/autostart"

echo "[Desktop Entry]
Name=flameshot
Icon=flameshot
Exec=flameshot
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > "$HOME/.config/autostart/flameshot.desktop"

echo "[Desktop Entry]
Name=CopyQ
Icon=copyq
Exec=copyq
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > "$HOME/.config/autostart/copyq.desktop"

echo "[Desktop Entry]
Name=skype
Icon=skype
Exec=skype
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > "$HOME/.config/autostart/skype.desktop"

# setup GIT
git config --global user.name "${namevar}"
git config --global user.email "${emailvar}"

echo "Setup completed at $(date +"%Y-%m-%d %T")" > "$HOME/.ubuntu-setup"

echo "Some of the settings (key bindings) will not work until you reboot."
echo "Do you want to reboot right now? (yes/no)"
read rebootvar

if [[ ${rebootvar,,} == "yes" ]]
  then
    sudo reboot
fi
