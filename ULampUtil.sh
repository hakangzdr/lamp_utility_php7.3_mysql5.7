#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "You need to execute with sudo"
    exit
fi

WWWFOLDER="/var/www"
RED="\033[0;31m";
LIGHTRED="\033[1;31m";
YELLOW="\033[1;33m";
CYAN="\033[0;36m";
NC="\033[0m";
NUMBER='^[0-9]+$'
ISLETTER="0"
SHOWMENU="1"

while :
do

	if [ $SHOWMENU = "1" ]; then

	if [ -d "$WWWFOLDER" ] 
	then
	   echo "$WWWFOLDER exists" 
	else
	  echo -e "${LIGHTRED}$WWWFOLDER NOT existing${NC}"
	fi

	echo "User name : $SUDO_USER"
	
	echo
		
	
	echo -e "${CYAN}Apache with PHP 7.3, MySQL 5.7"
	echo "=============================="
	echo "0) List all installed packages"
	echo
	echo "APACHE"
	echo "-----------------------"
	echo "1) Get version"
	echo "2) Install"
	echo "3) Server status"
	echo "4) Create virtual host in /var/www/html folder"
	echo "5) Disable default site"
	echo "6) Disable and delete selected site"
	echo "7) View host's conf file"
	echo "8) Restart Apache server"
	echo "9) Stop Apache server"
	echo "10) Start Apache server"
	echo "11) Set www-data as folder owner and group owner"
	echo -e "12) ${LIGHTRED}Uninstall and delete www folder${CYAN}"
	echo
	echo "PHP"
	echo "-----------------------"
	echo "21) Get version"
	echo "22) Install PHP 7.3"
	echo "23) List extensions"
	echo -e "24) ${LIGHTRED}Uninstall${CYAN}"
	echo
	echo "MySQL"
	echo "-----------------------"
	echo "31) Get version"
	echo "32) Add repository"
	echo "33) Add GPG key"
	echo "34) Install Mysql 5.7"
	echo "35) Server status"
	echo -e "36) ${LIGHTRED}Uninstall${CYAN}"
	echo
	echo "Firewall"
	echo "-----------------------"
	echo "41) View applications list"
	echo "42) View firewall status"
	echo "43) Enable firewall"
	echo "44) Disable firewall"
	echo "45) Allow Apache"
	echo "46) Open port"
	echo
	echo "c) Clear screen"
	echo "q) EXIT"

	fi

	SHOWMENU="0"

	echo
	echo -n "Enter choice and press ENTER [Press Enter for menu]: "


        # Read choice
        read choice

	echo -e "${NC}"
	
	ISLETTER="0"

	if [ $choice = "c" ] || [ $choice = "q" ] || [ $choice = "C" ] || [ $choice = "Q" ]; then
	 ISLETTER="1"
	fi

	if [ $ISLETTER = "0" ];
	then 
	 echo -e  "${YELLOW}==========================================================================${NC}"
        fi


        # Evaluate
        case $choice in

		0)	echo "--> Getting list of Apache packages"
			echo
			apt list --installed | grep apache
			echo
			echo "--> Getting list of PHP packages"
			sudo apt list --installed | grep php
			echo
			echo "--> Getting list of MySQL packages"
			sudo apt list --installed | grep mysql;;

                1)      echo "--> Getting Apache version..."
                        echo
                        apache2 -v;;

		2)	echo "--> Installing Apache2"
			echo
			sudo apt install apache2 -y
			echo
			echo "--> Enabling Expires and Rewrite modules"
			echo
			sudo a2enmod expires
			sudo a2enmod rewrite;;

		3)	sudo systemctl status apache2 --no-pager;;

		4)	echo -n "Enter folder name : "
			read folderName

			echo -n "Enter owner user of the folder [$SUDO_USER]: "
			read ownerUser

			ownerUser=${ownerUser:-$SUDO_USER}

			if [ -z "$folderName" ] || [ -z "$ownerUser" ]; then

				echo "Virtual host creation canceled"

			else

				echo -n "Enter host admin email : "
				read adminEmail

				echo -n "Enter server name : "
				read serverName

				echo -n "Enter server alias : "
				read serverAlias

				echo
				echo "--> Creating folder..."

				sudo mkdir -p /var/www/html/$folderName/{public_html,log,backups}

				if [ $? -ne 0 ]; then

					echo "${LIGHTRED}Error occured while creating directory${NC}"

				else

					echo "Directory created"
					sudo chown -R $SUDO_USER:www-data /var/www/html/$folderName
					sudo chmod -R 755 /var/www/html/$folderName
					echo "Folder permissions set"
					
					sudo dd of=/etc/apache2/sites-available/$folderName.conf << EOF
<VirtualHost _default_:80>
EOF

					
if ! [ -z "$adminEmail" ]; then
	
	printf "	ServerAdmin %s\n" $adminEmail >> /etc/apache2/sites-available/$folderName.conf

fi

if ! [ -z "$serverName" ]; then
	
	printf "	ServerName %s\n" $serverName >> /etc/apache2/sites-available/$folderName.conf

fi

if ! [ -z "$serverAlias" ]; then

	printf "	ServerAlias %s\n" $serverAlias >> /etc/apache2/sites-available/$folderName.conf

