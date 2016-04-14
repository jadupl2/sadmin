#!/usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#  Author:    Jacques Duplessis
#  Title      sadm_lib_server.sh
#  Date:      August 2015
#  Synopsis:  SADMIN Standard Shell Script Library specific to get server information 
# --------------------------------------------------------------------------------------------------
#set -x






# --------------------------------------------------------------------------------------------------
#                    Return The IP of the current Hostname
# --------------------------------------------------------------------------------------------------
sadm_server_ips() {
    
    index=0 ; sadm_server_ips=""                                        # Init Variables at Start
    case "$(sadm_get_ostype)" in
        "LINUX") rm -f $SADM_TMP_DIR/sadm_ips_$$ > /dev/null 2>&1       # Del TMP file - Make sure
                 ip addr |grep 'inet ' |grep -v '127.0.0' |awk '{ printf "%s %s\n",$2,$NF }'>$SADM_TMP_DIR/sadm_ips_$$
                 while read sadm_wip                                    # Read IP one per line
                   do
                    if [ "$index" -ne 0 ]                               # Don't add ; for 1st IP
                        then sadm_servers_ips="${sadm_servers_ips},"    # For others IP add ";"
                    fi
                    SADM_IP=`echo $sadm_wip | awk -F/ '{ print $1 }'`   # Get IP Address 
                    SADM_MASK_NUM=`echo $sadm_wip |awk -F/ '{ print $2 }' |awk '{ print $1 }'` # Get NetMask No
                    SADM_IF=`echo $sadm_wip | awk '{ print $2 }'`       # Get Interface Name
                    case "$SADM_MASK_NUM" in
                        1)      SADM_MASK="128.0.0.0"
                                ;;
                        2)      SADM_MASK="192.0.0.0" 
                                ;;
                        3)      SADM_MASK="224.0.0.0" 
                                ;;
                        4)      SADM_MASK="240.0.0.0" 
                                ;;
                        5)      SADM_MASK="248.0.0.0" 
                                ;;
                        6)      SADM_MASK="252.0.0.0" 
                                ;;
                        7)      SADM_MASK="254.0.0.0" 
                                ;;
                        8)      SADM_MASK="255.0.0.0" 
                                ;;
                        9)      SADM_MASK="255.128.0.0" 
                                ;;
                        10)     SADM_MASK="255.192.0.0" 
                                ;;
                        11)     SADM_MASK="255.224.0.0" 
                                ;;
                        12)     SADM_MASK="255.240.0.0" 
                                ;;
                        13)     SADM_MASK="255.248.0.0" 
                                ;;
                        14)     SADM_MASK="255.252.0.0" 
                                ;;
                        15)     SADM_MASK="255.254.0.0" 
                                ;;
                        16)     SADM_MASK="255.255.0.0" 
                                ;;
                        17)     SADM_MASK="255.255.128.0" 
                                ;;
                        18)     SADM_MASK="255.255.192.0" 
                                ;;
                        19)     SADM_MASK="255.255.224.0" 
                                ;;
                        20)     SADM_MASK="255.255.240.0" 
                                ;;
                        21)     SADM_MASK="255.255.248.0" 
                                ;;
                        22)     SADM_MASK="255.255.252.0" 
                                ;;
                        23)     SADM_MASK="255.255.254.0" 
                                ;;
                        24)     SADM_MASK="255.255.255.0" 
                                ;;
                        25)     SADM_MASK="255.255.255.128" 
                                ;;
                        26)     SADM_MASK="255.255.255.192" 
                                ;;
                        27)     SADM_MASK="255.255.255.224" 
                                ;;
                        28)     SADM_MASK="255.255.255.240" 
                                ;;
                        29)     SADM_MASK="255.255.255.248" 
                                ;;
                        30)     SADM_MASK="255.255.255.252" 
                                ;;
                        31)     SADM_MASK="255.255.255.254" 
                                ;;
                        32)     SADM_MASK="255.255.255.255"
                                ;;
                    esac
                    SADM_MAC=`ip addr show ${SADM_IF} | grep 'link' |head -1 | awk '{ print $2 }'` 
                    sadm_servers_ips="${sadm_servers_ips}${SADM_IF}|${SADM_IP}|${SADM_MASK}|${SADM_MAC}" 
                    index=`expr $index + 1`                             # Increment Index by 1
                   done < $SADM_TMP_DIR/sadm_ips_$$                     # Read IP From Generated File
                 rm -f $SADM_TMP_DIR/sadm_ips_$$ > /dev/null 2>&1       # Remove TMP IP File Output
                 ;;
        "AIX")   rm -f $SADM_TMP_DIR/sadm_ips_$$ > /dev/null 2>&1       # Del TMP file - Make sure
                 ifconfig -a | grep 'flags' | grep -v 'lo0:' | awk -F: '{ print $1 }' >$SADM_TMP_DIR/sadm_ips_$$
                 while read sadm_wip                                    # Read IP one per line
                   do
                    if [ "$index" -ne 0 ]                               # Don't add ; for 1st IP
                        then sadm_servers_ips="${sadm_servers_ips},"    # For others IP add ";"
                    fi
                    SADM_IP=`ifconfig $sadm_wip       | grep inet | awk '{ print $2 }'` # Get IP Address 
                    SADM_MASK=`lsattr -El $sadm_wip | grep -i netmask | awk '{ print $2 }'` # Get NetMask No
                    SADM_IF="$sadm_wip"               # Get Interface Name
                    SADM_MAC=`entstat -d $sadm_wip | grep 'Hardware Address:' | awk  '{  print $3 }'` # Get Interface Name
                    sadm_servers_ips="${sadm_servers_ips}${SADM_IF}|${SADM_IP}|${SADM_MASK}|${SADM_MAC}" 
                    index=`expr $index + 1`                             # Increment Index by 1
                   done < $SADM_TMP_DIR/sadm_ips_$$                     # Read IP From Generated File
                 ;;
    esac                 
    echo "$sadm_servers_ips"
}


