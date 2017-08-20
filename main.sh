#!/bin/bash

function deploy {

#Creating or recreating deployment directories
rm -rf webserver  > /dev/null 2>&1 && mkdir webserver  && rm -rf dbserver  > /dev/null 2>&1 && mkdir dbserver && rm -rf backup_scripts  > /dev/null 2>&1 && mkdir backup_scripts && rm -rf vars  > /dev/null 2>&1 && mkdir vars 

#Creating/recreating deployment files and scripts
touch /vars/ec2_secrets.yml


#Git ADD
git add vars/ > /dev/null 2>&1
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