fi


					sudo cat << EOF >> /etc/apache2/sites-available/$folderName.conf

	DirectoryIndex index.php index.html
	DocumentRoot /var/www/html/$folderName/public_html

	<Directory "/var/www/html/$folderName/public_html">
  		Options -Indexes
  		AllowOverride All
  		Order allow,deny
  		Allow from all
	</Directory>

	LogLevel warn
	ErrorLog /var/www/html/$folderName/log/error.log
	CustomLog /var/www/html/$folderName/log/access.log combined
</VirtualHost>
EOF

					sudo a2ensite $folderName.conf

					echo "Virtual host file created"
					
					sudo systemctl restart apache2

				fi


				echo "Go on"

			fi;;

		5)	sudo a2dissite 000-default.conf
			sudo systemctl reload apache2;;

		6)	echo -n "Enter name of directory to delete : "
			read folderNameToDelete

			if [ -z "$folderNameToDelete" ]; then

				echo "Blank folder name is not acceptable. Aborted"

			else

				sudo a2dissite $folderNameToDelete.conf
				sudo rm /etc/apache2/sites-available/$folderNameToDelete.conf
				sudo rm -r /var/www/html/$folderNameToDelete
				sudo systemctl reload apache2

			fi;;

		7)	echo -n "Enter host folder name : "
			read hostFolderName

			if [ -z "$hostFolderName" ];
			then

				echo "Operation cancelled"

			else

				sudo nano /etc/apache2/sites-available/$hostFolderName.conf

			fi;;


		8)	sudo systemctl restart apache2;;

		9)	sudo systemctl stop apache2;;

		10)	sudo systemctl start apache2;;

		11)	echo -n "Enter host folder name : "
			read hostFolder

			echo -n "Enter subfolder name : "
			read subFolder

			if [ -z "$hostFolder" ] || [ -z "$subFolder" ]; then

				echo "Operation canceled"

			else

				sudo chown -R www-data:www-data /var/www/html/$hostFolder/public_html/$subFolder
				sudo chmod -R 755 /var/www/html/$hostFolder/public_html/$subFolder

			fi;;

		12)	echo -n "Are you sure you want to uninstall Apache ? [Y/n] : "
			read confirmUninstall

			if [ $confirmUninstall = "Y" ]; then

				echo "--> Uninstalling Apache"
				echo
				sudo service apache2 stop
				sudo apt-get purge --auto-remove -y apache2

			else

				echo "Apache uninstallation cancelled"

			fi;;

		21)	php -version;;

		22)	sudo add-apt-repository -y ppa:ondrej/php
			sudo add-apt-repository -y ppa:ondrej/apache2
			sudo apt update
			sudo apt install -y php7.3
			sudo apt install -y php7.3-mysql
			sudo apt install -y php7.3-mbstring
			sudo apt install -y php7.3-intl
			sudo apt install -y php7.3-simplexml;;

		23)	php -m;;


		24)	echo -n "Are you sure you want to uninstall PHP 7.3 ? [Y/n] : "
			read confirmPHPRemove

			if [ $confirmPHPRemove = "Y" ]; then

				sudo apt-get purge --auto-remove -y php7.3-simplexml
				sudo apt-get purge --auto-remove -y php7.3-xml
				sudo apt-get purge --auto-remove -y php7.3-intl
				sudo apt-get purge --auto-remove -y php7.3-mbstring
			  	sudo apt-get purge --auto-remove -y php7.3-mysql
			  	sudo apt-get purge --auto-remove -y php7.3

			else

			  	echo "PHP 7.3 uninstallation canceled"

			fi;;

		31)	mysql -V;;

		32)	wget https://dev.mysql.com/get/mysql-apt-config_0.8.12-1_all.deb
			sudo dpkg -i mysql-apt-config_0.8.12-1_all.deb
			sudo apt update
			apt-cache policy mysql-server;;

		33)	echo -n "Type GPG key or 0 to exit: "
			read gpgkeyresponse

			if ! [ $gpgkeyresponse = "0" ]; then
				sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $gpgkeyresponse
				sudo apt-get update
				apt-cache policy mysql-server
			fi;;

		34)	apt install -f -y mysql-client=5.7* mysql-server=5.7*;;

		35)	sudo systemctl status mysql;;

		36)	echo -n "Are you sure you want to uninstall MySQL 5.7 ? [Y/n] : "
			read confirmMysqlRemoval			


			if [ $confirmMysqlRemoval = "Y" ]; then

				sudo service mysql stop
				sudo killall -KILL mysql mysqld_safe mysqld
				sudo apt-get purge --auto-remove -y mysql-client
				sudo apt-get purge --auto-remove -y mysql-server
				sudo apt-get purge --auto-remove -y mysql-apt-config

			else

				echo "MySql uninstallation canceled"

			fi;;


		41) 	sudo ufw app list;;

		42)	sudo ufw status;;

		43)	sudo ufw enable;;

		44)	sudo ufw disable;;

		45)	sudo ufw allow "Apache Full";;

		46)	echo -n "Enter port number to allow : "
			read portNumber

			if [ -z "$portNumber" ]; then

				echo "Operation canceled"

			else

				sudo ufw allow $portNumber

			fi;;

		c) clear;;
		C) clear;;

                q) echo -e "${NC}"
			exit;;
		Q) echo -e "${NC}"
			exit;;

		*) SHOWMENU="1";;

        esac

	echo

	if [ $ISLETTER = "0" ];
	then
	echo -e "${YELLOW}====================  Command completed ===============================${NC}"
	fi

	echo

done