# --------------------------------------------------------------------------------------------------
#                    Return a "P" if server is physical and "V" if it is Viirtual
# --------------------------------------------------------------------------------------------------
sadm_server_type() {
    case "$(sadm_get_ostype)" in
        "LINUX") $SADM_DMIDECODE | grep -i vmware >/dev/null 2>&1       # Search vmware in dmidecode
                 if [ $? -eq 0 ]                                        # If vmware was found
                    then sadm_server_type="V"                           # If VMware Server
                    else sadm_server_type="P"                           # Default Assume Physical
                 fi
                 ;;
        "AIX")   sadm_server_type="P"                                   # Default Assume Physical
                 ;;
    esac
    echo "$sadm_server_type"
}




# --------------------------------------------------------------------------------------------------
#                               RETURN THE MODEL OF THE SERVER
# --------------------------------------------------------------------------------------------------
sadm_server_model() {
    case "$(sadm_get_ostype)" in
        "LINUX") sadm_sm=`${SADM_DMIDECODE} |grep -i "Product Name:" |head -1 |awk -F: '{print $2}'`
                 sadm_sm=`echo ${sadm_sm}| sed 's/ProLiant//'`
                 sadm_sm=`echo ${sadm_sm}|sed -e 's/^[ \t]*//' |sed 's/^[ \t]*//;s/[ \t]*$//' `
                 sadm_server_model="${sadm_sm}"
                 if [ "$(sadm_server_type)" = "V" ]
                     then sadm_server_model="VM"
                     else grep -i '^revision' /proc/cpuinfo > /dev/null 2>&1
                          if [ $? -eq 0 ]
                            then wrev=`grep -i '^revision' /proc/cpuinfo |cut -d ':' -f 2)` 
                                 wrev=`echo $wrev | sed -e 's/^[ \t]*//'` #Del Lead Space
                                 sadm_server_model="Raspberry Rev.${wrev}"
                          fi
                 fi
                 ;;
        "AIX")   sadm_server_model=`uname -M | sed 's/IBM,//'`
                 ;;
    esac
    echo "$sadm_server_model"
}




# --------------------------------------------------------------------------------------------------
#                             RETURN THE SERVER SERIAL NUMBER
# --------------------------------------------------------------------------------------------------
sadm_server_serial() {
    case "$(sadm_get_ostype)" in
      "LINUX") if [ "$(sadm_server_type)" = "V" ]                       # If Virtual Machine
                  then wserial=" "                                      # VM as no serial 
                  else wserial=`${SADM_DMIDECODE} |grep "Serial Number" |head -1 |awk '{ print $3 }'`
                       if [ -r /proc/cpuinfo ]                          # Serial in cpuinfo (raspi)
                          then grep -i serial /proc/cpuinfo > /dev/null 2>&1
                               if [ $? -eq 0 ]                          # If Serial found in cpuinfo
                                  then wserial="$(grep -i Serial /proc/cpuinfo |cut -d ':' -f 2)"
                                       wserial=`echo $wserial | sed -e 's/^[ \t]*//'` #Del Lead Space
                               fi
                       fi
               fi 
               ;;
      "AIX")   wserial=`uname -u | awk -F, '{ print $2 }'`
               ;;
    esac
    echo "$wserial"
}




