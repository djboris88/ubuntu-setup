#!/bin/bash

# prevent running if log file already exists, no need for running this twice
if [ -f /home/$(users)/ubuntu-setup.log ]
	then
		echo "Setup already run. Please check the log at '/home/$(users)/ubuntu-setup.log'."
		exit 0
fi

# ########
# Get user inputs
# ########
read -p 'Your name: ' namevar
read -p 'Your Email address: ' emailvar


# ########
# Add repositories
# ########
echo "Adding apt repositories and installing general requirements..."
add-apt-repository -y ppa:ondrej/php &> ~/ubuntu-setup.log
add-apt-repository -y ppa:phpmyadmin/ppa &>> ~/ubuntu-setup.log
apt update &>> ~/ubuntu-setup.log
apt upgrade -y &>> ~/ubuntu-setup.log

# install general requirements
apt install -y software-properties-common gdebi curl git libfreetype6-dev libjpeg-dev libmagickwand-dev libpng-dev libzip-dev &>> ~/ubuntu-setup.log


# ########
# Setup Apache, PHP, MySQL
# ########

echo "Installing Apache, PHP and MySQL..."

# install apache2
apt install -y apache2 &>> ~/ubuntu-setup.log

systemctl start apache2 &>> ~/ubuntu-setup.log
systemctl enable apache2 &>> ~/ubuntu-setup.log

# setup permissions for /var/www
gpasswd -a "$(users)" www-data &>> ~/ubuntu-setup.log
chown -R www-data:www-data /var/www &>> ~/ubuntu-setup.log
setfacl -Rdm g:www-data:rwx /var/www &>> ~/ubuntu-setup.log
setfacl -Rdm u:www-data:rwx /var/www &>> ~/ubuntu-setup.log
setfacl -Rdm "u:$(users):rwx" /var/www &>> ~/ubuntu-setup.log

# set root for 'localhost' to /var/www
sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/g" /etc/apache2/sites-available/000-default.conf &>> ~/ubuntu-setup.log

# setup vhost script
echo "Setting up a script for automatic creation of virtual hosts..."
echo "To use it, type 'vhost create' in your terminal and follow the instructions."
echo "To remove existing virtual host, type 'vhost delete' and type in the vhost address."
wget https://raw.githubusercontent.com/djboris88/ubuntu-setup/master/virtualhost.sh &>> ~/ubuntu-setup.log
mv virtualhost.sh /usr/bin/vhost &>> ~/ubuntu-setup.log
chmod +x /usr/bin/vhost &>> ~/ubuntu-setup.log

# install php 7.3
apt install -y php7.3-fpm php7.3-common php7.3-zip php7.3-curl php7.3-xml php7.3-xmlrpc php7.3-json php7.3-mysql php7.3-pdo php7.3-gd php7.3-imagick php7.3-ldap php7.3-imap php7.3-mbstring php7.3-intl php7.3-cli php7.3-recode php7.3-tidy php7.3-bcmath php7.3-opcache php7.3-xdebug &>> ~/ubuntu-setup.log

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

for i in "${!confs[@]}"
do
	search=$i
	replace=${confs[$i]}

	sed -i -E "s/.?(${search}).+/\1 = ${replace}/g" /etc/php/7.3/fpm/php.ini  &>> ~/ubuntu-setup.log
done

# configure opcache
echo "opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1" >> /etc/php/7.3/mods-available/opcache.ini

# configure xdebug
echo "xdebug.remote_autostart = 1
xdebug.remote_enable = 1
xdebug.remote_handler = dbgp
xdebug.remote_host = 127.0.0.1
xdebug.remote_log = /tmp/xdebug_remote.log
xdebug.remote_mode = req
xdebug.remote_port = 9000" >> /etc/php/7.3/mods-available/xdebug.ini

# setup mysql and phpmyadmin
apt install -y mysql-server &>> ~/ubuntu-setup.log
apt install -y phpmyadmin &>> ~/ubuntu-setup.log

