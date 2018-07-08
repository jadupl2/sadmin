#! /usr/bin/env sh
#---------------------------------------------------------------------------------------------------
#   Author      :   Your Name
#   Script Name :   XXXXXXXX.sh
#   Date        :   YYYY/MM/DD
#   Requires    :   sh and SADMIN Shell Library
#   Description :
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use 
#                   a 100 characters per line. Comments in script always begin at column 73. You 
#                   will have a better experience, if you set screen width to have at least 100 Chr.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <jacques.duplessis@sadmin.ca>.
#   Developer Web Site : http://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# Version Change Log 
#
# 2017_07_07    V1.0 Initial Version
# 2018_02_08    v1.1 Fix compatibility problem with 'dash' shell (Debian, Ubuntu, Raspbian)
# 2018_05_14    v1.2 Check if root is running script before calling sadm tool library
# 2018_05_14    v1.3 Add SADM_USE_RCH Variable to use or not the [R]eturn [C]ode [H]istory file
# 2018_05_15    v1.4 Add SADM_LOG_FOOTER & SADM_LOG_HEADER var. to create or not log header/footer
# 2018_05_19    v1.5 Make SADMIN Setup a Function, Minor fix and performance issue.
#               v1.5a Remove SADM_HOSTNAME DEFINITION from script (Done in sadmlib)
# 2018_05_26    v1.6 Added SADM_EXIT_CODE for User to use
# 2018_05_27    v1.7 Replace setup_sadmin Function by putting code at the beginning of source.
# 2018_06_03    v1.8 Small Ameliorations and corrections
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x
     


#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.8'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=6                                   ; export DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
cscript="${SADM_BIN_DIR}/sadm_osupdate_farm.sh" ; export cscript        # Scrit to run in crontab



# ==================================================================================================
#                      Update the crontab based on the $paction parameter
#
#   cscript  The name of the script to execute (With NO path - Need to be in $SADMIN/bin)
#   pname    The hostname of the server to include/modify/delete in crontab
#   paction  [C] for create entry  [U] for Updating the crontab   [D] Delete crontab entry
#   cmonth   13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#            Position 0 = Y Then ALL Months are Selected
#            Position 1-12 represent the month that are selected (Y or N)             
#            Default is YNNNNNNNNNNNN meaning will run every month 
#   cdom     32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#            Position 0 = Y Then ALL Date in the month are Selected
#            Position 1-31 Indicate (Y) date of the month that script will run or not (N)
#   cdow     8 Characters (either a Y or a N) 
#            If Position 0 = Y then will run every day of the week
#            Position 1-7 Indicate a week day () Starting with Sunday
#            Default is all Week (YNNNNNNN)
#   chour    Hour when the update should begin (00-23) - Default 1am
#   cmin     Minute when the update will begin (00-50) - Default 5min
#cdom
#cdom
#cdom
#cdom
#cdom
#  |  | | +--------- month (1 - 12)
#  |  | | |  +------ day of week (0 - 6) (Sunday=0 or 7)
#  |  | | |  | User |Command to execute  
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_farm.sh -s nano >/dev/null 2>&1
# ==================================================================================================
## Please don't edit manually, SADMIN generated file 2018-06-30 19:59:36
# 
#SADMIN=/sadmin
# Exemple of Line that will be written to crontab file ($SADM_CRON_FILE)
#15 02 * * 00 root /sadmin/bin/sadm_osupdate_farm.sh -s raspi0 >/dev/null 2>&1

