#! /usr/bin/env bash
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
#   2.1      Revisited to work with LinuxMint - April 2017 - Jacques Duplessis
#   2.2      Correct cannot change filesystem type (always goes back to xfs)
#   2.3      Fix problem with filesystem increase
#@2019_02_25 Improvement: v2.4 SysAdmin Menu - (sadm command) Code revamp and add color to menu.
#@2019_04_07 Update: v2.5 Use color variables from SADMIN Libr.
#===================================================================================================

# Load Filesystem Library Tools
[ -f ${SADM_LIB_DIR}/sadmlib_fs.sh ] && . ${SADM_LIB_DIR}/sadmlib_fs.sh  



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
BATCH_MODE=0                        ; export BATCH_MODE                 # Batch mode OFF interactive
export FS_VER="02.05"                                                   # Filesystem Menu Version

#===================================================================================================
#                       Set FileSystem Creation Screen Default Value
#===================================================================================================
set_creation_default()
{
    CR_VG=`ls -1 $VGDIR | sort| head -1`        ; export CR_VG
    CR_LV=""                                    ; export CR_LV
    CR_MP=""                                    ; export CR_MP
    CR_MB="100"                                 ; export CR_MB
    CR_NS="0"                                   ; export CR_NS
    CR_SS="0"                                   ; export CR_SS
    case "$(sadm_get_osname)" in                                       
        "REDHAT"|"CENTOS")      CR_FT="ext4"
                                if [ "$(sadm_get_osmajorversion)" -lt 6 ] 
                                    then CR_FT="ext3" 
                                fi
                                if [ "$(sadm_get_osmajorversion)" -gt 6 ] 
                                    then CR_FT="xfs"  
                                fi
                                ;;
        "FEDORA")               CR_FT="xfs" 
                                ;;
        "UBUNTU"|"DEBIAN"|"RASPBIAN"|"LINUXMINT") CR_FT="ext4" 
                                ;;
        "*" )                   sadm_write "O/S $(sadm_get_osname) not supported yet.\n" 
                                ;;
    esac
    export CR_FT
}


#===================================================================================================
#                                   Create filesystem
#===================================================================================================
create_filesystem()
{
    set_creation_default                                                # Set FS Creation Default
    while : 
        do 
        sadm_display_heading  "Create Filesystem" "$FS_VER"
        sadm_show_menuitem 06 03 1 "Volume group............................. $CR_VG "
        sadm_show_menuitem 07 03 2 "Logical volume name...................... $CR_LV "
        sadm_show_menuitem 08 03 3 "Logical volume size in MB................ $CR_MB "
        sadm_show_menuitem 09 03 4 "Filesystem mount point................... $CR_MP "
        sadm_show_menuitem 10 03 5 "Filesystem Type (ext3,ext4,xfs).......... $CR_FT "
        sadm_show_menuitem 14 03 "P" "Proceed with creation ..................."
        sadm_show_menuitem 15 03 "Q" "Quit this menu..........................."
        sadm_writexy 21 01 "${GREEN}${REVERSE}${SADM_80_SPACES}\c"      # Line 21 - Rev. Video Line
        sadm_writexy 21 29 "Option ? ${NORMAL}  ${RIGHT}"                # Display "Option ? "
        sadm_writexy 21 38 " "                                          # Position to accept Choice
        read option
        case $option in       
                1 )     sadm_accept_data 06 50 10 A $CR_VG              # Accept Volume Group
                        if vgexist $WDATA
                            then CR_VG=$WDATA
                            else sadm_mess "Volume Group $WDATA does not exist"
                        fi
                        ;;
                2 )     sadm_accept_data 07 50 14 A $CR_LV              # Accept Logical volume name
                        if lvexist $WDATA  
                            then sadm_mess "The LV name ${WDATA} already exist"
                            else if [ "$WDATA" = "" ] || [[ ${WDATA:0:1} == "/" ]] ; 
                                    then sadm_mess "Invalid LV name ..."
                                    else CR_LV=$WDATA
                                 fi
                        fi
                        ;;
                3 )     sadm_accept_data 08 50 07 A $CR_MB              # Accept Logical Volume Size
                        if [ "$WDATA" -lt 32 ]
                            then sadm_mess "Filesystem Size must be at least 32 MB" 
                            else CR_MB=$WDATA
                        fi
                        ;;
                4 )     sadm_accept_data 09 50 30 A $CR_MP               # Accept Mount Point
                        if mntexist $WDATA  
                            then sadm_mess "Mount Point $WDATA already exist"
                            else if ! mntvalid $WDATA 
                                    then sadm_mess "First Character must be a \"/\""
                                    else CR_MP=$WDATA
                                 fi  
                        fi
	                    ;;
                5 )     sadm_accept_data 10 50 30 A $CR_FT              # Accept Filesystem Type
                        if [ "$WDATA" != "ext3" ] && [ "$WDATA" != "ext4" ] && [ "$WDATA" != "xfs" ]
                            then sadm_mess "Filesystem supported are ext3, ext4 and xfs." 
                            else CR_FT=$WDATA
                        fi
	                    ;;
              p|P )     sadm_messok 22 01 "Want to create $CR_MP filesystem" # Proceed with Creation ? 
                        if [ "$?" = "1" ] 
                            then sadm_display_heading  "Creating the filesystem" "$FS_VER"
                                 LVNAME=$CR_LV
                                 VGNAME=$CR_VG
                                 LVSIZE=$CR_MB
                                 LVTYPE=$CR_FT
                                 LVMOUNT=$CR_MP
                                 LVOWNER="root"
                                 LVGROUP="root"
                                 LVPROT="755"
                                 if ! metadata_creation_valid
                                     then sadm_mess "Filesystem Data is wrong - Please correct data"
                                          RC=1
                                     else echo " "                      # Blank line after heading
                                          create_fs
                                          RC=$?
                                fi
                                if [ "$RC" -ne 0 ] 
                                    then sadm_mess "Error ($RC) while creating the filesystem"
                                    else sadm_mess "Filesystem created with success !" 
		                                 set_creation_default
                                fi
                        fi
                        ;;
              q|Q )     break 
                        ;;
                * )     sadm_mess "Invalid response ..."                # Advise User if Incorrect
                        ;;                        
        esac
        done  
}


