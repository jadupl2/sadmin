#! /bin/bash
################################################################################
# Title      :  certificate_expire_date.sh
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  2006-03-21
# Requires   :  bash shell
# SCCS-Id.   :  @(#) certificate_expire_date.sh 1.6 21/03/2006
#
################################################################################
#
#set -x

# Certificate File Expiration
CFILE="/opt/ibm/edge/cp/server_root/ssl_keys/certificate_expire_date.txt"

# Epoch time - Now
ENOW=`/sysadmin/bin/epoch`      ; export ENOW

cat $CFILE | while read CLINE
    do
    #echo $CFILE  | grep -i "^#"  > /dev/null 2>&1
    echo $CLINE  | grep -i "^#"  > /dev/null 2>&1
    if [ $? -eq 0 ]
       then continue
            echo "Processing line"
       else CDATE=`echo $CLINE | awk -F: '{ print $1 }'`
            CDATE="${CDATE}090000"
            EDATE=`/sysadmin/bin/epoch ${CDATE}`
            CNAME=`echo $CLINE | awk -F: '{ print $2 }'`
            CMAIL=`echo $CLINE | awk -F: '{ print $3 }'`
            echo -e "\n\n-----------------------\nCertificate $CNAME will expire on $CDATE \nWill advise $CMAIL"
            WSEC=`echo "$ENOW - $EDATE" | bc`
            if [ $WSEC -gt 0 ]
               then echo "Certificate $CNAME is already expire - $CDATE"
                    echo "Certificate $CNAME is ALREADY expired - $CDATE !!!" | mail -s "ALERT: Certificate $CNAME Expired !!!" $CMAIL
               else WSEC=`echo "$WSEC * -1" | bc `
                    WDAYS=`echo "${WSEC} / 60 /60 /24" | bc `
                    echo "The certificate will expire in $WDAYS days. "
                    if [ $WDAYS -eq 21 ] || [ $WDAYS -eq 14 ] || [ $WDAYS -lt 11 ]
                        then echo "Certificate $CNAME will expire in $WDAYS days - $CDATE" | mail -s "Certificate $CNAME expiration warning" $CMAIL
                             echo "Reminder email sent to $CMAIL"
                    fi
            fi
    fi
    done