# --------------------------------------------------------------------------------------------------
#                     RETURN THE SERVER AMOUNT OF PHYSICAL MEMORY IN MB
# --------------------------------------------------------------------------------------------------
sadm_server_memory() {
    case "$(sadm_get_ostype)" in
        "LINUX") sadm_server_memory=`grep -i "memtotal:" /proc/meminfo | awk '{ print $2 }'`
                 sadm_server_memory=`echo "$sadm_server_memory / 1024" | bc`
                 ;;
        "AIX")   sadm_server_memory=`bootinfo -r`
                 sadm_server_memory=`echo "${sadm_server_memory} /1024" | $SADM_BC` 
                 ;;
    esac
    echo "$sadm_server_memory"
}




# --------------------------------------------------------------------------------------------------
#                             RETURN THE SERVER NUMBER OF CPU
# --------------------------------------------------------------------------------------------------
sadm_server_nb_cpu() { 
    case "$(sadm_get_ostype)" in
        "LINUX")    wnbcpu=`cat /proc/cpuinfo | grep -i '^processor' | wc -l | tr -d ' '`
                    if [ "$SADM_LSCPU" != "" ]
                        then wnbcpu=`$SADM_LSCPU | grep -i '^cpu(s):' | cut -d ':' -f 2 | tr -d ' '`
                    fi
                    ;;
        "AIX")      wnbcpu=`lsdev -C -c processor | wc -l | tr -d ' '`
                    ;;
    esac
    echo "$wnbcpu"
}




# --------------------------------------------------------------------------------------------------
#                             RETURN THE SERVER NUMBER OF CPU SOCKET
# --------------------------------------------------------------------------------------------------
sadm_server_nb_socket() { 
    case "$(sadm_get_ostype)" in
       "LINUX") wns=`cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l`
                if [ "$SADM_LSCPU" != "" ]
                    then wns=`$SADM_LSCPU | grep -i '^Socket(s)' | cut -d ':' -f 2 | tr -d ' '`
                fi
                ;;
        "AIX")  wns=`lscfg -vpl sysplanar0 | grep WAY | wc -l | tr -d ' '`
                ;;
    esac
    if [ "$wns" -eq 0 ] ; then wns=1 ; fi
    echo "$wns"
}


# --------------------------------------------------------------------------------------------------
#                         Return the Server Number of Core per Socket
# --------------------------------------------------------------------------------------------------
sadm_server_core_per_socket() {
    case "$(sadm_get_ostype)" in
       "LINUX") wcps=`cat /proc/cpuinfo |egrep "core id|physical id" |tr -d "\n" |sed s/physical/\\nphysical/g |grep -v ^$ |sort |uniq |wc -l`
                if [ "$wcps" -eq 0 ] ;then wcps=1 ; fi
                if [ "$SADM_LSCPU" != "" ]
                    then wcps=`$SADM_LSCPU | grep -i '^core(s) per socket' | cut -d ':' -f 2 | tr -d ' '`
                 fi
                ;;
        "AIX")  wcps=1
                ;;
    esac
    echo "$wcps"
}




