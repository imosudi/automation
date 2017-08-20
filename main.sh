#!/bin/bash

function deploy {

#Creating or recreating deployment directories
rm -rf roles  > /dev/null 2>&1 && mkdir roles 
mkdir roles/create-ec2-instance 
mkdir roles/create-ec2-instance/handlers && mkdir roles/create-ec2-instance/tasks 
rm -rf webserver  > /dev/null 2>&1 && mkdir webserver  
rm -rf dbserver  > /dev/null 2>&1 && mkdir dbserver 
rm -rf backup_scripts  > /dev/null 2>&1 && mkdir backup_scripts 
rm -rf vars  > /dev/null 2>&1 && mkdir vars 

#Creating/recreating deployment files and scripts
touch /vars/ec2_secrets.yml

cat <<'EOF' >  create_icinga2db.sh
#!/bin/bash

password=mysqlrootpassword

mysqladmin -u root password $password

EOF

chmod +x  create_icinga2db.sh

cp  create_icinga2db.sh  roles/mysqlserver-icinga2-client/create_icinga2db.sh

cat <<'EOF' > roles/webserver-icinga2-client/WebDockerfile 

#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#
## MOSUDI Using Ubuntu 14.04 aws ec2 instance 
## MOSUDI cd /home/ubuntu/
## MOSUDI git clone github.com/dockerfile/ubuntu
## MOSUDI mv /home/ubuntu/ubuntu/dockerfile  /home/ubuntu/ubuntu/dockerfile_backup
## MOSUDI mv /home/ubuntu/WebDockerfile  /home/ubuntu/ubuntu/dockerfile
## MOSUDI docker build -t="dockerfile/ubuntu" /home/ubuntu/ubuntu/
## MOSUDI docker run -itd --rm dockerfile/ubuntu

# Pull base image.
FROM ubuntu:14.04

#ARG DEBIAN_FRONTEND=noninteractive

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
		build-essential \
		byobu \
		curl \
		git \
		htop \
		man \
		python-software-properties \
		software-properties-common \ 
		unzip \
		vim \
		wget \

  && wget -O - https://packages.icinga.com/icinga.key | apt-key add -  
RUN echo "deb http://packages.icinga.com/ubuntu icinga-trusty main " >> /etc/apt/sources.list
RUN echo "deb-src http://packages.icinga.com/ubuntu icinga-trusty main " >> /etc/apt/sources.list  && \
 apt-get update && apt-get install -y \
		apache2 \
		bash-completion \
		icinga2 \
                nagios-plugins  \
		openssh-server \
		php5 \
		php5-intl \
		php5-mcrypt php5-imagick  \
		python \
		tzdata \
#RUN sed -i 's/;date.timezone =/date.timezone = Africa\/Lagos/g' /etc/php5/apache2/php.ini && \
  && icinga2 daemon -C && \
  service apache2 start -C && \
 
# END OF ADDED LINES
  rm -rf /var/lib/apt/lists/*

# Add files.
ADD root/.bashrc /root/.bashrc
ADD root/.gitconfig /root/.gitconfig
ADD root/.scripts /root/.scripts

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]


EOF

cat <<'EOF' > roles/webserver-icinga2-client/web_lab_server.sh
#!/bin/bash

docker run -itd --rm dockerfile/ubuntu > web_lab

web_lab="$(cat web_lab )" 
docker commit  $web_lab mosudi/webserver  > /dev/null 2>&1 
docker run -h webserver.mosudi -p 800:80 -p 223:22 -itd mosudi/webserver /bin/bash >web_lab_container
web_lab_container="$(cat web_lab_container )"
docker inspect $web_lab_container  | grep Hostname | grep -v null| cut -d '"' -f 4 | tail -1 >web_lab_container_hostname 
web_lab_container_hostname="$(cat web_lab_container_hostname)"
docker inspect $web_lab_container  | grep IPAddress | grep -v null| cut -d '"' -f 4 | head -1 >web_lab_container_ip
web_lab_container_ip="$( cat web_lab_container_ip)"
echo "$(cat web_lab_container_ip)    $(cat web_lab_container_hostname) " >> /etc/hosts
docker exec -it $web_lab_container bash -c "echo '$web_lab_container_ip    $web_lab_container_hostname '  >> /etc/hosts"
docker inspect $web_lab_container | grep Gateway | grep -v null| cut -d '"' -f 4 | head -1 >lab_gateway_ip
lab_gateway_ip="$(cat lab_gateway_ip)"
lab_gateway_public_hostname=
lab_gateway_public_ip=
lab_gateway_hostname="$(hostname -f)"
docker exec -it $web_lab_container bash -c "echo '$lab_gateway_ip    $lab_gateway_hostname '  >> /etc/hosts"

docker exec -it $web_lab_container bash -c "echo '$lab_gateway_public_ip    $lab_gateway_public_hostname '  >> /etc/hosts"

docker exec -it $web_lab_container bash -c "sed -i 's/;date.timezone =/date.timezone = Africa\/Lagos/g' /etc/php5/apache2/php.ini "

docker exec -it $web_lab_container bash -c "sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config "

docker exec -it $web_lab_container bash -c " echo -e 'password\npassword' | passwd  root  "

docker exec -it $web_lab_container bash -c 'mv /etc/icinga2/conf.d/services.conf /etc/icinga2/conf.d/services.conf_backup'
docker exec -it $web_lab_container bash -c 'mv /etc/icinga2/conf.d/hosts.conf /etc/icinga2/conf.d/hosts.conf_backup'
services="$(cat webservices.conf)"
hosts="$(cat webhosts.conf)"
docker exec -it $web_lab_container bash -c "echo '$services' >/etc/icinga2/conf.d/services.conf"
docker exec -it $web_lab_container bash -c "echo '$hosts' >/etc/icinga2/conf.d/hosts.conf"
#46a67e40ff6f
docker exec -it $web_lab_container bash -c "service ssh start  "
docker exec -it $web_lab_container bash -c "service apache2 start  "


docker exec -it $web_lab_container bash -c "icinga2 object list --type Host "
docker exec -it $web_lab_container bash -c "icinga2 object list --type Service "
docker exec -it $web_lab_container bash -c "icinga2 daemon -C "


#getting the host docker ip address
#ip addr show |grep 172.17.| grep -v null | awk '{print $2}'|cut -d '/' -f 1


EOF

chmod +x roles/webserver-icinga2-client/web_lab_server.sh


#Git ADD
git add vars/ > /dev/null 2>&1
git add roles/ > /dev/null 2>&1
git add webserver/  > /dev/null 2>&1
git add dbserver/  > /dev/null 2>&1
git add backup_scripts/  > /dev/null 2>&1




}
##End of my function - deploy

while true; do
    read -p "Please confirm you are ready to provide your AWS AccessKeyId and SecretKey to Continue with the Program?  " yn #AWSAccessKeyId, AWSSecretKey
    case $yn in
#        [Yy]* ) make install; break;;

 [Yy]* ) echo -n "Please provide your AWSAccessKeyId > "
read AWSAccessKeyId
echo -n "Please provide your AWSSecretKey > "
read AWSSecretKey
echo "Your AWSAccessKeyId: $AWSAccessKeyId and AWSSecretKey: $AWSSecretKey"; 
deploy;
break;;
       
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


