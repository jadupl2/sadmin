#! /bin/bash
#===============================================================================
# Title      :  sam_gfs.sh - sam GFlobal Filesystem Tools
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  2007-12-18
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam_gfs.sh 1.0 18-Dec-2007
#
#===============================================================================
#
# Description 
#   This script is used to create/enlarge/delete GFS filesystems
#
#===============================================================================
# History    :
#   1.0      Initial Version - Jan 2005 - Jacques Duplessis
#
#===============================================================================
trap 'exec $SAM/sam' 2   		# INTERCEPTE LE ^C
#
BATCH_MODE=0 		; export BATCH_MODE     # Batch mode OFF while interactive

# Load GFS unction
. $SAM/sam_gfs_functions.sh

#===============================================================================
# Set Creation screen Default Value
#===============================================================================
set_creation_default()
{
CR_VG=`grep -v rootvg $VGLIST | sort | head -1`    ; export CR_VG
if [ -z "$CR_VG" ] ; then CR_VG="rootvg" ; fi

CR_LV=""                ; export CR_LV
CR_MP=""                ; export CR_MP
CR_MB="128"             ; export CR_MB
CR_FT="E"               ; export CR_FT
CR_NS="0"               ; export CR_NS
CR_SS="0"               ; export CR_SS
CR_CN=$CNAME            ; export CR_CN
let CR_JL=$CNBNODE+1    ; export CR_JL
CR_CM="N"               ; export CR_CM
CR_PR="2775"            ; export CR_PR
CR_GR="root"            ; export CR_GR
CR_OW="root"            ; export CR_OW
CR_REAL_SIZE=0          ; export CR_REAL_SIZE
}



