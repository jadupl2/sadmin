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
	display_entete "RPM DataBase Tools"
	writexy 05 10 "01- Search for a package using this pattern.:"
	writexy 06 10 "02- View changelog of the package...........:" 
	writexy 07 10 "03- Reset files permissions of package......:"
	writexy 08 10 "04- Display documentation files of package..:"
	writexy 09 10 "05- Query packages install order & date.....:"
	writexy 10 10 "06- What RPM package provide that program...:"
	writexy 11 10 "07- List files included in this package.....:"
	writexy 12 10 "08- Display Information about this package..:"
	writexy 13 10 "09- Display URL of a package................:"
	writexy 15 10 " Q- Quit this menu...................."
	writexy 21 29 "${rvs}Option ? ${nrm}_${right}"
	writexy 21 38 " "
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
           accept_data 05 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   display_entete "Search for $RPM in package name"
                   writexy 04 01 "Searching for $RPM in package name\n"
                   rpm -qa | grep -i $RPM 
                   mess " " 
           fi
           ;;
	    2) RPM="" 
           accept_data 06 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   display_entete "Query Change log of package $RPM"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -q --changelog $RPM | less 
                   fi
           fi
           ;;
	    3) RPM="" 
           accept_data 07 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   display_entete "Reset Files Permissions of package $RPM"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm --setperms $RPM 
                           display_entete "Reset Files Permissions of package $RPM"
                           if [ $? -eq 0 ]
                              then mess "Files Permissions were reset successfully"
                              else mess "Files Persissions were NOT reset successfully"
                           fi
                   fi
           fi
           ;;
	    4) RPM="" 
           accept_data 08 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   display_entete "List documentation files of package $RPM"
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
           accept_data 10 56 25 A $PGM
           if [ -z "$WDATA" ] 
              then continue
              else if [ ! -e "$WDATA" ] 
                      then mess "$WDATA does not exist on the system ?" 
                      else PGM=$WDATA
                           display_entete "Package providing $PGM" 
                           writexy 04 01 "The file $PGM is part of this RPM package\n\n" 
                           rpm -qf $PGM  
                           mess " "
                   fi
           fi
           ;;
	    7) RPM="" 
           accept_data 11 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   display_entete "List files contained in $RPM Package"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -ql $RPM | less 
                   fi
           fi
           ;;
	    8) RPM="" 
           accept_data 12 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   display_entete "Display $RPM Package Information"
                   rpm -q $RPM > /dev/null 2>&1
                   if [ $? -ne 0 ] 
                      then mess "Package $RPM does not exist or not installed"
                      else rpm -qi $RPM | less 
                   fi
           fi
           ;;
	    9) RPM="" 
           accept_data 13 56 15 A $RPM
           if [ -z "$WDATA" ] 
              then continue
              else RPM=$WDATA
                   display_entete "Display URL of Package $RPM"
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
