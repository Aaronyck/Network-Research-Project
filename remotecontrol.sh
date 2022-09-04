#!/bin/bash




function installtool()
{
#if string is empty(Nipe is not install), then install Nipe, else ignore.
#install geoip-bin to use geoiplookup command in latter function.
	
	checknipe=$(find / -type d -name nipe 2>/dev/null)
	
	if [ -z $checknipe ]
then
	sudo apt-get update && sudo apt-get upgrade
	echo "Installing Geoip-bin..."
	sudo apt-get install geoip-bin
	git clone https://github.com/htrgouvea/nipe && cd nipe
	sudo cpan install Try::Tiny Config::Simple JSON
	sudo  cpan install Switch JSON LWP::UserAgent Config::Simple
	sudo perl nipe.pl install

else
	echo "Nipe is already downloaded."
	

fi	
}


function checkanonymous()
{
#check for anonymous
#Sometime nipe might not works properly, so we need to include commands to check for nipe status to make sure it is activated.
	
	checknipe=$(find / -type d -name nipe 2>/dev/null)
	cd $checknipe
	check=$(sudo perl nipe.pl status | grep -w activated)
	ipadd=$(curl -s ifconfig.io)
	country=$(geoiplookup $ipadd | awk '{print $5}')
	
	if [ ! -z "$check" ]
	then
		echo "You are anonymous"
		echo "Current IP address is $ipadd which is from $country"
	else
		echo "You are exposed"
		echo "Current IP address is $ipadd which is from $country"
		echo "Starting Nipe now..."
		cd nipe
		sudo perl nipe.pl start
		tornotfound
	fi
	
}

function tornotfound()
{
#error message if tor is not found, to install tor else ignore.
	
	troubleshoot=$(echo $(sudo perl nipe.pl start) > troubleshoot.txt)
	notfound=$(cat troubleshoot.txt | grep -o "tor: not found")
	
	if [ "$notfound" == "tor: not found" ]
	then
	sudo apt-get install tor
	fi
	
}

function checknipestatus()
{
#in case there are errors for nipe, to stop and start again
	
	checknipe=$(find / -type d -name nipe 2>/dev/null)
	location=$(echo "$checknipe")
	failgrep=$(sudo perl nipe.pl status)
	echo "$failgrep" > fail.txt
	grepecho=$(cat "$location"/fail.txt | grep -o "ERROR")

	check=$(sudo perl nipe.pl status | grep -w activated)
	
	if [ "$grepecho" == "ERROR" ]
	then
		cd "$location"
		sudo perl nipe.pl stop
		sudo perl nipe.pl start
		checknipestatus
	else
		echo "Double check status..."
		checkanonymous
	fi
}

function vps()
{
#Run a portion of a shell script on another server (using <<ENDSSH and ENDSSH), reference to link below.
#https://www.howtogeek.com/devops/how-to-run-a-local-shell-script-on-a-remote-ssh-server/
#In nutshell, script will conduct nmap scan and whois (check for domain name for specific IP Address) at remote server via ssh (IP Address and Username provided by user). 
#By default, nmap will scan http://scanme.nmap.org/ (45.33.32.156) this website. You may change to your desired target's IP Address.
	echo "Please provide Username and IP Address for ssh into the remote server."
	read -p "Username: " user
	read -p "IP Address: " ipssh
	
	ssh "$user"@"$ipssh"  'bash -s' <<'ENDSSH'
	nmap 45.33.32.156 -oN nmap_whoisresult.txt
	ipdetail=$(whois 45.33.32.156)
	echo "$ipdetail" >> nmap_whoisresult.txt
	exit
ENDSSH
	echo " "
	scp $user@$ipssh:/home/$user/nmap_whoisresult.txt .
	
}


installtool      		#run installation for Nipe and Geoiplookup
checkanonymous			#check anonymous
checknipestatus			#check for error (if any) in running Nipe and make sure it is working properly
vps						#ssh into vps and execute nmap and whois an ip address