#===============================================================================
# Create filesystem
#===============================================================================
create_filesystem()
{
   set_creation_default
   
   while : 
     do 
     display_entete "Create GFS Filesystem"
     writexy 04 05  "01- Cluster Name ............................ $CR_CN "
     writexy 05 05  "02- Nb. of Nodes that will mount filesystem.. $CR_JL "
     writexy 06 05  "03- Cluster will mount the GFS (Y/N)......... $CR_CM "
     writexy 08 05  "04- Volume group name ....................... $CR_VG "
     writexy 09 05  "05- Logical volume name...................... $CR_LV "
     writexy 10 05  "06- Logical volume USABLE space required(MB). $CR_MB "
     writexy 11 05  "07- Filesystem mount point................... $CR_MP "
     writexy 12 05  "08- Owner of filesystem (chown).............. $CR_OW "
     writexy 13 05  "09- Group assigned to filesystem (chgrp)..... $CR_GR "
     writexy 14 05  "10- Filesystem Protection (chmod - 4 Char.).. $CR_PR "
     writexy 17 07  "${bold}P${nrm}- Proceed with creation ...................."
     writexy 18 07  "${bold}Q${nrm}- Quit this menu............................"
     writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
     writexy 21 38 " "
     read option
     case $option in
    
          # CLUSTER NAME
          1 ) mess "Cluster Name cannnot be changed !"
              ;;

          # NUMBER OF GFS JOURNAL 
          2 ) accept_data 05 51 2 N $CR_JL
              if [ "$WDATA" -gt "$CNBNODE" ] 
                 then messok 22 01 "You asked for $WDATA Journals and you have only $CNBNODE in the Cluster "
                      if [ "$?" = "1" ] 
                        then CR_JL=$WDATA
                        else CR_JL=$CNBNODE
                      fi
                 else CR_JL=$WDATA
              fi
              ;;

          # MOUNT BY THE CLUSTER SOFTWARE ?
          3 ) accept_data 06 51 1 A $CR_CM
              case $WDATA in
                   Y|y ) CR_CM="Y" 
                         ;;
                   N|n ) CR_CM="N" 
                         ;;
                   *   ) mess "Y=Do not mount upon reboot, N=Mount upon reboot"
                         ;;
              esac
	          ;;

          # VOLUME GROUP NAME
          4 ) accept_data 08 51 10 A $CR_VG
              if vgexist $WDATA
                 then CR_VG=$WDATA
                 else mess "Volume Group $WDATA does not exist"
              fi
              ;;

          # ACCEPT LOGIVAL VOLUME NAME
          5 ) accept_data 09 51 14 A $CR_LV
              if lvexist $WDATA
                 then mess "The LV name ${WDATA} already exist"
                 else if [ "$WDATA" = "" ]
                         then mess "No Valid LV name is specify"
                         else CR_LV=$WDATA
                      fi
              fi
              ;;
 
          # LOGICAL VOLUME SIZE
          6 ) accept_data 10 51 08 A $CR_MB 
              let WMIN=($CR_JL*128)+64
              if [ "$WDATA" -lt $WMIN ]
                 then mess "Filesystem Size must be at least $WMIN MB" 
                 else CR_MB=$WDATA
              fi
              ;;

          # FILESYSTEM MOUNT POINT
          7 ) accept_data 11 51 30 A $CR_MP
              if mntexist $WDATA  
                 then mess "Mount Point $WDATA already exist"
                 else if ! mntvalid $WDATA 
                         then mess "First Character must be a \"/\""
                         else CR_MP=$WDATA
                      fi  
              fi
	          ;;

          # OWNER OF FILESYSTEM
          8 ) accept_data 12 51 20 A $CR_OW
              grep "^${WDATA}:" /etc/passwd >/dev/null 2>&1 
              if [ $? -ne 0 ] 
                 then mess "The user $WDATA is not defined in /etc/passwd"
                 else CR_OW=$WDATA
              fi
   	          ;;

          # GROUP OF FILESYSTEM
          9 ) accept_data 13 51 20 A $CR_GR
              grep "^${WDATA}" /etc/group >/dev/null 2>&1 
              if [ $? -ne 0 ] 
                 then mess "The group $WDATA is not defined in /etc/group"
                 else CR_GR=$WDATA
              fi
   	          ;;

          # FILESYSTEM PRIVILEGE
          10) accept_data 14 51 4 N $CR_PR
              CR_PR=$WDATA
              C1=`echo "$WDATA" | cut -c1-1`
              C2=`echo "$WDATA" | cut -c2-2`
              C3=`echo "$WDATA" | cut -c3-3`
              C4=`echo "$WDATA" | cut -c4-4`
     	      ;;


        p|P ) LVNAME=$CR_LV
              VGNAME=$CR_VG
              LVSIZE=$CR_MB
              LVTYPE=$CR_FT
              LVMOUNT=$CR_MP
              LVOWNER=$CR_OW
              LVGROUP=$CR_GR
              LVPROT=$CR_PR
              if ! data_creation_valid
                 then mess "GFS Filesystem Data is wrong - Please correct data"
                      RC=1
                 else let CR_REAL_SIZE=($CR_JL*128)+$CR_MB+256
                      messok 22 01 "Do you want to create $CR_MP (${CR_REAL_SIZE}MB) GFS filesystem" 
                      if [ "$?" = "1" ] 
                         then display_entete "Creating the GFS filesystem"
                              create_gfs
                              RC=$?
                              if [ "$RC" -ne 0 ] 
                                 then mess "Error ($RC) occured while creating the GFS filesystem"
                                 else echo "Filesystem created with success - Press [ENTER]" 
                                      read dummy
		                              set_creation_default
                              fi
    
                      fi
              fi
	          ;;

        q|Q ) break 
              ;;
     esac
     done  
}



                                                                                                                             
#===============================================================================
# Run fsck on the selected filesystem
#===============================================================================
filesystem_check()
{
                                                                                                                             
     RM_MP="" ; export RM_MP
     RM_ST="" ; export RM_ST
     RM_FLAG=0
     while :
        do
        display_entete "GFS Filesystem Integrity Check"
        if [ $RM_FLAG -eq 1 ]
           then writexy 07 08 "Logical Volume Name .....................: $LVNAME"
                writexy 08 08 "Volume Group ............................: $VGNAME"
                writexy 09 08 "Filesystem Type .........................: $LVTYPE"
                writexy 10 08 "Filesystem Size in MB ...................: $LVSIZE"
                writexy 11 08 "Filesystem Owner ........................: $LVOWNER"
                writexy 12 08 "Filesystem Group ........................: $LVGROUP"
                writexy 13 08 "Filesystem Protection ...................: $LVPROT"
        fi
        writexy 05 05  "1- GFS Mount Point to check................. $RM_MP "
        writexy 16 05  "P- Proceed with the filesystem check........"
        writexy 17 05  "Q- Quit this menu..........................."
        writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        writexy 21 38 " "
        read option
        case $option in
            1 ) accept_data 05 50 30 A $RM_MP
                if ! mntexist $WDATA
                   then mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                        RM_FLAG=1
                fi
                ;;
                                                                                                                             
              p|P ) messok 22 01 "Do you want to run a gfs_fsck on $RM_MP filesystem"
                    if [ "$?" = "1" ]
                       then display_entete "Filesystem Integrity Check"
                            RM_FLAG=0
                            gfs_fsck
                            RC=$?
                            if [ "$RC" -ne 0 ]
                               then mess "Error ($RC) occured while checking the GFS filesystem"
                               else mess "Filesystem check ran with success !"
                                    RM_MP="" ; export RM_MP
                                    RM_ST="" ; export RM_ST
                               fi
                            fi
                    ;;
                                                                                                                             
              q|Q ) break
                    ;;
           esac
        done
}
                                                                                                                             


                                                                                                                             
#===============================================================================
#            Display GFS Information                                        
#===============================================================================
display_gfs_info()
{
                                                                                                                             
     RM_MP="" ; export RM_MP
     while :
        do
        display_entete "Display GFS Information"               
        writexy 05 05  "1- GFS Mount Point ......................... $RM_MP "
        writexy 16 05  "P- Proceed with the request ................"
        writexy 17 05  "Q- Quit this menu..........................."
        writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        writexy 21 38 " "
        read option
        case $option in
            1 ) accept_data 05 50 30 A $RM_MP
                if ! mntexist $WDATA
                   then mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                fi
                ;;
                                                                                                                             
              p|P ) messok 22 01 "Do you want to display the GFS Information"
                    if [ "$?" = "1" ]
                       then tput clear 
                            gfs_tool df $RM_MP | grep -v "^$"
                            mess ""
                    fi 
                    ;;
                                                                                                                             
              q|Q ) break
                    ;;
           esac
        done
}
                                                                                                                             