# --------------------------------------------------------------------------------------------------
#                       RETURN THE SERVER NUMBER OF THREAD(S) PER CORE
# --------------------------------------------------------------------------------------------------
sadm_server_thread_per_core() { 
    case "$(sadm_get_ostype)" in
        "LINUX") sadm_wht=`cat /proc/cpuinfo |grep -E "cpu cores|siblings|physical id" |xargs -n 11 echo |sort |uniq |head -1`
                 sadm_sibbling=`echo $sadm_wht | awk -F: '{ print $3 }' | awk '{ print $1 }'`
                 if [ -z "$sadm_sibbling" ] ; then sadm_sibbling=0 ; fi
                 sadm_cores=`echo $sadm_wht | awk -F: '{ print $4 }' | tr -d ' '`
                 if [ -z "$sadm_cores" ] ; then sadm_cores=0 ; fi
                 if [ "$sadm_sibbling" -gt 0 ] && [ "$sadm_cores" -gt 0 ]
                    then sadm_server_thread_per_core=`echo "$sadm_sibbling / $sadm_cores" | bc`
                    else sadm_server_thread_per_core=1
                 fi
                 if [ "$SADM_LSCPU" != "" ]
                    then wnbcpu=`$SADM_LSCPU | grep -i '^thread' | cut -d ':' -f 2 | tr -d ' '`
                 fi
                 ;;
        "AIX")   sadm_server_thread_per_core=1
                 ;;
    esac
    echo "$sadm_server_thread_per_core"
}



 
# --------------------------------------------------------------------------------------------------
#                                   Return the CPU Speed in Mhz
# --------------------------------------------------------------------------------------------------
sadm_server_cpu_speed() { 
    case "$(sadm_get_ostype)" in
        "LINUX") 
                 if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]
                    then freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
                         sadm_server_cpu_speed=`echo "$freq / 1000" | $SADM_BC`
                    else sadm_server_cpu_speed=`cat /proc/cpuinfo | grep -i "cpu MHz" | tail -1 | awk -F: '{ print $2 }'`
                         sadm_server_cpu_speed=`echo "$sadm_server_cpu_speed / 1" | $SADM_BC`
                         #if [ "$sadm_server_cpu_speed" -gt 1000 ]
                         #   then sadm_server_cpu_speed=`expr $sadm_server_cpu_speed / 1000`
                         #fi
                 fi
                 ;;
        "AIX")   sadm_server_cpu_speed=`pmcycles -m | awk '{ print $5 }'`
                 ;;
    esac
    echo "$sadm_server_cpu_speed"
}

 
# --------------------------------------------------------------------------------------------------
#                     Return 32 or 64 Bits Depending of CPU Hardware Capability
# --------------------------------------------------------------------------------------------------
sadm_server_hardware_bitmode() { 
    case "$(sadm_get_ostype)" in
        "LINUX")   sadm_server_hardware_bitmode=`grep -o -w 'lm' /proc/cpuinfo | sort -u`
                   if [ "$sadm_server_hardware_bitmode" = "lm" ]
                       then sadm_server_hardware_bitmode=64
                       else sadm_server_hardware_bitmode=32
                   fi
                   ;;
        "AIX")     sadm_server_hardware_bitmode=`bootinfo -y`
                   ;;
    esac
    echo "$sadm_server_hardware_bitmode"
}

# --------------------------------------------------------------------------------------------------
#    FUNCTION RETURN A STRING CONTAINING DISKS NAMES AND CAPACITY (MB) OF EACH DISKS
#
#    Example :  sda:65536;sdb:17408;sdc:17408;sdd:104
#        EACH DISK NAME IS FOLLOWED BY THE DISK CAPACITY IN MB,  SEPERATED BY A ":"
#        IF THEY ARE MULTIPLE DISKS ON THE SERVER EACH DISK INFO IS SEPARATED BY A ";"
# --------------------------------------------------------------------------------------------------
sadm_server_disks() {
    index=0 ; sadm_server_disks=""                                                  # Init Variables
    case "$(sadm_get_ostype)" in
        "LINUX")    for wdisk in `find /sys/block -name "sd[a-z]" -exec basename {} \;` # Get Disk Name 
                        do
                        if [ "$index" -ne 0 ]                                       # Don't add , for 1st Disk
                            then sadm_server_disks="${sadm_server_disks},"          # For others disks add ","
                        fi
                        wsize=`$SADM_FDISK -l /dev/${wdisk} |grep -i "^Disk" |grep -i $wdisk |awk '{ print $3 }'`
                        wsize=`echo $wsize / 1 | $SADM_BC`                          # Get rid of Decimal

                        wunit=`$SADM_FDISK -l /dev/${wdisk} | grep -i "^Disk" | grep -i $wdisk | awk '{ print $4 }'`
                        if [ "$wunit" = "GB," ]                                     # If Disk Size in GB
                           then wsize=`echo "($wsize * 1024) / 1" | $SADM_BC`       # Convert GB into MB 
                           else wsize=`echo "$wsize * 1" | $SADM_BC`                # If MB Get Rid of Decimal
                        fi
                        sadm_server_disks="${sadm_server_disks}${wdisk}|${wsize}"   # Combine Disk Name & Size
                        index=`expr $index + 1`                                     # Increment Index by 1
                    done
                    ;;
        "AIX")      for wdisk in `find /dev -name "hdisk*"`
                        do
                        if [ "$index" -ne 0 ] ; then sadm_server_disks="${sadm_server_disks}," ; fi
                        sadm_disk_name=`basename $wdisk`
                        sadm_disk_size=`getconf DISK_SIZE ${wdisk}` 
                        sadm_server_disks="${sadm_server_disks}${sadm_disk_name}|${sadm_disk_size}"
                        index=`expr $index + 1`                                    
                    done
                    ;;
    esac
    echo "$sadm_server_disks"                                                      
}



