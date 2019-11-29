#!/bin/bash

# run script as root if not called as root
if [ "$(whoami)" != 'root' ]
	then
		sudo $0 $1 $2
		exit 0
fi

# Set default parameters
action=$1
owner=$(users)
email='webmaster@localhost'
sitesEnabled='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
rootDir='/var/www/'
currentDir=$(pwd)
dirName=${currentDir##*/}

# check if action is not 'create' or 'delete'
if [[ "${action,,}" != 'create' ]] && [[ "${action,,}" != 'delete' ]]
	then
		echo "You need to type in the action: "
		echo "- '${0} create' or"
		echo "- '${0} delete'"
		exit 1;
fi

if [[ $2 != "" ]]
	then
		assumedDomain=$2
else
	assumedDomain=${dirName}.local
fi

# get the $domainName and $fullPath
read -e -p "Enter domain name: " -i "${assumedDomain,,}" domainName

if [ "${action,,}" == 'create' ]
	then
		read -e -p "Enter full path: " -i "${currentDir}" fullPath
fi

# if the action is delete, remove the vhost .conf file and the entry from /etc/hosts
if [ "${action,,}" == 'delete' ]
	then
		a2dissite ${domainName}
		rm -f /etc/apache2/sites-available/${domainName}.conf
		sed -i -E "s/127.0.0.1 ${domainName}//g" /etc/hosts
		systemctl reload apache2

		exit 0
fi

echo "<VirtualHost *:80>
        ServerAdmin ${owner}@localhost
        ServerName ${domainName}
        DocumentRoot ${fullPath}
        ErrorLog \${APACHE_LOG_DIR}/${domainName}-error.log
        CustomLog \${APACHE_LOG_DIR}/${domainName}-access.log combined

        <Directory ${fullPath}>
                Options +Includes +Indexes +FollowSymLinks +MultiViews
                AllowOverride All
                Require all granted
                DirectoryIndex index.php
        </Directory>
</VirtualHost>" > /etc/apache2/sites-available/${domainName}.conf

echo "127.0.0.1 ${domainName}" >> /etc/hosts
a2ensite ${domainName}
systemctl reload apache2