#! /usr/bin/env bash
#===================================================================================================
# Title      :  sam_ui_deb.sh - Debian (deb) Package Tools
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  2019_11_12
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam_ui_deb.sh 1.0 12-Nov-2019
#
#===================================================================================================
# Description 
#   This script is used query and use deb related tools 
#
#===================================================================================================
# History    :
# 2019_11_12 Added: v1.0 Initial version
# 2019_11_14 Added: v1.1 Test Phase
# 2019_11_18 Added: v1.2 First functional release
# 2019_11_21 Added: v1.3 Change Deb search method, now using 'apt-cache search'.
#
#===================================================================================================
trap 'exec $SADMIN/sadm' 2                                                # INTERCEPT  ^C
#

#===================================================================================================
# Scripts Variables 
#===================================================================================================
export DEB_VER="01.03"                                                  # This script Version.


# --------------------------------------------------------------------------------------------------
# Display DEB Tools Menu
# --------------------------------------------------------------------------------------------------
display_menu()
{
    sadm_display_heading "DEB Package Tools" "$DEB_VER" 
    OPT1="View package that provide a program/file.."
    OPT2="List files included in a package.........."
    OPT3="Search installed package for a pattern...."
    OPT4="View changelog of a package..............." 
    OPT5="View 'apt' history log(s)................."
    OPT6="View Information about a package.........."
    menu_array=("$OPT1" "$OPT2" "$OPT3" "$OPT4" "$OPT5" "$OPT6" )
    s_count=${#menu_array[@]}                                           # Get Nb, of  items in Menu
    sadm_display_menu "${menu_array[@]}"                                # Display Menu Array
    return $?
}



# --------------------------------------------------------------------------------------------------
# Search if a package is installed and list version, a brief description
# --------------------------------------------------------------------------------------------------
search_package_name() 
{
    while : 
        do 
        menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
        sadm_display_heading "$menu_title" "$DEB_VER"                   # Show Screen Std Heading
        sadm_writexy 04 01 "Enter string to search (or [Q] ):"          # Display What to Enter
        sadm_accept_data 04 35 25 A ""                                  # Accept Expr. to search
        if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then break ; fi   # Quit = Return to Caller
        if [ -z "$WDATA" ] ; then continue ; fi                         # If didn't enter anything
        
        sadm_writexy 06 01 "Running 'apt-get update' to refresh cache ..." 
        apt-get update >/dev/null 2>&1
        if [ $? -ne 0 ]                                                 # Command finish with error
           then sadm_mess "Command completed with error."               # Advise user
        fi 

        #format='${binary:Package}\t${Version}\t${binary:Summary}\n'
        #dpkg-query -W -f="$format" $WDATA > $SADM_TMP_FILE1 2>&1
        #dpkg -l | awk '{ printf "%-42s\n" ,$2 }'| grep $WDATA >$SADM_TMP_FILE1 2>&1
        apt-cache search --names-only "$WDATA" >$SADM_TMP_FILE1 2>&1    # Search Package in cache
        stitle="Search for '$WDATA' package name"                       # Heading Search Title 
        if [ -s $SADM_TMP_FILE1 ]                                       # If file not empty
           then sadm_pager "$stitle" "$SADM_TMP_FILE1" 17               # Show results
           else sadm_display_heading "$stitle" "$DEB_VER"               # Show Screen Std Heading
                sadm_mess "No match were found for '$WDATA'."           # Advise user
                continue
        fi
        done
}



# --------------------------------------------------------------------------------------------------
# Show the change log of a particular package
# --------------------------------------------------------------------------------------------------
view_changelog() 
{
    while : 
        do 
        menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"      # Build Title minux the dot
        sadm_display_heading "$menu_title" "$DEB_VER"                   # Show Screen Std Heading
        sadm_writexy 04 01 "View change log of the package (or [Q]) :"  # Show What to Enter
        sadm_accept_data 04 43 25 A ""                                  # Accept Expr. to search
        if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then break ; fi   # Exit - Return to caller
        if [ -z "$WDATA" ]                                              # If didn't enter anything
           then continue                                                # Go and ask again
           else dpkg -l $WDATA > /dev/null 2>&1                         # Check if package exist
                if [ $? -ne 0 ]                                         # If Package doesn't exist
                   then sadm_mess "Package '$WDATA' doesn't exist or not installed."
                   else apt-get changelog $WDATA >$SADM_TMP_FILE1       # Query package
                        stitle="'$WDATA' Change Log"                    # Heading Search Title 
                        if [ -s $SADM_TMP_FILE1 ]                       # If file not empty
                           then sadm_pager "$stitle" "$SADM_TMP_FILE1" 17   # Show results
                           else sadm_display_heading "$stitle" "$DEB_VER" # Show Screen Std Heading
                                sadm_mess "No log were found for '$WDATA'." # Advise user
                                continue
                        fi
                fi
        fi 
        done
}


# --------------------------------------------------------------------------------------------------
# Find what package provide the command or file entered
# --------------------------------------------------------------------------------------------------
what_provides() 
{
    while : 
        do 
        menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"      # Build Menu title, no dot
        sadm_display_heading "$menu_title" "$DEB_VER"                   # Show Screen Std Heading
        sadm_writexy 04 01 "For better and faster result, specify the full path of command or file."
        sadm_writexy 06 01 "Show what package provide this program (or [Q]):"
        sadm_accept_data 06 50 30 A ""                                  # Accept Expr. to search
        if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then break ; fi   # Exit - Return to caller

        if [ -z "$WDATA" ] ; then continue ; fi                         # Nothing Entered = Menu

        # Find what package provide an existing command/file.
        if [ -f "$WDATA" ]                                              # If command/file exist
           then sadm_writexy 08 01 "Running 'dpkg -S $WDATA' ..."       # Show what we do
                sadm_writexy 10 01 ""                                   # Position cursor for result
                dpkg -S "$WDATA" > $SADM_TMP_FILE1 2>&1                 # Execute the search
                RC=$?                                                   # Save Return Code
                cat $SADM_TMP_FILE1                                     # Show result & Error
                if [ $RC -ne 0 ]                                        # If Command Not Successful
                   then sadm_mess "Command completed with error."       # Advise user.
                   else sadm_mess "Command completed with success."     # Show user status
                fi 
                continue                                                # Go to while beginning
        fi


        # Find what package provide for a non existing command/file.
        stitle="What package provide '$WDATA'"                          # Menu Heading
        sadm_writexy 08 01 "Running 'apt-file update' to refresh cache ..." 
        apt-file update >/dev/null 2>&1
        if [ $? -eq 0 ]                                                 # If Command Successful
           then sadm_writexy 09 01 "Command completed with success." 
           else sadm_writexy 09 01 "Command completed with error."
        fi 
        #
        sadm_writexy 11 01 "Running 'apt-file search "$WDATA" | grep \"${WDATA}$\"' ..." 
        apt-file search "$WDATA" |grep "${WDATA}$" >$SADM_TMP_FILE1 2>&1 # How provide this command
        if [ $? -eq 0 ]                                                 # If Command Successful
           then if [ -s $SADM_TMP_FILE1 ]                               # If file not empty
                   then sadm_pager "$stitle" "$SADM_TMP_FILE1" 17       # Show results
                   else sadm_mess "The search didn't return anything." 
                fi
           else sadm_mess "Operation completed with error."             # Show Error was returned
        fi 
        done
}



# --------------------------------------------------------------------------------------------------
# List files included in a package
# --------------------------------------------------------------------------------------------------
list_package_files() 
{
    while : 
        do 
        menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"      # Build Menu Title from Item
        sadm_display_heading "$menu_title" "$DEB_VER"                   # Show Screen Std Heading
        sadm_writexy 04 01 "List files included in this package (or [Q]):"
        sadm_accept_data 04 48 25 A ""                                  # Accept Expr. to search
        if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then break ; fi   # Quit and return to caller

        if [ -z "$WDATA" ] ; then continue ; fi                         # If didn't enter anything
        dpkg -L $WDATA > /dev/null 2>&1                                 # Check if package exist
        if [ $? -ne 0 ]                                                 # If Package doesn't exist
           then sadm_mess "Package '$WDATA' doesn't exist or not installed"
           else dpkg -L $WDATA > $SADM_TMP_FILE1 2>&1                   # Create List if files incl.
                stitle="Files included in package '$WDATA'"             # Pager Heading 
                sadm_pager "$stitle" "$SADM_TMP_FILE1" 17               # Show results per page
        fi
        done
}


# --------------------------------------------------------------------------------------------------
# Show information about package
# --------------------------------------------------------------------------------------------------
show_package_info() 
{
    while : 
        do 
        menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"      # Build Menu Title from Item
        sadm_display_heading "$menu_title" "$DEB_VER"                   # Show Screen Std Heading
        sadm_writexy 04 01 "See information about the package name (or [Q]):"
        sadm_accept_data 04 50 25 A ""                                  # Accept Expr. to search
        if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then break ; fi   # Quit and return to caller
        if [ -z "$WDATA" ] ; then continue ; fi                         # If didn't enter anything

        dpkg -s $WDATA > $SADM_TMP_FILE1 2>&1                           # Check if package exist
        if [ $? -ne 0 ]                                                 # If Package doesn't exist
           then sadm_mess "Package '$WDATA' doesn't exist or not installed"
                continue                                                # Back to accept package 
        fi 
        stitle="Information about package '$WDATA'"                     # Pager Heading 
        sadm_pager "$stitle" "$SADM_TMP_FILE1" 17                       # Show results per page
        done
}



# --------------------------------------------------------------------------------------------------
# View apt history log
# --------------------------------------------------------------------------------------------------
view_apt_history_log() 
{
    menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
    sadm_display_heading "$menu_title" "$DEB_VER"                       # Show Screen Std Heading
    w="/var/log/apt/history.log"                                        # First log file name
    rm -f $SADM_TMP_FILE1 > /dev/null 2>&1                              # Make sure it doesn't exist

    if [ -f "$w" ]                                                      # First log file exist ?
       then printf "\n ----- Content of log file $w -----\n" >>$SADM_TMP_FILE1
            cat /var/log/apt/history.log >> $SADM_TMP_FILE1             # cat first log file
            for w in `ls -1t /var/log/apt/history*.gz`                  # Include All gz log
                do 
                printf "\n ----- Content of log file $w -----\n" >>$SADM_TMP_FILE1
                zcat $w >> $SADM_TMP_FILE1                              # Include compress log 
                done
    fi               

    stitle="APT History Log"                                            # Heading Title 
    if [ -s $SADM_TMP_FILE1 ]                                           # If file not empty
       then sadm_pager "$stitle" "$SADM_TMP_FILE1" 17                   # Show results
       else sadm_display_heading "$stitle"  "$DEB_VER"                  # Show Screen Std Heading
            sadm_mess "No log were found ($w)."                         # Advise user
    fi
}



#===================================================================================================
#  P R O G R A M    S T A R T    H E R E
#===================================================================================================

    while :
        do
        display_menu                                                    # Show Menu & Accept choice
        CHOICE=$?                                                       # Save User choice
        case $CHOICE in                         

            # What package provide this program
            1)  what_provides
                ;;

            # List files included in the specified package
            2)  list_package_files
                ;;

            # Search package installed for the string specified.
            3)  search_package_name
                ;;

            # View the change log of the package specified.
            4)  view_changelog
                ;;

            # View Change log of a package
            5)  view_apt_history_log 
                ;;

            # Display Information about a package
            6)  show_package_info
                ;;

            # 99 = Quit was pressed, return to caller
            99) break
                ;;
        esac
    done
