#! /usr/bin/env bash
#===================================================================================================
# Title      :  sam_ui_rpm.sh - sam rpm database Tools
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  2019_11_06
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam_ui_rpm.sh 1.0 06-Nov-2019
#
#===================================================================================================
# Description 
#   This script is used query and use rpm related tools 
#
#===================================================================================================
# History    :
#@2019_11_06 Added: v1.0 Initial version
#@2019_11_11 Updated: v1.1 Revamp the RPM question & display of results.
#
#===================================================================================================
trap 'exec $SADM/sadm' 2                                                # INTERCEPTE LE ^C
#



# --------------------------------------------------------------------------------------------------
# Display RPM Tools Menu
# --------------------------------------------------------------------------------------------------
display_menu()
{
    sadm_display_heading "RPM Packages Tools"
    OPT1="Search package name using this pattern.."
    OPT2="View changelog of the package..........." 
    OPT3="Reset files permissions of package......"
    OPT4="Display documentation files of package.."
    OPT5="Query RPM DB for install/update by date."
    OPT6="What RPM package provide that program..."
    OPT7="List files included in this package....."
    OPT8="Display Information about this package.."
    OPT9="Display URL of a package................"
    OPT10="List Repositories......................" 
    menu_array=("$OPT1" "$OPT2" "$OPT3" "$OPT4" "$OPT5" "$OPT6" "$OPT7" "$OPT8" "$OPT9" "$OPT10")
    s_count=${#menu_array[@]}                                           # Get Nb, of  items in Menu
    sadm_display_menu "${menu_array[@]}"                                # Display Menu Array
    return $?
}




#===================================================================================================
#  P R O G R A M    S T A R T    H E R E
#===================================================================================================

    while :
        do
        display_menu                                                    # Show Menu & Accept choice
        CHOICE=$?                                                       # Save User choice
        case $CHOICE in                         

            # Search the list of package installed for the string specified.
            1)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "Enter package name to search (or [Q] ):" # Display What to Enter
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 41 25 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else rpm -qa | grep -i $WDATA >$SADM_TMP_FILE1 2>&1 # Grep response in rpm list
                         stitle="Search for '$WDATA' package name"      # Heading Search Title 
                         if [ -s $SADM_TMP_FILE1 ]                      # If file not empty
                            then sadm_pager "$stitle" "$SADM_TMP_FILE1" 17      # Show results
                            else sadm_display_heading "$stitle"         # Show Screen Std Heading
                                 sadm_mess "No match were found for '$WDATA'."  # Advise user
                                 continue
                         fi
                fi
                ;;

            # View the change log of the package specified.
            2)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "View change log of the package (or [Q]) :" # Show What to Enter
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 43 25 A $rpm                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else rpm -q $WDATA > /dev/null 2>&1                 # Check if package exist
                         if [ $? -ne 0 ]                                # If Package doesn't exist
                            then sadm_mess "Package '$WDATA' doesn't exist or not installed"
                            else rpm -q --changelog $WDAT >$SADM_TMP_FILE1  # Query RPM DB 
                                 stitle="'$WDATA' Change Log"           # Heading Search Title 
                                 if [ -s $SADM_TMP_FILE1 ]              # If file not empty
                                    then sadm_pager "$stitle" "$SADM_TMP_FILE1" 17   # Show results
                                    else sadm_display_heading "$stitle" # Show Screen Std Heading
                                         sadm_mess "No log were found for '$WDATA'." # Advise user
                                         continue
                                 fi
                         fi
                fi
                ;;

            # Reset files permissions included in the package specified.
            3)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "Reset files permissions part of package (or [Q]) : " # Question 
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 52 20 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else RPM=$WDATA                                     # Save User Response
                         rpm -q $RPM > /dev/null 2>&1                   # Check if package exist
                         if [ $? -ne 0 ]                                # If Package doesn't exist
                            then sadm_mess "Package '$RPM' doesn't exist or not installed"
                            else sadm_messok 06 01 "Reset files permissions of package '$RPM'"
                                 if [ $? -eq 1 ]                        # If responded Yes
                                    then sadm_writexy 08 01 "Running command : 'rpm --setperms $RPM'" 
                                         rpm --setperms $RPM >$SADM_TMP_FILE1 2>&1 # Reset perm
                                         if [ $? -eq 0 ]                # If command went ok
                                            then msg="Files permissions were reset successfully."
                                            else msg="Files permissions were NOT reset successfully."
                                         fi
                                         sadm_writexy 09 01 "$msg"      # Show result to user
                                         sadm_mess ""                   # Wait for [ENTER]
                                 fi
                         fi
                fi 
                ;;

            # List documentation files included in a package
            4)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "View documentation files included in package (or [Q] ):"
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 57 25 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else RPM=$WDATA                                     # Save User Response
                         rpm -q $RPM > /dev/null 2>&1                   # Check if package exist
                         if [ $? -ne 0 ]                                # If Package doesn't exist
                            then sadm_mess "Package '$RPM' doesn't exist or not installed"
                            else rpm -qd $RPM >$SADM_TMP_FILE1  # Query RPM DB 
                                 stitle="Documentation files included in '$RPM'" # Heading DocSearch
                                 sadm_pager "$stitle" "$SADM_TMP_FILE1" 17 # Show results
                         fi
                fi
                ;;

            # Query RPM Database for install/update by Date.
            5)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                rpm -qa --last > $SADM_TMP_FILE1                        # Query RPM DB
                stitle="Install/Update sorted by date"                  # Heading Title 
                sadm_pager "$stitle" "$SADM_TMP_FILE1" 17               # Show results
                ;;

            # What package provide this program
            6)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "Show what package provide this program (or [Q] ):"
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 52 25 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Nothing Entered = Menu
                    else stitle="What package provide '$WDATA'"         # Menu Heading
                         yum whatprovides $WDATA > $SADM_TMP_FILE1 2>&1 # How provide this command
                         sadm_pager "$stitle" "$SADM_TMP_FILE1" 17      # Show results
                fi
                ;;


            # List files included in the specified package
            7)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "List files included in this package (or [Q] ):"
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 49 25 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else rpm -q $WDATA > /dev/null 2>&1                 # Check if package exist
                         if [ $? -ne 0 ]                                # If Package doesn't exist
                            then sadm_mess "Package '$WDATA' doesn't exist or not installed"
                            else rpm -ql $WDATA > $SADM_TMP_FILE1 2>&1
                                 stitle="Files included in package '$WDATA'"
                                 sadm_pager "$stitle" "$SADM_TMP_FILE1" 17      # Show results
                         fi
                fi
                ;;


            # Display Information about a package     # Show results
            8)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "Show information about this package (or [Q] ):"
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 49 25 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else rpm -q $WDATA > /dev/null 2>&1                 # Check if package exist
                         if [ $? -ne 0 ]                                # If Package doesn't exist
                            then sadm_mess "Package '$WDATA' doesn't exist or not installed"
                            else rpm -qi $WDATA > $SADM_TMP_FILE1 2>&1
                                 stitle="Display $WDATA Package Information"
                                 sadm_pager "$stitle" "$SADM_TMP_FILE1" 17      # Show results
                         fi
                fi
                ;;


            # Display Home Page of a package
            9)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "Show Home page of package $RPM (or [Q]) :"
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 39 25 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else rpm -q $WDATA > /dev/null 2>&1                 # Check if package exist
                         if [ $? -ne 0 ]                                # If Package doesn't exist
                            then sadm_mess "Package '$WDATA' doesn't exist or not installed"
                            else sadm_writexy 06 01 "The Home page of $WDATA is "
                                 PHOME=`rpm -q --qf "%{name} - %{url}\n" $WDATA`
                                 sadm_writexy 07 01 "$PHOME"
                                 sadm_mess " "
                         fi
                fi
                ;;




            # List Repositories ([A]ll, [D]isabled, [E]nabled.
            10)  menu_title="`echo ${menu_array[$CHOICE - 1]} | tr -d '.'`"
                sadm_display_heading "$menu_title"                      # Show Screen Std Heading
                sadm_writexy 04 01 "Show Home page of package $RPM (or [Q]) :"
                RPM=""                                                  # Clear User response
                sadm_accept_data 04 39 25 A $RPM                        # Accept Expr. to search
                if [ "$WDATA" = "Q" ] || [ "$WDATA" = "q" ] ; then continue ; fi
                if [ -z "$WDATA" ]                                      # If didn't enter anything
                    then continue                                       # Go and ask again
                    else rpm -q $WDATA > /dev/null 2>&1                 # Check if package exist
                         if [ $? -ne 0 ]                                # If Package doesn't exist
                            then sadm_mess "Package '$WDATA' doesn't exist or not installed"
                            else sadm_writexy 06 01 "The Home page of $WDATA is "
                                 PHOME=`rpm -q --qf "%{name} - %{url}\n" $WDATA`
                                 sadm_writexy 07 01 "$PHOME"
                                 sadm_mess " "
                         fi
                fi
                ;;

            # 99 = Quit was pressed
            99) stty $stty_orig
                cd $CURDIR
                SADM_EXIT_CODE=0
                break
                ;;
            
            # Anything else is invalid 
            *)  sadm_mess "Invalid option - $CHOICE"
                ;;
        esac
    done
