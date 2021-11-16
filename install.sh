#!/bin/bash

/usr/bin/reset

if [[ $EUID -ne 0 ]]; then
   /usr/bin/echo "This script must be run as root" 
   exit 1
fi

/usr/bin/echo "
██      ██  ██████  ██   ██ ████████  ██████  ██     ██ ██      
██      ██ ██       ██   ██    ██    ██    ██ ██     ██ ██      
██      ██ ██   ███ ███████    ██    ██    ██ ██  █  ██ ██      
██      ██ ██    ██ ██   ██    ██    ██    ██ ██ ███ ██ ██      
███████ ██  ██████  ██   ██    ██     ██████   ███ ███  ███████"
/usr/bin/echo ""
/usr/bin/echo ""

/usr/bin/apt update
/usr/bin/apt upgrade -y

/usr/bin/apt install -y curl # python3-pip python3-m2crypto
/usr/bin/curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
/usr/bin/chmod +x /usr/local/bin/docker-compose

if [ -x "$(command -v docker)" ]; then
   :
else
   /usr/bin/echo "Docker is not installed on system. Please Install it and re-run the install script"
   exit 1
fi

/usr/bin/echo ""
/usr/bin/echo -n "Admin Password: " 
read -s password
/usr/bin/echo ""
/usr/bin/echo -n "Confirm Password: "
read -s confirm_password
/usr/bin/echo ""

while [[ true ]]
do
   if [[ "$password" != "" ]]
   then
      if [[ "$password" == "$confirm_password" ]]
      then
         break
      fi
   fi

   /usr/bin/echo ""
   echo "Passwords mismatch or is empty"
   echo -n "Admin Password: " 
   read -s password
   /usr/bin/echo ""
   echo -n "Confirm Password: "
   read -s confirm_password
   echo ""
done

/usr/bin/echo ""
/usr/bin/echo -n "IP Address: "
read ip_address
while [[ true ]]
do
   if [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
   else
      /usr/bin/echo ""
      /usr/bin/echo "Invalid IP Address"
      /usr/bin/echo -n "IP Address: "
      read ip_address
   fi
done
/usr/bin/echo ""

/usr/sbin/addgroup lightowl
sha_password=$(/usr/bin/openssl passwd -1 ${password})
rabbit_password=$(/usr/bin/date +%s | /usr/bin/sha256sum | /usr/bin/base64 | /usr/bin/head -c 32 ; /usr/bin/echo)
lightowl_token=$(/usr/bin/date +%s | /usr/bin/sha256sum | /usr/bin/base64 | /usr/bin/head -c 32 ; /usr/bin/echo)

/usr/sbin/useradd -m -p $sha_password -s /bin/bash -g sudo lightowl
/usr/sbin/usermod -aG docker lightowl

/usr/bin/cp -r ./* /

# Creating PKI
cd /home/lightowl
/usr/bin/chown -R lightowl:lightowl ./

/usr/bin/docker build -t lightowl:install -f install.dockerfile .
/usr/bin/docker run -it --rm \
   -v /home/rabbitmq:/home/rabbitmq \
   -v /home/lightowl:/home/lightowl \
   -v /home/telegraf:/home/telegraf \
   -v /etc/ssl/lightowl:/etc/ssl/lightowl \
   --name lightowl_install \
   lightowl:install \
   bash /home/lightowl/bootstrap/bootstrap.sh $rabbit_password $ip_address

# Fix rights
/usr/bin/chown -R lightowl:lightowl /home/haproxy
/usr/bin/chown -R lightowl:lightowl /home/telegraf
/usr/bin/chown root:lightowl /etc/ssl/lightowl/*
/usr/bin/chmod 440 /etc/ssl/lightowl/*

/usr/local/bin/docker-compose -f ./docker-compose.yml up -d

until /usr/bin/curl -s -f -k -o /dev/null "https://127.0.0.1/docs"
do
    /usr/bin/echo "Waiting"
   /usr/bin/sleep 1;
done

## Configure LightOwl Superuser
/usr/bin/docker exec lightowl_lightowl_1 python3 /app/scripts/bootstrap.py $password $ip_address $lightowl_token

# Now we can install local agent
cd /tmp/
/usr/bin/wget https://lightowl.io/download/ubuntu-agent/?wpdmdl=1039&masterkey=619232cce3f21

/usr/bin/chmod +x ./lightowl-agent-ubuntu.run
./lightowl-agent-ubuntu.run $ip_address $lightowl_token

/usr/bin/echo ""
/usr/bin/echo "
██      ██  ██████  ██   ██ ████████  ██████  ██     ██ ██      
██      ██ ██       ██   ██    ██    ██    ██ ██     ██ ██      
██      ██ ██   ███ ███████    ██    ██    ██ ██  █  ██ ██      
██      ██ ██    ██ ██   ██    ██    ██    ██ ██ ███ ██ ██      
███████ ██  ██████  ██   ██    ██     ██████   ███ ███  ███████"
/usr/bin/echo ""
/usr/bin/echo "LightOwl is now installed. Go to https://${ip_address}"