#===============================================================================
# Delete filesystem Menu
#===============================================================================
delete_filesystem()
{

     RM_MP="" ; export RM_MP
     RM_ST="" ; export RM_ST
     RM_FLAG=0
     while :
	    do
        display_entete "Delete a GFS Filesystem"
        if [ $RM_FLAG -eq 1 ] 
           then writexy 07 08 "Logical Volume Name ...........: $LVNAME"
                writexy 08 08 "Volume Group ..................: $VGNAME"
                writexy 09 08 "Filesystem Type ...............: $LVTYPE"
                writexy 10 08 "Filesystem Size in MB .........: $LVSIZE"
                writexy 11 08 "Filesystem Owner ..............: $LVOWNER"
                writexy 12 08 "Filesystem Group ..............: $LVGROUP"
                writexy 13 08 "Filesystem Protection .........: $LVPROT"
        fi
        writexy 05 05  "1- Mount Point to delete.......... $RM_MP "
        writexy 16 05  "P- Proceed with the delete........"
        writexy 17 05  "Q- Quit this menu................."
        writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        writexy 21 38 " "
        read option
        case $option in
            1 ) accept_data 05 40 35 A $RM_MP
                if ! mntexist $WDATA  
                   then mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                        RM_FLAG=1
                fi  
                ;;
              
              p|P ) if [ -z "$RM_MP" ] 
                       then mess "No mount point specified ?"
                       else messok 22 01 "Do you want to delete $RM_MP GFS filesystem"
                            if [ "$?" = "1" ]
                               then display_entete "Delete the filesystem"
                                    RM_FLAG=0
                                    remove_gfs 
                                    RC=$?
                                    if [ "$RC" -ne 0 ]
                                       then mess "Error ($RC) occured while deleting the filesystem"
                                       else mess "Filesystem deleted with success !"
        	                                RM_MP="" ; export RM_MP
                                            RM_ST="" ; export RM_ST
                                    fi
                            fi
                    fi
                    ;;

              q|Q ) break
                    ;;
           esac
        done
}