# --------------------------------------------------------------------------------------------------
#       Return  String containing all VG names, VG capacity and VG Free Spaces in (MB)
# --------------------------------------------------------------------------------------------------
#    Example :  datavg:16373:10250:6123;datavg_sdb:16373:4444:11929;rootvg:57088:49859:7229
#               Each VG name is followed by the VGSize, VGUsed and VGFree space in MB
#               If they are multiple disks on the server each disk info is separated by a ";"
# --------------------------------------------------------------------------------------------------
sadm_server_vg() {
    index=0 ; sadm_server_vg=""                                         # Init Variables at Start
    rm -f $SADM_TMP_DIR/sadm_vg_$$ > /dev/null 2>&1                          # Del TMP file - Make sure
    case "$(sadm_get_ostype)" in
        "LINUX") ${SADM_WHICH} vgs >/dev/null 2>&1
                 if [ $? -eq 0 ]
                    then vgs --noheadings -o vg_name,vg_size,vg_free >$SADM_TMP_DIR/sadm_vg_$$ 2>/dev/null
                         while read sadm_wvg                                                 # Read VG one per line
                            do
                            if [ "$index" -ne 0 ]                                           # Don't add ; for 1st VG
                                then sadm_server_vg="${sadm_server_vg},"                    # For others VG add ";"
                            fi    
                            sadm_vg_name=`echo ${sadm_wvg} | awk '{ print $1 }'`            # Save VG Name
                            sadm_vg_size=`echo ${sadm_wvg} | awk '{ print $2 }'`            # Get VGSize from vgs output
                            if $(echo $sadm_vg_size | grep -i 'g' >/dev/null 2>&1)             # If Size Specified in GB
                                then sadm_vg_size=`echo $sadm_vg_size | sed 's/g//' |sed 's/G//'`        # Get rid of "g" in size
                                     sadm_vg_size=`echo "($sadm_vg_size * 1024) / 1" | $SADM_BC` # Convert in MB
                                else sadm_vg_size=`echo $sadm_vg_size | sed 's/m//'`        # Get rid of "m" in size
                                     sadm_vg_size=`echo "$sadm_vg_size / 1" | $SADM_BC`     # Get rid of decimal
                            fi
                            sadm_vg_free=`echo ${sadm_wvg} | awk '{ print $3 }'`            # Get VGFree from vgs ouput
                            if $(echo $sadm_vg_free | grep -i 'g' >/dev/null 2>&1)             # If Size Specified in GB
                                then sadm_vg_free=`echo $sadm_vg_free | sed 's/g//' |sed 's/G//'|sed 's/M//'`        # Get rid of "g" in size
                                     sadm_vg_free=`echo "($sadm_vg_free * 1024) / 1" | $SADM_BC`  # Convert in MB
                                else sadm_vg_free=`echo $sadm_vg_free | sed 's/m//' |sed 's/M//'`        # Get rid of "m" in size
                                     sadm_vg_free=`echo "$sadm_vg_free / 1" | $SADM_BC`     # Get rid of decimal
                            fi
                            sadm_vg_used=`expr ${sadm_vg_size} - ${sadm_vg_free}`           # Calculate VG Used MB 
                            sadm_server_vg="${sadm_server_vg}${sadm_vg_name}|${sadm_vg_size}|${sadm_vg_used}|${sadm_vg_free}"
                            index=`expr $index + 1`                                         # Increment Index by 1
                            done < $SADM_TMP_DIR/sadm_vg_$$                                          # Read VG From Generated File
                 fi
                 ;;
        "AIX")   lsvg > $SADM_TMP_DIR/sadm_vg_$$
                 while read sadm_wvg
                    do
                    if [ "$index" -ne 0 ] ; then sadm_server_vg="${sadm_server_vg}," ;fi
                    sadm_vg_name="$sadm_wvg"
                    sadm_vg_size=`lsvg $sadm_wvg |grep 'TOTAL PPs:' |awk -F: '{print $3}' |awk -F"(" '{print $2}'|awk '{print $1}'`
                    sadm_vg_free=`lsvg $sadm_wvg |grep 'FREE PPs:'  |awk -F: '{print $3}' |awk -F"(" '{print $2}'|awk '{print $1}'`
                    sadm_vg_used=`lsvg $sadm_wvg |grep 'USED PPs:'  |awk -F: '{print $3}' |awk -F"(" '{print $2}'|awk '{print $1}'`
                    sadm_server_vg="${sadm_server_vg}${sadm_vg_name}|${sadm_vg_size}|${sadm_vg_used}|${sadm_vg_free}"
                    index=`expr $index + 1`                                         # Increment Index by 1
                    done < $SADM_TMP_DIR/sadm_vg_$$ 
                ;;
    esac
    
    rm -f $SADM_TMP_DIR/sadm_vg_$$ > /dev/null 2>&1                          # Remove TMP VG File Output
    echo "$sadm_server_vg"                                              # Return VGInfo to caller
}