#===================================================================================================
#                            Run fsck on the selected filesystem
#===================================================================================================
filesystem_check()
{
    RM_MP="" ; export RM_MP
    RM_ST="" ; export RM_ST
    RM_FLAG=0
    while :
        do
        sadm_display_heading  "Filesystem Integrity Check" "$FS_VER"
        if [ $RM_FLAG -eq 1 ]
           then sadm_writexy 07 10 "Logical Volume Name .............: $LVNAME"
                sadm_writexy 08 10 "Volume Group ....................: $VGNAME"
                sadm_writexy 09 10 "Filesystem Type .................: $LVTYPE"
                sadm_writexy 10 10 "Size of filesystem MB ...........: $LVSIZE"
                sadm_writexy 11 10 "Owner of filesystem .............: $LVOWNER"
                sadm_writexy 12 10 "Filesystem Group ................: $LVGROUP"
                sadm_writexy 13 10 "Filesystem Permission ...........: $LVPROT"
        fi
        sadm_show_menuitem 05 05 1   "Mount Point to check................... $RM_MP "
        sadm_show_menuitem 16 05 "P" "Proceed with the filesystem check......"
        sadm_show_menuitem 17 05 "Q" "Quit this menu........................."
        sadm_writexy 21 01 "${GREEN}${REVERSE}${SADM_80_SPACES}\c" # Line 21 - Rev. Video Line
        sadm_writexy 21 29 "Option ? ${NORMAL}  ${RIGHT}"      # Display "Option ? "
        sadm_writexy 21 38 " "                                          # Position to accept Choice
        read option
        case $option in
            1 ) sadm_accept_data 05 50 30 A $RM_MP
                if ! mntexist $WDATA
                   then sadm_mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                        RM_FLAG=1
                fi
                ;;
          p|P ) sadm_messok 22 01 "Do you want to run a fsck on $RM_MP filesystem"
                if [ "$?" = "1" ]
                   then sadm_display_heading  "Filesystem Integrity Check" "$FS_VER"
                        RM_FLAG=0
                        filesystem_fsck
                        RC=$?
                        if [ "$RC" -ne 0 ]
                           then sadm_mess "Error ($RC) occurred while checking the filesystem"
                           else sadm_mess "Filesystem check ran with success !"
                                RM_MP="" ; export RM_MP
                                RM_ST="" ; export RM_ST
                        fi
                fi
                ;;
          q|Q ) break
                ;;
            * ) sadm_mess "Invalid response ..."                        # Advise User if Incorrect
                ;;                    
        esac
        done
}


