#! /bin/bash
#===============================================================================
# Title      :  sam_rpm_tools.sh - sam rpm database Tools
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  2008-01-10
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam_rpm_tools.sh 1.0 10-Jan-2008
#
#===============================================================================
#
# Description 
#   This script is used query and use rpm related tools 
#
#===============================================================================
# History    :
#   1.0      Initial Version - Jan 2008 - Jacques Duplessis
#
#===============================================================================
trap 'exec $SAM/sam' 2   		# INTERCEPTE LE ^C
#



#===============================================================================
# Display RPM Tools Menu
#===============================================================================
display_rpm_menu()
{
	sadm_display_heading "RPM DataBase Tools"
	sadm_writexy 05 10 "01- Search for a package using this pattern.:"
	sadm_writexy 06 10 "02- View changelog of the package...........:" 
	sadm_writexy 07 10 "03- Reset files permissions of package......:"
	sadm_writexy 08 10 "04- Display documentation files of package..:"
	sadm_writexy 09 10 "05- Query packages install order & date.....:"
	sadm_writexy 10 10 "06- What RPM package provide that program...:"
	sadm_writexy 11 10 "07- List files included in this package.....:"
	sadm_writexy 12 10 "08- Display Information about this package..:"
	sadm_writexy 13 10 "09- Display URL of a package................:"
	sadm_writexy 15 10 " Q- Quit this menu...................."
	sadm_writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
	sadm_writexy 21 38 " "
}





#===============================================================================
#       P R O G R A M    S T A R T    H E R E
#===============================================================================
   while :
      do
      display_rpm_menu
      read REPONSE
      case $REPONSE in
	    1) RPM="" 
           sadm_accept_data 05 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   sadm_display_heading "Search for $RPM in package name"
                   sadm_writexy 04 01 "Searching for $RPM in package name\n"
                   rpm -qa | grep -i $RPM 
                   mess " " 
           fi
           ;;
	    2) RPM="" 
           sadm_accept_data 06 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   sadm_display_heading "Query Change log of package $RPM"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -q --changelog $RPM | less 
                   fi
           fi
           ;;
	    3) RPM="" 
           sadm_accept_data 07 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   sadm_display_heading "Reset Files Permissions of package $RPM"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm --setperms $RPM 
                           sadm_display_heading "Reset Files Permissions of package $RPM"
                           if [ $? -eq 0 ]
                              then mess "Files Permissions were reset successfully"
                              else mess "Files Persissions were NOT reset successfully"
                           fi
                   fi
           fi
           ;;
	    4) RPM="" 
           sadm_accept_data 08 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   sadm_display_heading "List documentation files of package $RPM"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -qd $RPM 
                   fi
           fi
           ;;
	    5) tput clear 
           echo "Processing request ..."
           rpm -qa --last | less 
           ;;
	    6) PGM="" 
           sadm_accept_data 10 56 25 A $PGM
           if [ -z "$WDATA" ] 
              then continue
              else if [ ! -e "$WDATA" ] 
                      then mess "$WDATA does not exist on the system ?" 
                      else PGM=$WDATA
                           sadm_display_heading "Package providing $PGM" 
                           sadm_writexy 04 01 "The file $PGM is part of this RPM package\n\n" 
                           rpm -qf $PGM  
                           mess " "
                   fi
           fi
           ;;
	    7) RPM="" 
           sadm_accept_data 11 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   sadm_display_heading "List files contained in $RPM Package"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -ql $RPM | less 
                   fi
           fi
           ;;
	    8) RPM="" 
           sadm_accept_data 12 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   sadm_display_heading "Display $RPM Package Information"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -qi $RPM | less 
                   fi
           fi
           ;;
	    9) RPM="" 
           sadm_accept_data 13 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   sadm_display_heading "Display URL of Package $RPM"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -q --qf "%{name} - %{url}\n" $RPM
                           mess " " 
                   fi
           fi
           ;;
   Q | q ) break
	       ;;
        *) mess "Invalid option - $REPONSE"
           ;;
      esac
   done
