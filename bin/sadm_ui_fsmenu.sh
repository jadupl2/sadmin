#! /bin/bash
#===================================================================================================
# Title      :  sadm_menu_fs.sh - sadm - Menu for filesystems tools
# Version    :  1.5
# Author     :  Jacques Duplessis
# Date       :  2016-06-01
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam_menu_fs.sh 1.5 1-Jun-2016
#
#===================================================================================================
#
# Description
#   This script is used to create/enlarge/delete filesystems
#
#===================================================================================================
# History    :
#   1.0      Initial Version - Jun 2016 - Jacques Duplessis
#   1.3      Revised for ext4 -Jul 2016 - Jacques Duplessis
#   1.5      Revised for xfs -Jul 2016 - Jacques Duplessis
#   2.0      Revisited to work with SADM environment - Jan 2017 - Jacques Duplessis
#===================================================================================================

# Load Filesystem Library Tools
[ -f ${SADM_LIB_DIR}/sadm_lib_fs.sh ] && . ${SADM_LIB_DIR}/sadm_lib_fs.sh  

# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
BATCH_MODE=0                        ; export BATCH_MODE                 # Batch mode OFF interactive


#===================================================================================================
#                       Set FileSystem Creation Screen Default Value
#===================================================================================================
set_creation_default()
{
    CR_VG=`ls -1 $VGDIR | sort| head -1`    ; export CR_VG
    CR_LV=""       ; export CR_LV
    CR_MP=""       ; export CR_MP
    CR_MB="32"     ; export CR_MB
    CR_NS="0"      ; export CR_NS
    CR_SS="0"      ; export CR_SS
    if [ "$OSVERSION" -gt 5 ] ; then CR_FT="ext4" ; else CR_FT="ext3" ; fi
    if [ "$OSVERSION" -gt 6 ] ; then CR_FT="xfs"  ; else CR_FT="ext4" ; fi
    export CR_FT
}