update_crontab () 
{
    cserver=$1                                                          # Server Name (NOT FQDN)
    cscript=$2                                                          # Update Script to Run
    cmin=$3                                                             # Crontab Minute
    chour=$4                                                            # Crontab Hour
    cmonth=$5                                                           # Crontab Mth (YNNNN) Format
    cdom=$6                                                             # Crontab DOM (YNNNN) Format
    cdow=$7                                                             # Crontab DOW (YNNNN) Format

    # To Display Parameters received - Used for Debugging Purpose ----------------------------------
    if [ $DEBUG_LEVEL -gt 5 ] 
        then sadm_writelog "I'm in update crontab"
             sadm_writelog "cserver  = $cserver"                        # Server to run script
             sadm_writelog "cscript  = $cscript"                        # Script to execute
             sadm_writelog "cmonth   = $cmonth"                         # Month String YNYNYNYNYNY..
             sadm_writelog "cdom     = $cdom"                           # Day of MOnth String YNYN..
             sadm_writelog "cdow     = $cdow"                           # Day of Week String YNYN...
             sadm_writelog "chour    = $chour"                          # Hour to run script
             sadm_writelog "cmin     = $cmin"                           # Min. to run Script
             sadm_writelog "cronfile = $SADM_CRON_FILE"                 # Name of Output file
    fi
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    cline=`printf "%02d %02d" "$cmin" "$chour"`                         # Hour & Min. of Execution
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    # Construct DATE of the month (1-31) to run and add it to crontab line ($cline) ----------------
    flag_dom=0
    if [ "$cdom" == "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" ]                # If it's to run every Date
        then cline="$cline *"                                           # Then use a Star for Date
        else fdom=""                                                    # Clear Final Date of Month
             for i in {1..31}                                           # From the 1st to the 31th
                do                                                      # Of the month
                #echo "i=$i - ${cdom:$i:1}"                              # Debug Info
                if [ "${cdom:$i:1}" == "Y" ]                            # If Date Set to Yes 
                    then if [ $flag_dom -eq 0 ]                         # If First Date to Run 
                            then fdom=`printf "%02d" "$i"`              # Add Date to Final DOM
                                 flag_dom=1                             # No Longer the first date
                            else wdom=`printf "%02d" "$i"`              # Format the Date number
                                 fdom=`echo "${fdom},${wdom}"`          # Combine Final+New Date
                         fi
                fi                                                      # If Date is set to No
                done                                                    # End of For Loop
             cline="$cline $fdom"                                       # Add DOM in Crontab Line
    fi
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    # Construct the month(s) (1-12) to run the script and add it to crontab line ($cline) ----------
    flag_mth=0
    if [ "$cmonth" == "YNNNNNNNNNNNN" ]                                 # If it's to run every Month
        then cline="$cline *"                                           # Then use a Star for Month
        else fmth=""                                                    # Clear Final Date of Month
             for i in {1..12}                                           # From the 1st to the 12th
                do                                                      # Month of the year
                #echo "i=$i - ${cmonth:$i:1}"                            # Debug Info
                if [ "${cmonth:$i:1}" == "Y" ]                          # If Month Set to Yes 
                    then if [ $flag_mth -eq 0 ]                         # If First Month to Run 
                            then fmth=`printf "%02d" "$i"`              # Add Month to Final Months
                                 flag_mth=1                             # No Longer the first Month
                            else wmth=`printf "%02d" "$i"`              # Format the Month number
                                 fmth=`echo "${fmth},${wmth}"`          # Combine Final+New Months
                         fi
                fi                                                      # If Month is set to No
                done                                                    # End of For Loop
             cline="$cline $fmth"                                       # Add Month in Crontab Line
    fi
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the day of the week (0-6) to run the script and add it to crontab line ($cline) ----
    flag_dow=0
    if [ "$cdow" == "YNNNNNNN" ]                                        # Run every Day of Week ?
        then cline="$cline *"                                           # Then use Star for All Week
        else fdow=""                                                    # Final Day of Week Flag
             for i in {1..7}                                            # From Day 1(Sun) to 7(Sat)
                do                                                      # Day of the week (dow)
                #echo "i=$i - ${cdow:$i:1}"                              # Debug Info
                if [ "${cdow:$i:1}" == "Y" ]                            # If 1st Char=Y then AllWeek
                    then if [ $flag_dow -eq 0 ]                         # If First Day to Insert
                            then fdow=`printf "%02d" "$i"`              # Add day to Final Day
                                 flag_dow=1                             # No Longer the first Insert
                            else wdow=`printf "%02d" "$i"`              # Format the day number
                                 fdow=`echo "${fdow},${wdow}"`          # Combine Final+New Day
                         fi
                fi                                                      # If DOW is set to No
                done                                                    # End of For Loop
             cline="$cline $fdow"                                       # Add DOW in Crontab Line
    fi
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN
    cline="$cline root $cscript -s $cserver >/dev/null 2>&1";   
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    echo "$cline" >> $SADM_CRON_FILE                                    # Output Line to Crontab cfg
}



