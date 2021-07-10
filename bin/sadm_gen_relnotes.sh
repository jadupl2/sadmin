#! /usr/bin/env sh
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_create_relnotes.sh
#   Date        :   2018_07_28
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Grep source for line beginning with "#@" that contain release notes of 
#                   modification for posting to web site release note page.
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use 
#                   a 100 characters per line. Comments in script always begin at column 73. You 
#                   will have a better experience, if you set screen width to have at least 100 Char
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
# Change log, comment line comma separated fields
# Field 1: Date of change (YYY_MM_DD) prefix by '@' 
#          - "sadm_gen_relnotes.sh" utility
#            - The '@' will be used to identify source modified to be added to "changelog.md".
#            - The '@' will be removed automatically when new version is release.
# Field 2: Types of changes (Ignore case)
#          - "Added" or "New" for new features.
#          - "Changed" for changes in existing functionality.
#          - "Removed" for now removed features.
#          - "Fixed" for any bug fixes.
#          - "Security" in case of vulnerabilities.
#          - "Doc" in case we modify code comments(documentation).
#          - "Minor" in case of minor modification.
#          - "Nolog" cosmetic change, won't appear in change log.
# Field 3: Version number 'v99.99'
# Field 4: Description of change (Max 60 Characters)
#
#@YYYY_MM_DD, Type,     vxx.xx, 123456789012345678901234567890123456789012345678901234567890--------
#---------------------------------------------------------------------------------------------------
# 2018_07_16    V1.0 Initial Version
# 2018_08_16    V1.1 With HTML Output
# 2018_10_15    V1.2 Change HTML Output to fit new design of download page.
# 2019_03_15 Improvement: v1.3 Reformat Changelog HTML Code and add Markdown code to change log.
# 2019_03_20 Feature: v1.4 If comment prefix is "nolog", in won't appear in changelog.
#@2019_06_11 New: v1.5 Comma can be included in change description without being drop.
#@2019_06_12 New: v1.6 Now include link to documentation for HTML change log.
#@2021_07_08 Update: v1.7 Adapt to the SADMIN web Site.
#@2021_07_09 Update: v1.8 remove old SADM section, Remove hard code working directory
#
#---------------------------------------------------------------------------------------------------
#@YYYY_MM_DD, Type,     vxx.xx, 123456789012345678901234567890123456789012345678901234567890--------
#---------------------------------------------------------------------------------------------------
#
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x
     



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.50
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null 
         if [ $? -eq 0 ]                                   # Found SADMIN in /etc/env.
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.8'                                      # Script Version
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script ?
export SADM_PID_TIMEOUT=7200                               # Seconds before PID Lock expire/ignore
export SADM_LOCK_TIMEOUT=3600                              # Sec. before System Lock File is deleted
export SADM_USE_RCH="N"                                    # Use & Update RCH History File 
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # LOAD SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
export SADM_ALERT_TYPE=0                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Server
# ---------------------------------------------------------------------------------------


  

# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
#
export CUR_DATE=`date "+%C%y-%m-%d"`                                    # GitHub Cur. Release Date 
export LAST_DATE=""                                                     # GitHub Last Release Date
export CHANGELOG="${SADM_TMP_DIR}/changelog.md"                         # New Release MD Changelog 




# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d              (Debug Level [0-9])"
    printf "\n\t-h              (Display this help message)"
    printf "\n\t-v              (Show Script Version Info)"
    printf "\n\t-s YYYY_MM_DD   (Last release date, skip change before this date)"
    printf "\n\n" 
}





