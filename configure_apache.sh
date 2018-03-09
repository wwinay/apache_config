#!/bin/bash
#
# Sccipt to configure the apache httpd on Centos 7
#

clear
u_id=$(id -u)

## Section to check if the logged in user is root
## Will exit the script if not a root user

if [ $u_id -ne 0 ]; then
	echo "Not root user, please switch to root and then run the script...exiting........"
	exit 1
fi

## check wether the httpd/mod_ssl is already installed
## if not it will install the package
## Also, it will exit the script if not able to install the package via yum 

for package in httpd mod_ssl
do
	yum list installed $package &> /dev/null
	if [ $? -ne 0 ]; then
		echo "########################################"
		echo "$package is not installed on machine, proceeding with installation......"
		echo "########################################"
		sleep 3
		yum install $package -y
		if [ $? -ne 0 ]; then
			echo "####################################################################"
			echo "Unable to install the package, please check yum configuration..."
			echo "####################################################################"
			exit 1
		fi
			
	else
		echo "########################################"
		echo "httpd and mod_ssl already installed, moving formward."
		echo "########################################"
	fi
done

## To create Document root
## And put the htpl code

if [ -d /apps/hello-http/html ]; then
	echo "########################################"
	echo "Document root is already exists"
	echo "########################################"
else
	echo "########################################"
	echo "Document root doesn't found creating..."
	echo "########################################"
	mkdir -p /apps/hello-http/html
	echo "<!DOCTYPE html PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
    <HEAD>
        <TITLE>Hello Williams-Sonoma!</TITLE>
    </HEAD>
    <BODY>
        <H1>Hello Williams-Sonoma!</H1>
    </BODY>
</HTML>" > /apps/hello-http/html/index.html
fi

## Create http log files

if [ -d /var/log/weblogs/http ]; then
	echo "########################################"
	echo "Log directory already exists"
	echo "########################################"
else
	echo "########################################"
	echo "Log directory not found...creating..."
	echo "########################################"
	mkdir -p /var/log/weblogs/http
fi

## httpd configuration to run the apache on port 80 and 443

echo "<VirtualHost *:80>
	DocumentRoot /apps/hello-http/html 
	ServerName $HOSTNAME
	CustomLog /var/log/weblogs/http/access_log combined
	ErrorLog /var/log/weblogs/http/error_log
	LogLevel warn

	<Directory /apps/hello-http/html>
		AllowOverride FileInfo Options
		Order allow,deny
		Allow from all
	</Directory>

	RewriteEngine On
	RewriteCond %{HTTPS} off
	RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
</VirtualHost>

<VirtualHost _default_:443>
	DocumentRoot /apps/hello-http/html 
	ServerName $HOSTNAME
	SSLEngine on


	SSLProtocol ALL -SSLv3 -SSLv2 -TLSv1
	SSLCertificateFile /etc/pki/tls/certs/localhost.crt
	SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
	CustomLog /var/log/weblogs/http/ssl_request_log \"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x "'\'"\"%r"'\'"\" %b\"
	ErrorLog /var/log/weblogs/http/ssl_error_log

	<Directory /apps/hello-http/html>
                AllowOverride FileInfo Options
                Order allow,deny
                Allow from all
		Require all granted
        </Directory>

		  
</VirtualHost>
" > /etc/httpd/conf.d/wsi_eng_inf.conf

httpd -t

## Start httpd service and display the output using curl
## Also check wether it have HTTP status code 200

systemctl start httpd.service
if [ $? -eq 0 ]; then
	echo "########################################"
	echo "httpd started succesfully."
	echo "########################################"
	systemctl enable httpd.service
	sleep 1
	echo -e "HTTP status code - \n"
	curl -I https://LNPNPRIFTST063V -k -s | head -1
	echo "########################################"
	echo "Fetching the page"
	echo "########################################"
	sleep 2
	curl -k https://LNPNPRIFTST063V
	echo "########################################"
	
else
	echo "########################################"
	echo "Unable to start httpd."
	echo "########################################"
fi


