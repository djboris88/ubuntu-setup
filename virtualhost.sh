#!/bin/bash

# Set default parameters
action=$1
owner=$(users)
email='webmaster@localhost'
sitesEnabled='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
rootDir='/var/www/'
currentDir=$(pwd)
dirName=${currentDir##*/}

if [ "${action,,}" != 'create' ] && [ "${action,,}" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete)"
		exit 1;
fi

if [[ $currentDir == *"${rootDir}"* ]]
	then
		read -e -p "Enter domain name: " -i "${dirName,,}.local" domainName
else
	while [ "${domain}" == "" ]
		do
			echo -e $"Please provide domain: e.g \"project.local\""
			read domain
	done
fi