#===================================================================================================
#                               Script Main Processing Function
#===================================================================================================
main_process()
{
    # Build a file that contains filenames that we want to search for lines beginning with '#@'.
    find $SADM_BIN_DIR   -type f -regex '.*\(sh\|pl\|php\|py\)$' -exec grep -H "^#@" {} \;   >$SADM_TMP_FILE1
    find $SADM_CFG_DIR   -type f -regex '.*$' -exec grep -H "^#@" {} \;                     >>$SADM_TMP_FILE1
    find $SADM_LIB_DIR   -type f -regex '.*\(sh\|pl\|php\|py\)$' -exec grep -H "^#@" {} \;  >>$SADM_TMP_FILE1
    find $SADM_SETUP_DIR -type f -regex '.*\(sh\|php\|py\)$' -exec grep -H "^#@" {} \;      >>$SADM_TMP_FILE1
    find $SADM_WWW_DIR   -type f -regex '.*\(sh\|php\|py\)$' -exec grep -H "^#@" {} \;      >>$SADM_TMP_FILE1

    # Sort by Date (Ascending Order)
    #cp $SADM_TMP_FILE1 /tmp/relnotes1.txt                               # Save Unsorted Rel. Notes
    sort -t':' -k2,2 $SADM_TMP_FILE1 > $SADM_TMP_FILE2                  # Sorted Rel. Notes
    #cp $SADM_TMP_FILE2 /tmp/relnotes2.txt                               # Save Rel Notes Sorted
    if [ "$SADM_DEBUG" -gt 4 ]                                          # For debugging purpose
        then sadm_writelog "Lines that we will be processing ..."       # Message to user
             nl $SADM_TMP_FILE2                                         # List lines selected
    fi
    sed -i 's/\#@//g' $SADM_TMP_FILE2                                   # Remove #@ from every lines


    # Example of format of lines we will process
    # /sadmin/bin/sadm_client_housekeeping.sh:#@2019_06_03 Update: v1.30 Include RCH format conversion, will do conversion only once.
    # /sadmin/bin/sadm_fetch_clients.sh:#@2019_06_06  Fix: v2.37 Fix problem sending alert when SADM_ALERT_TYPE was set 2 or 3.
    # /sadmin/bin/sadm_fetch_clients.sh:#@2019_06_07  New: v2.38 We now have et the end a alert status summary of all systems.
    # ----------------------------------------------------------------------------------------------
    rm -f $SADM_TMP_FILE1 >> /dev/null 2>&1                             # Clear new work output file
    cat $SADM_TMP_FILE2 | while read wline                              # Read each line in file
        do
        if [ $SADM_DEBUG -gt 4 ] ; then printf "\n-----\nProcessing Line : ${wline}" ; fi

        # Extract each field on the line.
        SCRIPT_WITH_PATH=`echo $wline | awk -F: '{ print $1 }'`         # Extract ScriptName + Path
        PNAME=`basename $SCRIPT_WITH_PATH`                              # Extract ScriptName No Path
        PDATE=`echo $wline  |awk '{ print $1 }' |awk -F: '{print $2 }'` # Date of Modification
        PSECTION=`echo $wline |awk '{ print $2 }' |tr -d ':'`           # Isolate Section Name
        PVER=`echo $wline   |awk '{ print $3 }'`                        # Get Script version No.
        PDESC=`echo $wline  |cut  -f 4- -d" " `                         # Description of the change
        PSECTION=$(sadm_capitalize $PSECTION)                           # Capitalize Section Name

        # Show Script name, Modification and Last Release Date.
        LAST_REL_DATE=$(echo "$LAST_DATE" | tr -d '_')
        UPDATE_DATE=$(echo "$PDATE" | tr -d '_')

        # If change were made before the start date, then skip the line and proceed with next one.
        if [ $UPDATE_DATE -gt $LAST_REL_DATE ] 
           then printf "\n %-30s %-08d %-08d %-8s" "$PNAME" $UPDATE_DATE $LAST_REL_DATE "Selected" 
           else printf "\n %-30s %-08d %-08d %-8s" "$PNAME" $UPDATE_DATE $LAST_REL_DATE "Rejected" 
                continue
        fi 

        # Under Debug Show Information about the change
        if [ $SADM_DEBUG -gt 4 ]
           then printf "\nScript Path :..${SCRIPT_WITH_PATH}.."
                printf "\nScript Name :..${PNAME}.."
                printf "\nChangeDate  :..${PDATE}.."
                printf "\nSection     :..${PSECTION}.."
                printf "\nVersion     :..${PVER}.."
                printf "\nDescription :..${PDESC}.." 
        fi 

        # When title is 'Nolog', ignore it (Don't want it to appears in changelog)
        if [ "$PSECTION" = "Nolog" ]    ; then continue ; fi 

        # Make Section Title Uniform.
        if [ "$PSECTION" = "Deprecate" ]  ; then PSECTION="Deprecated"  ; fi
        if [ "$PSECTION" = "Feature" ]    ; then PSECTION="Features"    ; fi
        if [ "$PSECTION" = "secure" ]     ; then PSECTION="Security"    ; fi
        if [ "$PSECTION" = "Change" ]     ; then PSECTION="Update"      ; fi
        if [ "$PSECTION" = "Changed" ]  || [ "$PSECTION" = "Updated" ]   ; then PSECTION="Update" ;fi
        if [ "$PSECTION" = "Added" ]    || [ "$PSECTION" = "Add" ]       ; then PSECTION="New" ;fi
        if [ "$PSECTION" = "Optimize" ] || [ "$PSECTION" = "Improve" ]   ; then PSECTION="Improvement" ;fi
        if [ "$PSECTION" = "Remove" ]   || [ "$PSECTION" = "Delete" ]    ; then PSECTION="Removed" ;fi
        if [ "$PSECTION" = "Fixed" ]    || [ "$PSECTION" = "Fix" ]       ; then PSECTION="Fixes" ;fi
        if [ "$PSECTION" = "Bugfix" ]   || [ "$PSECTION" = "Bugfixes" ]  ; then PSECTION="Fixes" ;fi
        if [ "$PSECTION" = "Doc" ]      || [ "$PSECTION" = "Docs" ]      ; then PSECTION="Documentation" ;fi
        if [ "$PSECTION" = "Redesign" ] || [ "$PSECTION" = "Rewritten" ] ; then PSECTION="Refactoring" ;fi

        # Show user what is written to output file
        if [ $SADM_DEBUG -gt 4 ]
           then printf "\nInfo just before writing to output file."
                printf "\nScript Path :..${SCRIPT_WITH_PATH}.."
                printf "\nScript Name :..${PNAME}.."
                printf "\nChangeDate  :..${PDATE}.."
                printf "\nSection     :..${PSECTION}.."
                printf "\nVersion     :..${PVER}.."
                printf "\nDescription :..${PDESC}.." 
        fi 

        printf "%s;%s;%s;%s;%s\n" "$PSECTION" "$PNAME" "$PDATE" "$PVER" "$PDESC"  >>$SADM_TMP_FILE1
        done
    

    # Write Markdown Change to the screen ready to include in changelog.md
    wrel=$(sadm_get_release)                                            # Get Release Number
    printf "\n\n## Release v[${wrel}](https://github.com/jadupl2/sadmin/releases) (${CUR_DATE})" > $CHANGELOG
    SECTION=""
    sort $SADM_TMP_FILE1 | while read wline                              # Read each line in file
        do
        if [ $SADM_DEBUG -gt 4 ] ; then printf "\nChangelog Pass Line : ${wline}\n" ; fi
        PSECTION=`echo $wline | awk -F ';' '{ print $1 }'`
        PDATE=` echo $wline   | awk -F ';' '{ print $2 }'`
        PNAME=` echo $wline   | awk -F ';' '{ print $3 }'`
        PVER=`  echo $wline   | awk -F ';' '{ print $4 }'`
        PDESC=` echo $wline   | awk -F ';' '{ print $5 }'`
        if [ "$PSECTION" != "$SECTION" ]
            then printf "\n- $PSECTION" >> $CHANGELOG
                 SECTION=$PSECTION
        fi 
        printf "\n\t- %s %s (%s) - %s"  "$PDATE" "$PNAME" "$PVER" "$PDESC"  >> $CHANGELOG
        done
    #sort -k2 $SADM_TMP_FILE2 | uniq
    printf "\n\n" >> $CHANGELOG
    printf "\n\n----- Start of Markdown changelog ($CHANGELOG)"
    chmod 664 $CHANGELOG
    cat $CHANGELOG
    printf "\n----- End of Markdown changelog\n"
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller

}


# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# (-s) Start Date
# --------------------------------------------------------------------------------------------------
function cmd_options()
{

    while getopts "s:d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
            s) LAST_DATE=$OPTARG                                        # Get Last Release date
               ;;                                                       # No stop after each page
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done       
    
    # MUST specify the Last Release Date
    if [ "$LAST_DATE" = "" ]                                           # If No Release date 
        then printf "\nYou must specify the last release date with the '-s' option." 
             show_usage
             exit 1
    fi  
    return 
}

#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
#
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