#===================================================================================================
#                                   Delete filesystem Menu
#===================================================================================================
delete_filesystem()
{
    RM_MP="" ; export RM_MP
    RM_FLAG=0
    while :
	    do
        sadm_display_heading  "Delete a Filesystem" "$FS_VER"                 
        if [ $RM_FLAG -eq 1 ] 
           then sadm_writexy 07 09 "Logical Volume Name .........: $LVNAME"
                sadm_writexy 08 09 "Volume Group ................: $VGNAME"
                sadm_writexy 09 09 "Filesystem Type .............: $LVTYPE"
                sadm_writexy 10 09 "Filesystem Size in MB .......: $LVSIZE"
                sadm_writexy 11 09 "Filesystem Owner ............: $LVOWNER"
                sadm_writexy 12 09 "Filesystem Group ............: $LVGROUP"
                sadm_writexy 13 09 "Filesystem Permission .......: $LVPROT"

        fi
        sadm_show_menuitem 05 04 01  "Mount Point to delete......... $RM_MP "
        sadm_show_menuitem 16 04 "P" "Proceed with the delete......."
        sadm_show_menuitem 17 04 "Q" "Quit this menu................"
        sadm_writexy 21 01 "${GREEN}${REVERSE}${SADM_80_SPACES}\c" # Line 21 - Rev. Video Line
        sadm_writexy 21 29 "Option ? ${NORMAL}  ${RIGHT}"      # Display "Option ? "
        sadm_writexy 21 38 " "                                          # Position to accept Choice
        read option
        case $option in
            1 ) sadm_accept_data 05 40 40 A $RM_MP
                if ! mntexist $WDATA  
                   then sadm_mess "Mount Point $WDATA does not exist"
                   else RM_MP=$WDATA
                        LVMOUNT=$RM_MP
                        get_mntdata $LVMOUNT
                        RM_FLAG=1
                fi  
                ;;
          p|P ) sadm_messok 22 01 "Do you really want to delete $RM_MP filesystem"
                if [ "$?" = "1" ]
                   then sadm_display_heading  "Delete the filesystem" "$FS_VER"
                        echo " "                                        # Blank line after heading
                        RM_FLAG=0
                        remove_fs 
                        RC=$?
                        if [ "$RC" -ne 0 ]
                           then sadm_mess "Error ($RC) occurred while deleting the filesystem"
                           else sadm_mess "Filesystem deleted with success !"
                                RM_MP="" 
                        fi
                   else RM_MP="" 
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
        sadm_display_heading  "Filesystem size increase" "$FS_VER"
        if [ $RM_FLAG -eq 1 ]
           then sadm_writexy 07 08 "Logical Volume Name .................: $LVNAME"
                sadm_writexy 08 08 "Filesystem Type .....................: $LVTYPE"
                sadm_writexy 09 08 "Filesystem Size in MB ...............: ${LVSIZE}"
                sadm_writexy 10 08 "Filesystem Owner ....................: $LVOWNER"
                sadm_writexy 11 08 "Filesystem Group ....................: $LVGROUP"
                sadm_writexy 12 08 "Filesystem Permission ...............: $LVPROT"
        fi
        sadm_show_menuitem 05 03 1 "Filesystem mount point to increase...: $RM_MP "
        sadm_show_menuitem 15 03 2 "New Filesystem Size in MB............: ${BOLD}${RM_MB}${NORMAL}"
        sadm_show_menuitem 17 03 "P" "Proceed with increasing the size......"
        sadm_show_menuitem 18 03 "Q" "Quit this menu........................"
        sadm_writexy 21 01 "${GREEN}${REVERSE}${SADM_80_SPACES}\c" # Line 21 - Rev. Video Line
        sadm_writexy 21 29 "Option ? ${NORMAL}  ${RIGHT}"      # Display "Option ? "
        sadm_writexy 21 38 " "                                          # Position to accept Choice
        read option
        case $option in
             1 ) sadm_accept_data 05 47 35 A $RM_MP                     # Accept Mount point to incr
                 if ! mntexist $WDATA
                    then sadm_mess "Filesystem $WDATA doesn't exist"
                    else RM_MP=$WDATA
                         LVMOUNT=$RM_MP
                         get_mntdata $LVMOUNT
                         RM_FLAG=1
                         let "RM_MB=$LVSIZE+1"
                         getvg_info "$VGNAME"
                 fi
                 ;;
             2 ) sadm_accept_data 15 47 07 N $RM_MB                     # Accept new filsystem size
                 if [ $WDATA -le $LVSIZE ] 
                    then sadm_mess "Size must be greater than ($LVSIZE) the actual size"
                    else RM_MB=$WDATA
                 fi
                 ;;
           p|P ) let "wincr=$RM_MB - $LVSIZE"                           # Proceed with Creation
                 sadm_messok 22 01 "Do you want to increase $RM_MP filesystem by $wincr MB"
                 if [ "$?" = "1" ]
                    then sadm_display_heading  "Filesystem size increase" "$FS_VER"
                         echo " "                                       # Blank line after heading
                         LVSIZE=$wincr
                         mount $LVMOUNT > /dev/null 2>&1
                         RM_FLAG=0
                         extend_fs                                      # Call Extend FS Function
                         RC=$?
                         if [ "$RC" -ne 0 ]
                            then sadm_mess "Error ($RC) occurred while increasing the filesystem"
                            else sadm_mess "Filesystem increased with success !"
                                 RM_MP="" ; export RM_MP
                                 RM_MB="" ; export RM_MB
                         fi
                 fi
                 ;;
           q|Q ) break                                                  # Quit this menu
                 ;;
        esac
        done
}


#===================================================================================================
# P R O G R A M    S T A R T    H E R E
#===================================================================================================
    while :
        do
        sadm_display_heading  "Filesystem - Maintenance" "$FS_VER"
        menu_array=("Create a filesystem..............." \
                    "Increase filesystem size ........." \
                    "Remove a filesystem..............." \
                    "Filesystem Integrity check (fsck)." )
        sadm_display_menu "${menu_array[@]}"
        REPONSE=$?
        case $REPONSE in
                1)  create_filesystem
                    ;;
                2)  enlarge_filesystem
                    ;;
                3)  delete_filesystem
                    ;;
                4)  filesystem_check
                    ;;
               99)  break
                    ;;
                *)  sadm_mess "Invalid option - $REPONSE"
                    ;;
        esac
        done
   return 0