#===============================================================================
# Add GFS Journal
#===============================================================================
add_gfs_journal()
{

     RM_MP="" ; export RM_MP
     RM_ST="" ; export RM_ST
     NBJNL=0  ; export NBJNL
     RM_FLAG=0
     while :
	    do
        display_entete "ADD GFS to filesystem"
        if [ $RM_FLAG -eq 1 ] 
           then writexy 07 08 "Logical Volume Name ...........: $LVNAME"
                writexy 08 08 "Volume Group ..................: $VGNAME"
                writexy 09 08 "Filesystem Type ...............: $LVTYPE"
                writexy 10 08 "Filesystem Size in MB .........: $LVSIZE"
                writexy 11 08 "Actual number of GFS journal...: $LVJNL"
        fi
        writexy 05 05  "1- Add journal to Mount Point.....: $RM_MP "
        writexy 14 05  "2- Number of GFS journal to add...: $NBJNL "
        writexy 16 05  "P- Proceed with adding journal...."
        writexy 17 05  "Q- Quit this menu................."
        writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        writexy 21 38 " "
        read option
        case $option in

            1 ) accept_data 05 40 35 A $RM_MP
                if ! mntexist $WDATA  
                   then mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                        RM_FLAG=1
                fi  
                ;;

            2 ) accept_data 14 40 35 A $NBJNL
                if [ $WDATA -lt 1 ] || [ $WDATA -gt 2 ]
                   then mess "Journal must be greater than 0 and no more than 2 additionals journals"
                   else NBJNL=$WDATA
                fi
                ;;
              
              p|P ) if [ -z "$RM_MP" ] 
                       then mess "No mount point specified ?"
                       else messok 22 01 "Want to add $NBJNL journal(s) to $RM_MP GFS filesystem"
                            if [ "$?" = "1" ]
                               then display_entete "Add journal to GFS filesystem"
                                    RM_FLAG=0
                                    if [ $NBJNL -lt 1 ] 
                                       then  mess "Number of journal must be greater than 0" 
                                       else add_journal
                                            RC=$?
                                            if [ "$RC" -ne 0 ]
                                               then mess "Error ($RC) occured while adding journal to filesystem"
                                               else mess "GFS journal was added with success !"
        	                                        RM_MP="" ; export RM_MP
                                                    RM_ST="" ; export RM_ST
                                                    NBJNL=0  ; export NBJNL
                                            fi
                                    fi
                            fi
                    fi
                    ;;

              q|Q ) break
                    ;;
           esac
        done
}