# enable no password for phpmyadmin
sed -i "s/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27AllowNoPassword\x27\] = TRUE;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27AllowNoPassword\x27\] = TRUE;/g" /etc/phpmyadmin/config.inc.php &>> ~/ubuntu-setup.log

# enable everything and restart apache
a2enmod proxy_fcgi setenvif &>> ~/ubuntu-setup.log
a2enconf php7.3-fpm &>> ~/ubuntu-setup.log

systemctl restart apache2 &>> ~/ubuntu-setup.log
systemctl restart php7.3-fpm &>> ~/ubuntu-setup.log


# ########
# Setup DevTools
# ########

# install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php &>> ~/ubuntu-setup.log
mv composer.phar /usr/local/bin/composer &>> ~/ubuntu-setup.log

# install NVM
echo "Installing NVM, Node.js, npm and gulp..."
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.35.1/install.sh | bash &>> ~/ubuntu-setup.log

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# setup Node.js and global npm modules
nvm install 10.15.3 &>> ~/ubuntu-setup.log
npm i -g gulp-cli yarn &>> ~/ubuntu-setup.log

# setup GIT
sudo -u $(users) git config --global user.name "${namevar}" &>> ~/ubuntu-setup.log
sudo -u $(users) git config --global user.email "${emailvar}" &>> ~/ubuntu-setup.log


# ########
# Install basic software
# ########

# code editors/IDEs
echo "Installing Sublime Text, VSCode and PHPStorm..."
snap install sublime-text --classic &>> ~/ubuntu-setup.log
snap install code --classic &>> ~/ubuntu-setup.log
snap install phpstorm --classic &>> ~/ubuntu-setup.log

# Skype
echo "Installing Skype..."
snap install skype --classic &>> ~/ubuntu-setup.log

# autostart
echo "[Desktop Entry]
Name=skype
Icon=skype
Exec=skype
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > ~/.config/autostart/skype.desktop

# Clipboard manager
echo "Installing CopyQ, a nice clipboard manager..."
echo "Shortcut for using it is 'Ctrl + \`'"
apt install -y copyq default-jre xbindkeys &>> ~/ubuntu-setup.log

# autostart
echo "[Desktop Entry]
Name=CopyQ
Icon=copyq
Exec=copyq
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > ~/.config/autostart/copyq.desktop

# add keybinding
sudo -u $(users) echo '"copyq menu"
Control+Mod2 + grave' >> ~/.xbindkeysrc

# Screenshot tool
echo "Installing Flameshot, nice screenshot app..."
apt install -y flameshot  &>> ~/ubuntu-setup.log

# autostart
echo "[Desktop Entry]
Name=flameshot
Icon=flameshot
Exec=flameshot
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true" > ~/.config/autostart/Flameshot.desktop

# remove system keybinding and add custom
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot [''] &>> ~/ubuntu-setup.log
sudo -u $(users) echo '"flameshot gui"
Mod2 + Print' >> ~/.xbindkeysrc

# Chrome
echo "Installing Google Chrome..."
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >  /etc/apt/sources.list.d/google-chrome.list
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - &>> ~/ubuntu-setup.log
apt update &>> ~/ubuntu-setup.log
apt install -y google-chrome-stable &>> ~/ubuntu-setup.log

# git client GitEye
echo "Installing GitEye, git client with gui..."
wget -O giteye.zip https://www.collab.net/sites/default/files/downloads/GitEye-2.2.0-linux.x86_64.zip &>> ~/ubuntu-setup.log
unzip -o giteye.zip -d /opt/giteye &>> ~/ubuntu-setup.log
rm -f giteye.zip &>> ~/ubuntu-setup.log
ln -sf /opt/giteye/GitEye /usr/bin/GitEye &>> ~/ubuntu-setup.log
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

# reboot
echo "Rebooting in 3..."
sleep 3 && reboot