#===================================================================================================
# Process all your active(s) server(s) in the Database (Used if want to process selected servers)
#===================================================================================================
process_servers()
{
    sadm_writelog "Processing All Actives Servers"                  # Enter Servers Processing

    # Put Rows you want in the select 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/pdf/database directory
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir," 
    SQL="${SQL} srv_update_minute,srv_update_hour,srv_update_dom,srv_update_month,srv_update_dow"
    
    # Build SQL to select active server(s) from Database & output result in CSV Format to work file.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1
    # If File was not created or has a zero lenght then No Actives Servers were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_writelog "No Active Server were found."               # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 

    # Create Crontab File Header
    echo "# " > $SADM_CRON_FILE 
    echo "# Please don't edit manually, SADMIN generated." >> $SADM_CRON_FILE 
    echo "# Operating System Update Schedule" >> $SADM_CRON_FILE 
    echo "# " >> $SADM_CRON_FILE 
    echo "SADMIN=$SADM_BASE_DIR"  $SADM_CRON_FILE
    echo "# " >> $SADM_CRON_FILE 

    xcount=0; ERROR_COUNT=0;                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Server Counter
        db_name=`    echo $wline|awk -F, '{ print $1 }'`            # Extract Server Name
        db_os=`      echo $wline|awk -F, '{ print $2 }'`            # O/S (linux/aix/darwin)
        db_domain=`  echo $wline|awk -F, '{ print $3 }'`            # Extract Domain of Server
        db_monitor=` echo $wline|awk -F, '{ print $4 }'`            # Monitor  1=True 0=False
        db_sporadic=`echo $wline|awk -F, '{ print $5 }'`            # Sporadic 1=True 0=False
        db_rootdir=` echo $wline|awk -F, '{ print $7 }'`            # Client SADMIN Root Dir.
        fqdn_server=`echo ${db_name}.${db_domain}`              # Create FQDN Server Name
        db_updmin=`  echo $wline|awk -F, '{ print $8 }'`            # crontab Update Min field
        db_updhrs=`  echo $wline|awk -F, '{ print $9 }'`            # crontab Update Hrs field
        db_upddom=`  echo $wline|awk -F, '{ print $10 }'`           # crontab Update DOM field
        db_updmth=`  echo $wline|awk -F, '{ print $11 }'`           # crontab Update Mth field
        db_upddow=`  echo $wline|awk -F, '{ print $12 }'`           # crontab Update DOW field
        sadm_writelog " "                                               # Blank Line
        sadm_writelog "`printf %10s |tr " " "-"`"                       # Ten Dashes Line    
        sadm_writelog "Processing Server No.$xcount $fqdn_server"               # Server Count & FQDN Name 
        
        update_crontab "${db_name}" "$cscript" "$db_updmin" "$db_updhrs" "$db_updmth" "$db_upddom" "$db_upddow"

        done < $SADM_TMP_FILE1
    return $ERROR_COUNT                                                 # Return Err Count to caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    process_servers                                                     # Process All Active Servers
    #update_crontab "${db_name}" "$cscript" "01" "02" "YNNNNNNNNNNNN" "YNNNNNNNNNNNYYNNNNNNNNNNNNNNNNNN" "YNNNNNNN"
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    