#===============================================================================
# Enlarge filesystem Menu
#===============================================================================
enlarge_filesystem()
{
     RM_MP="" ; export RM_MP
     RM_MB="" ; export RM_MB
     RM_FLAG=0
     while :
        do
        display_entete "GFS Filesystem size increase"
        if [ $RM_FLAG -eq 1 ]
           then writexy 07 08 "Logical Volume Name .....................: $LVNAME"
                writexy 08 08 "Volume Group ............................: $VGNAME ($VGFREE MB Free)"
                writexy 09 08 "Filesystem Type .........................: $LVTYPE"
                writexy 10 08 "Filesystem Size in MB ...................: ${bold}${LVSIZE}${nrm}"
                writexy 11 08 "Filesystem Owner ........................: $LVOWNER"
                writexy 12 08 "Filesystem Group ........................: $LVGROUP"
                writexy 13 08 "Filesystem Protection ...................: $LVPROT"
        fi
        writexy 05 05  "1- GFS Filesystem mount point to increase...: $RM_MP "
        writexy 15 05  "2- New Filesystem Size in MB................: ${bold}${RM_MB}${nrm}"
        writexy 17 05  "P- Proceed with increasing the size........."
        writexy 18 05  "Q- Quit this menu..........................."
        writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        writexy 21 38 " "
        read option
        case $option in

                 # ===== Accept Filesystem Mount point to increase
             1 ) accept_data 05 51 30 A $RM_MP
                 if ! mntexist $WDATA
                    then mess "Filesystem $WDATA does not exist"
                    else RM_MP=$WDATA
                         LVMOUNT=$RM_MP
                         get_mntdata $LVMOUNT
                         RM_FLAG=1
                         let "RM_MB=$LVSIZE+1"
                         getvg_info
                 fi
                 ;;

                 # Accept new filsystem size
             2 ) accept_data 15 51 06 N $RM_MB
                 if [ $WDATA -le $LVSIZE ] 
                    then mess "Size must be greater than ($LVSIZE) the actual size"
                    else RM_MB=$WDATA
                 fi
                 ;;

                 # ===== Proceed with Creation
           p|P ) let "wincr=$RM_MB - $LVSIZE"
                 messok 22 01 "Do you want to increase $RM_MP filesystem by $wincr MB"
                 if [ "$?" = "1" ]
                    then display_entete "Filesystem size increase"
                         LVSIZE=$wincr
			             mount $LVMOUNT > /dev/null 2>&1
                         RM_FLAG=0
                         extend_gfs
                         RC=$?
                         if [ "$RC" -ne 0 ]
                            then mess "Error ($RC) occured while increasing the filesystem"
                            else mess "Filesystem increased with success !"
                                 RM_MP="" ; export RM_MP
                                 RM_MB="" ; export RM_MB
                         fi
                 fi
                 ;;

                 #  ===== Quit this menu
           q|Q ) break
                 ;;
        esac
        done
}





#===============================================================================
# Display GFS Filesystem Menu
#===============================================================================
display_gfs_menu()
{
	display_entete "GFS Filesystem - Maintenance"
	writexy 05 20 "1- Create a GFS filesystem..............."
	writexy 07 20 "2- Increase GFS filesystem size ........."
	writexy 09 20 "3- Remove a GFS filesystem..............."
	writexy 11 20 "4- GFS Filesystem Integrity check (fsck)."
	writexy 13 20 "5- Display GFS Information..............."
	writexy 15 20 "6- Add Journal to a GFS Filesystem......."
	writexy 17 20 "Q- Quit this menu...................."
	writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
	writexy 21 38 " "
	return 
}



# ------------------------------------------------------------------------------
# Verify SSH between this node and the other and check cluster status
# ------------------------------------------------------------------------------
validate_cluster()
{
    RC=0

# Test ssh between nodes - IMPORTANT FOR GFS SCRIPT TO WORK !!
	display_entete "Validating SSH between nodes"
	echo "Validating SSH between nodes" 
    for wnode in `cat $CNODEFILE`
        do 
        cmd="date" 
        echo -n "ssh $wnode $cmd"
        ssh $wnode $cmd > /dev/null 2>&1
        if [ $? -ne 0 ]
           then echo " ERROR" 
                RC=1
                break
           else echo " OK"
        fi   
        done
    if [ $RC -ne 0 ] 
	   then mess "SSH between all nodes are note working - please correct that !!"
	   		return 1
	fi

# Check CLuster Status	
    cmd="$CLUSTAT"
    echo "  " 
	echo -n "Verifying cluster status by executing $CLUSTAT" 
    $CLUSTAT > /dev/null 2>&1
    if [ $? -ne 0 ]
       then echo " ERROR" 
            RC=1
       else echo " OK"
    fi   
    if [ "$RC" -ne 0 ] 
	   then mess "The cluster status is in error please correct the situation"
			return 1
	fi
    return 0
}





#===============================================================================
#       P R O G R A M    S T A R T    H E R E
#===============================================================================
    validate_cluster
    if [ $? -ne 0 ] ; then exit ; fi

    while :
      do
      display_gfs_menu
      read REPONSE
      case $REPONSE in
	    1) create_filesystem
           ;;
	    2) enlarge_filesystem
           ;;
	    3) delete_filesystem
	       ;;
	    4) filesystem_check
           ;;
	    5) display_gfs_info
           ;;
	    6) add_gfs_journal
           ;;
   Q | q ) break
	       ;;
        *) mess "Invalid option - $REPONSE"
           ;;
      esac
   done
