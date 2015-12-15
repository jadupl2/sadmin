#! /bin/sh
tput clear
while :
      do
          echo -e "find /var/lib/puppet/ssl -name HOSTNAME.pem -delete"
          echo -e "--------------------------"
          echo -e "Enter the fully qualified server name \c : "
          read server
          echo -ne "I am trying to ping the server $server"
          ping -c2 $server > /dev/null 2>&1
          if [ $? -ne 0 ]
             then echo "The server $server doesn't respond to ping ..."
                  echo "Please enter a valid server name"
             else break
          fi
          done

echo "\n\n Issuing : find /var/lib/puppet/ssl -name ${server}.pem -delete"
find /var/lib/puppet/ssl -name ${server}.pem -delete