#===================================================================================================
# Create filesystem
#===================================================================================================
create_filesystem()
{
   set_creation_default
   while : 
     do 
     sadm_display_heading  "Create Filesystem"
     sadm_writexy 06 05  "1- Volume group............................. $CR_VG "
     sadm_writexy 07 05  "2- Logical volume name...................... $CR_LV "
     sadm_writexy 08 05  "3- Logical volume size in MB................ $CR_MB "
     sadm_writexy 09 05  "4- Filesystem mount point................... $CR_MP "
     sadm_writexy 10 05  "5- Filesystem Type (ext3,ext4,xfs).......... $CR_FT "
     sadm_writexy 14 05  "${bold}P${nrm}- Proceed with creation ..................."
     sadm_writexy 15 05  "${bold}Q${nrm}- Quit this menu..........................."
     sadm_writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
     sadm_writexy 21 38 " "
     read option
     case $option in
    
          # Accept Volume Group
          1 ) accept_data 06 50 10 A $CR_VG
              if vgexist $WDATA
                 then CR_VG=$WDATA
                 else sadm_mess "Volume Group $WDATA does not exist"
              fi
              ;;

          # Accept Logical volume name
          2 ) accept_data 07 50 14 A $CR_LV
              if lvexist $WDATA  
                 then sadm_mess "The LV name ${WDATA} already exist"
                 else if [ "$WDATA" = "" ]
                         then sadm_mess "No Valid LV name is specify"
                         else  CR_LV=$WDATA
                      fi
              fi
	      ;;

          # Accept Logical Volume Size
          3 ) accept_data 08 50 07 A $CR_MB 
              if [ "$WDATA" -lt 32 ]
                 then sadm_mess "Filesystem Size must be at least 32 MB" 
                 else CR_MB=$WDATA
              fi
              ;;

          # Accept Filesystem Mount Point
          4 ) accept_data 09 50 30 A $CR_MP
              if mntexist $WDATA  
                 then sadm_mess "Mount Point $WDATA already exist"
                 else if ! mntvalid $WDATA 
                         then sadm_mess "First Character must be a \"/\""
                         else CR_MP=$WDATA
                      fi  
              fi
	      ;;


          # Accept Filesystem Type
          5 ) accept_data 10 50 30 A $CR_FT
              if [ "$WDATA" != "ext3" ] && [ "$WDATA" != "ext4" ]
                 then sadm_mess "Filesystem supported are ext3 and ext4." 
                 else if [ "$OSVERSION" -lt 6 ] && [ "$WDATA" = "ext4" ]
                         then sadm_mess "Filesystem ext4 only supported on RHEL 6 and higher"
                         else CR_FT=$WDATA
                      fi
              fi
	          ;;


        p|P ) messok 22 01 "Do you want to create $CR_MP filesystem" 
              if [ "$?" = "1" ] 
                 then sadm_display_heading  "Creating the filesystem"
                      LVNAME=$CR_LV
                      VGNAME=$CR_VG
                      LVSIZE=$CR_MB
                      LVTYPE=$CR_FT
                      LVMOUNT=$CR_MP
                      LVOWNER="root"
                      LVGROUP="root"
                      LVPROT="755"
                      if ! data_creation_valid
                         then sadm_mess "Filesystem Data is wrong - Please correct data"
                              RC=1
                         else create_fs
                              RC=$?
                      fi
                      if [ "$RC" -ne 0 ] 
                         then sadm_mess "Error ($RC) occured while creating the filesystem"
                         else sadm_mess "Filesystem created with success !" 
		              set_creation_default
                      fi
              fi
              ;;

        q|Q ) break 
              ;;
     esac
     done  
}



                                                                                                                             
#===================================================================================================
# Run fsck on the selected filesystem
#===================================================================================================
filesystem_check()
{
                                                                                                                             
     RM_MP="" ; export RM_MP
     RM_ST="" ; export RM_ST
     RM_FLAG=0
     while :
        do
        sadm_display_heading  "Filesystem Integrity Check"
        if [ $RM_FLAG -eq 1 ]
           then sadm_writexy 07 08 "Logical Volume Name .....................: $LVNAME"
                sadm_writexy 08 08 "Volume Group ............................: $VGNAME"
                sadm_writexy 09 08 "Filesystem Type .........................: $LVTYPE"
                sadm_writexy 10 08 "Filesystem Size in MB ...................: $LVSIZE"
                sadm_writexy 11 08 "Filesystem Owner ........................: $LVOWNER"
                sadm_writexy 12 08 "Filesystem Group ........................: $LVGROUP"
                sadm_writexy 13 08 "Filesystem Protection ...................: $LVPROT"
        fi
        sadm_writexy 05 05  "1- Mount Point to check..................... $RM_MP "
        sadm_writexy 16 05  "P- Proceed with the filesystem check........"
        sadm_writexy 17 05  "Q- Quit this menu..........................."
        sadm_writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        sadm_writexy 21 38 " "
        read option
        case $option in
            1 ) accept_data 05 50 30 A $RM_MP
                if ! mntexist $WDATA
                   then sadm_mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                        RM_FLAG=1
                fi
                ;;
                                                                                                                             
              p|P ) messok 22 01 "Do you want to run a fsck on $RM_MP filesystem"
                    if [ "$?" = "1" ]
                       then sadm_display_heading  "Filesystem Integrity Check"
                            RM_FLAG=0
                            filesystem_fsck
                            RC=$?
                            if [ "$RC" -ne 0 ]
                               then sadm_mess "Error ($RC) occured while checking the filesystem"
                               else sadm_mess "Filesystem check ran with success !"
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
                                                                                                                             





#===================================================================================================
# Delete filesystem Menu
#===================================================================================================
delete_filesystem()
{

     RM_MP="" ; export RM_MP
     RM_ST="" ; export RM_ST
     RM_FLAG=0
     while :
	do
        sadm_display_heading  "Delete a Filesystem"
        if [ $RM_FLAG -eq 1 ] 
           then sadm_writexy 07 08 "Logical Volume Name ..........: $LVNAME"
                sadm_writexy 08 08 "Volume Group .................: $VGNAME"
                sadm_writexy 09 08 "Filesystem Type ..............: $LVTYPE"
                sadm_writexy 10 08 "Filesystem Size in MB ........: $LVSIZE"
                sadm_writexy 11 08 "Filesystem Owner .............: $LVOWNER"
                sadm_writexy 12 08 "Filesystem Group .............: $LVGROUP"
                sadm_writexy 13 08 "Filesystem Protection ........: $LVPROT"
        fi
        sadm_writexy 05 05  "1- Mount Point to delete......... $RM_MP "
        sadm_writexy 16 05  "P- Proceed with the delete......."
        sadm_writexy 17 05  "Q- Quit this menu................"
        sadm_writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        sadm_writexy 21 38 " "
        read option
        case $option in
            1 ) accept_data 05 39 40 A $RM_MP
                if ! mntexist $WDATA  
                   then sadm_mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                        RM_FLAG=1
                fi  
                ;;
              
              p|P ) messok 22 01 "Do you want to delete $RM_MP filesystem"
                    if [ "$?" = "1" ]
                       then sadm_display_heading  "Delete the filesystem"
                            RM_FLAG=0
                            remove_fs 
                            RC=$?
                            if [ "$RC" -ne 0 ]
                               then sadm_mess "Error ($RC) occured while deleting the filesystem"
                               else sadm_mess "Filesystem deleted with success !"
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



