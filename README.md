# Ubuntu 19.10 Setup script

_A set of bash commands to streamline setup of a **clean Ubuntu 19.10 installation**
as a PHP development machine, including AMP stack, necessary PHP modules, Composer, NPM/Gulp, 
some of the most popular IDEs and text editors, and basic every-day apps: clipboard manager, 
screenshot tool, git client..._

## How to run

To start the setup, run this command in terminal:
```shell script
bash <(wget -qO- https://raw.githubusercontent.com/djboris88/ubuntu-setup/master/setup.sh)
```

Log will be stored in the `~/ubuntu-setup.log` file. You are only allowed to run the script once per 
machine, to avoid some duplicate commands being run.

## `vhost` command

Beside all other goodies, this setup script will create a custom script for creating Apache virtual hosts,
and store it in the `/user/bin/vhost` file.

#### Using `vhost`
To `create` new virtual host run
```shell script
vhost create
```
And then follow the on-screen instructions. The similar is for the `delete` command:
```shell script
vhost delete
```

By default, script will offer you the placeholders for the virtual host url and for the project
root path, based on the current directory you are calling this script from.

For example, if your terminal location is `/var/www/project`, it will offer you the `project.local` 
for virtual host url, and `/var/www/project` for the root path.

After entering or confirming those two parameters, script will create a new `.conf` file inside
`/etc/apache2/sites-available` directory and call `a2ensite ${vhostUrl}`. Also, new entry will be
made in the `/etc/hosts` file.

When calling `vhost delete` both of those will be removed. Apache is reloaded in both cases.

## Other Content

### Apache2, MySQL, PHPMyAdmin, PHP7.3-FPM
- set permissions for `/var/www` using `setfacl`, `rwx` for both `www-data` and the logged in user
- root directory for the default virtual host is set to `/var/www`
- installed and activated many PHP modules
- reconfigured `php.ini` with some basic settings for local development
- added some settings to `opcache.ini` and `xdebug.ini`
- changed settings for phpmyadmin to allow login without password

### Dev tools
- Composer
- WP-CLI
- NVM, Node.js, Gulp, Yarn
- Git, set up global `user.name` and `user.email`

### Software
- Sublime Text
- PHPStorm
- Visual Studio Code
- Skype (autostart)
- CopyQ (autostart) - clipboard manager, keyboard shortcut set to ``Ctrl + ` ``
- Flameshot (autostart) - screenshot tool, keyboard shortcut set to `Print`
- Google Chrome
- GitEye - git client