#===================================================================================================
# Enlarge filesystem Menu
#===================================================================================================
enlarge_filesystem()
{
     RM_MP="" ; export RM_MP
     RM_MB="" ; export RM_MB
     RM_FLAG=0
     while :
        do
        sadm_display_heading  "Filesystem size increase"
        if [ $RM_FLAG -eq 1 ]
           then sadm_writexy 07 08 "Logical Volume Name .....................: $LVNAME"
                sadm_writexy 08 08 "Volume Group ............................: $VGNAME ($VGFREE MB Free)"
                sadm_writexy 09 08 "Filesystem Type .........................: $LVTYPE"
                sadm_writexy 10 08 "Filesystem Size in MB ...................: ${bold}${LVSIZE}${nrm}"
                sadm_writexy 11 08 "Filesystem Owner ........................: $LVOWNER"
                sadm_writexy 12 08 "Filesystem Group ........................: $LVGROUP"
                sadm_writexy 13 08 "Filesystem Protection ...................: $LVPROT"
        fi
        sadm_writexy 05 05  "1- Filesystem mount point to increase.......: $RM_MP "
        sadm_writexy 15 05  "2- New Filesystem Size in MB................: ${bold}${RM_MB}${nrm}"
        sadm_writexy 17 05  "P- Proceed with increasing the size........."
        sadm_writexy 18 05  "Q- Quit this menu..........................."
        sadm_writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
        sadm_writexy 21 38 " "
        read option
        case $option in

                 # ===== Accept Filesystem Mount point to increase
             1 ) accept_data 05 51 30 A $RM_MP
                 if ! mntexist $WDATA
                    then sadm_mess "Filesystem $WDATA does not exist"
                    else RM_MP=$WDATA
                         LVMOUNT=$RM_MP
                         get_mntdata $LVMOUNT
                         RM_FLAG=1
                         let "RM_MB=$LVSIZE+1"
                         getvg_info
                 fi
                 ;;

                 # Accept new filsystem size
             2 ) accept_data 15 51 07 N $RM_MB
                 if [ $WDATA -le $LVSIZE ] 
                    then sadm_mess "Size must be greater than ($LVSIZE) the actual size"
                    else RM_MB=$WDATA
                 fi
                 ;;

                 # ===== Proceed with Creation
           p|P ) let "wincr=$RM_MB - $LVSIZE"
                 messok 22 01 "Do you want to increase $RM_MP filesystem by $wincr MB"
                 if [ "$?" = "1" ]
                    then sadm_display_heading  "Filesystem size increase"
                         LVSIZE=$wincr
                         mount $LVMOUNT > /dev/null 2>&1
                         RM_FLAG=0
                         extend_fs
                         RC=$?
                         if [ "$RC" -ne 0 ]
                            then sadm_mess "Error ($RC) occured while increasing the filesystem"
                            else sadm_mess "Filesystem increased with success !"
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





#===================================================================================================
# Display Filesystem Menu
#===================================================================================================
display_fs_menu()
{
    sadm_display_heading  "Filesystem - Maintenance"
    sadm_writexy 05 20 "1- Create a filesystem..............."
    sadm_writexy 07 20 "2- Increase filesystem size ........."
    sadm_writexy 09 20 "3- Remove a filesystem..............."
    sadm_writexy 11 20 "4- Filesystem Integrity check (fsck)."
    sadm_writexy 15 20 "Q- Quit this menu...................."
    sadm_writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
    sadm_writexy 21 38 " "
}


#===================================================================================================
#                           P R O G R A M    S T A R T    H E R E
#===================================================================================================
   while :
      do
      display_fs_menu
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
   Q | q ) break
           ;;
        *) sadm_mess "Invalid option - $REPONSE"
           ;;
      esac
   done
   return 0