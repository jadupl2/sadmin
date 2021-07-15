#! /usr/bin/env sh
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_gen_relnotes.sh
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
# Change log, comment line semicolon separated fields (So don't use ';' in description)
# Field 1: Date of change (YYY_MM_DD) prefix by '@' 
#          - "sadm_gen_relnotes.sh" utility
#            - The '@' identify changes to be include in next release (To Create Change log).
#            - The '@' will be removed automatically when new version is release.
# Field 2: Standard Types of changes (Ignore case)
#           - "Added" or "New" for new features.
#           - "Changed" for changes in existing functionality.
#           - "Remove" for now removed features.
#           - "Fix" for any bug fixes.
#           - "Security" in case of vulnerabilities.
#           - "Doc" in case we modify code comments(documentation).
#           - "Minor" in case of minor modification.
#           - "Nolog" cosmetic change, won't appear in change log.
#           - "perf" Optimize for better performance
#          SADMIN related Changes
#           - "Web"         Web Interface modification
#           - "install"     Install, Uninstall & Update modification or fixes.
#           - "cmdline"     command line tools modification or fixes.
#           - "lib"         Library, Templates, Alerts, Libr demo modification & fixes.
#           - "mon"         Sadmin monitor modification or fixes.
#           - "backup"      Backup related modification or fixes.
#           - "config"      Configuration files modification or fixes.
#           - "server"      Server related modification or fixes.
#           - "client"      Server related modification or fixes.
#           - "Nolog"       cosmetic change, won't appear in change log.
#           - "osupdate"    O/S Update modification or fixes.
# Field 3: Version number 'v99.99'
# Field 4: Description of change (Max 60 Characters)
#
#@YYYY_MM_DD; Type;    vxx.xx; 123456789012345678901234567890123456789012345678901234567890---------
#---------------------------------------------------------------------------------------------------
# 2018_07_16    V1.0 Initial Version
# 2018_08_16    V1.1 With HTML Output
# 2018_10_15    V1.2 Change HTML Output to fit new design of download page.
# 2019_03_15 Improvement: v1.3 Reformat Changelog HTML Code and add Markdown code to change log.
# 2019_03_20 Feature: v1.4 If comment prefix is "nolog", in won't appear in changelog.
# 2019_06_11 nolog: v1.5 Comma can be included in change description without being drop.
# 2019_06_12 nolog: v1.6 Now include link to documentation for HTML change log.
#@2021_07_08 nolog: v1.7 Adapt to the SADMIN web Site.
#@2021_07_09 nolog: v1.8 remove old SADM section, Remove hard code working directory
#
#---------------------------------------------------------------------------------------------------
#@YYYY_MM_DD; Type;    vxx.xx; 123456789012345678901234567890123456789012345678901234567890---------
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
source ${SADMIN}/lib/sadmlib_std.sh                        # LOAD SADMIN Shell Library
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

# Command line option (-u) 
# Untag only new sources with tag date after last release date
export OPTION_U="N"                                                     
#
# Command line option (-o) 
# Untag only old sources with tag date before last release date
export OPTION_O="N"                                                     
#
# Command line option (-r) 
# Release the new version - It include -u -o)
export OPTION_R="N"                                                     

# Directories to search for "#@" at the beginning of lines
declare -a SEARCH_DIR
export SEARCH_DIR=( $SADM_BIN_DIR $SADM_CFG_DIR $SADM_LIB_DIR $SADM_SETUP_DIR $SADM_WWW_DIR )

# Array for section name & description
declare -A section_array
section_array=( [web]="Web interface" 
                [install]="Install, Uninstall & Update project" 
                [cmdline]="Command line tools"
                [lib]="Libraries, Scripts Templates, Demo"
                [mon]="System Monitor"
                [backup]="Backup related"
                [config]="Configuration files"
                [server]="SADMIN Server related"
                [client]="SADMIN Client related"
                [nolog]="Cosmetic change won't appear in change log"
                [osupdate]="Operating System Update"
                [added]="New Features"
                [update]="Update"
                [removed]="Removal"
                [fix]="Bug Fixes"
                [security]="Security"
                [doc]="Documentation Update"
                [minor]="Minor modification"
            )




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
    printf "\n\t-u              (Untag only new sources with tag date after last release date)"
    printf "\n\t-o              (Untag only old sources with tag date before last release date)"
    printf "\n\t-r              (Release the new version - It include -u -o)"
    printf "\n\n" 
}






#===================================================================================================
# Validate input file - Reject invalid formatted line - Deleted from file.
#
# Input Parameters :
#   - 1st Filename containing line to validate
#   - 2nd "E"= Print Error line, "A"= Print all lines 
# Return value :
#   - 0= No error detected
#   - 1= Invalid line were detected
#===================================================================================================
validate_input_file() 
{
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters."
             sadm_writelog "Function received $* and this isn't valid."
             sadm_writelog "Should receive a filename and "E" or "A"." 
             return 1
    fi

    # Save parameters received
    FILE=$1                                                             # Save Source file name
    KEY=$(sadm_toupper $2)                                              # Should be "E" or "A"

    # Check if the source file exist and readable.
    if [ ! -r "$FILE" ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} File ($FILE) don't exist."
             return 1
    fi    

    # Check for a valid report type (E or A)
    if [ "$KEY" != "A" ] && [ "$KEY" != "E" ] 
        then sadm_writelog "Error: ${FUNCNAME[0]} Invalid report type ($KEY) should be 'A' or 'E'."
             return 1
    fi    
    
    # Make sure output file exist and is empty
    if [ -f "$SADM_TMP_FILE3" ] ; then rm -f $SADM_TMP_FILE3 ; touch $SADM_TMP_FILE3 ; fi

    # Reset counter variables
    error_count=0                                                       # Error Count While Validate
    warning_count=0                                                     # Warn. Count While Validate
    valid_count=0                                                       # Valid Count While Validate

    sadm_writelog " "
    sadm_writelog "-----"
    sadm_writelog "Validating all changes lines collected."
    sadm_writelog "-----"
    sadm_writelog " "
    
    # Loop through all modified lines flagged (#@) 
     while read wline                                                   # Read each line collected
        do
        sadm_writelog " "
        sadm_writelog "-----" 
        sadm_writelog "Inspecting: ${wline}"
        
        SCRIPT_WITH_PATH=`echo $wline | awk -F: '{ print $1 }'`         # Extract ScriptName + Path
        PNAME=`basename $SCRIPT_WITH_PATH | tr -d ' '`                  # Extract ScriptName No Path
        PDATE=`echo $wline  |awk '{ print $1 }' |awk -F: '{print $2 }' | tr -d ' '`
        PSECNAME=`echo $wline |awk '{print $2}' |tr -d ':' |tr -d ' '`  # Isolate Section Name
        PSECNAME=$(sadm_tolower $PSECNAME)                              # Lowercase of Section Name
        PVER=`echo $wline   |awk '{ print $3 }' | tr -d ' '`            # Get Script version No.
        PDESC=`echo $wline  |cut  -f 4- -d" " `                         # Description of the change
        PSECDESC="Section $PSECNAME"                                    # Default Section Title
        if [ "$PDATE" = "YYYY_MM_DD;" ]                                 # Skip template lines
           then sadm_writelog "[ WARNING ] Skipping template line ($PDATE)"
                warning_count=$((warning_count+1))
                continue 
        fi                                                              # Skip template lines

        # Skip "nolog" section name and template code example 
        if [ "$PSECNAME" = "nolog" ] || [ "${wline:2:10}" = "YYYY_MM_DD" ] 
           then sadm_writelog "[ WARNING ] Line rejected ($PNAME - $UPDATE_DATE - $PSECNAME)"   
                sadm_writelog "Section = 'nolog' or template line."
                sadm_writelog "Continue with next line."
                warning_count=$((warning_count+1))
                continue
        fi

        # Transform last release date from YYYY_MM_DD to YYYYMMDD format (For comparison)
        LAST_REL_DATE=$(echo "$LAST_DATE" | tr -d '_')                  # Last Rel. Date without '_'

        # Transform date changed from YYYY_MM_DD to YYYYMMDD & validate if numeric (For comparison)
        UPDATE_DATE=$(echo "$PDATE" | tr -d '_')                        # Cur. Line Date without '_'
        RNOTE_DATE=$(echo "$PDATE" | tr '_' '/')                        # Change Date with slash
        num=`echo "$UPDATE_DATE" | grep -E ^\-?[0-9]?\.?[0-9]+$`        # Valid if Numeric Value
        if [ "$num" = "" ]                                              # No it's not numeric 
           then sadm_writelog "[ ERROR ] Line rejected ($PNAME) - Invalid Change Date ($UPDATE_DATE)"   
                sadm_writelog "Continue with next line."
                error_count=$((error_count+1))
                continue
        fi

        # If change were made after last release date we select it, else skip the line.
        # If Change Date prior than last release , continue read next line
        if [ $UPDATE_DATE -le $LAST_REL_DATE ]                          
            then sadm_writelog "[ WARNING ] Rejected date too old ($PNAME $UPDATE_DATE)"
                 warning_count=$((warning_count+1))
                 # (-o) (Untag only old sources with tag date before last release date)"
                 if [ "$OPTION_O" = "Y" ] 
                    then deactivate_line "$SCRIPT_WITH_PATH" "#@${PDATE}" 
                 fi
                 continue
            else # (-u) (Untag only new sources with tag date after last release date)"
                 if [ "$OPTION_U" = "Y" ] 
                    then deactivate_line "$SCRIPT_WITH_PATH" "#@${PDATE}" 
                 fi 
        fi 

        # Make Section Title Uniform.
        if [ "$PSECNAME" = "libr" ]     || [ "$PSECNAME" = "template" ]  ; then PSECNAME="lib"      ;fi
        if [ "$PSECNAME" = "script" ]   || [ "$PSECNAME" = "demo" ]      ; then PSECNAME="lib"      ;fi
        if [ "$PSECNAME" = "feature" ]  || [ "$PSECNAME" = "features" ]  ; then PSECNAME="new"      ;fi
        if [ "$PSECNAME" = "add" ]      || [ "$PSECNAME" = "added" ]     ; then PSECNAME="new"      ;fi
        if [ "$PSECNAME" = "secure" ]                                    ; then PSECNAME="security" ;fi
        if [ "$PSECNAME" = "change" ]                                    ; then PSECNAME="update"   ;fi
        if [ "$PSECNAME" = "changed" ]  || [ "$PSECNAME" = "updated" ]   ; then PSECNAME="update"   ;fi
        if [ "$PSECNAME" = "secure" ]   || [ "$PSECNAME" = "threat" ]    ; then PSECNAME="security" ;fi
        if [ "$PSECNAME" = "remove" ]   || [ "$PSECNAME" = "delete" ]    ; then PSECNAME="removed"  ;fi
        if [ "$PSECNAME" = "fixed" ]    || [ "$PSECNAME" = "fixes" ]     ; then PSECNAME="fix"      ;fi
        if [ "$PSECNAME" = "bugfix" ]   || [ "$PSECNAME" = "bugfixes" ]  ; then PSECNAME="fix"      ;fi
        if [ "$PSECNAME" = "documentation" ] || [ "$PSECNAME" = "docs" ] ; then PSECNAME="doc"      ;fi
        if [ "$PSECNAME" = "performance" ] || [ "$PSECNAME" = "speed" ]  ; then PSECNAME="perf"     ;fi

        for key in "${!section_array[@]}"                               # Loop through title array
            do 
            if [ "$PSECNAME" = "$key" ]                                 # Found section in array
                then PSECDESC=${section_array[$key]}                    # Get Section Title in Array
            fi
            done

        # Check if we have a valid section name
        if [ "$PSECDESC" = "Section $PSECNAME" ] 
            then sadm_writelog "Section $PSECNAME is not a valid section."
                 error_count=$((error_count+1))
                 if [ "$KEY" = "E" ] 
                    then sadm_writelog " "
                         if [ $SADM_DEBUG -gt 4 ] 
                            then sadm_writelog "ERROR -${error_count}- LINE DETECTED:"
                                 sadm_writelog "Script Path   :${SCRIPT_WITH_PATH}"
                                 sadm_writelog "Script Name   :${PNAME}"
                                 sadm_writelog "ChangeDate    :${PDATE}"
                                 sadm_writelog "Section       :${PSECNAME}"
                                 sadm_writelog "Section Title :${PSECDESC}"
                                 sadm_writelog "Version       :${PVER}"
                                 sadm_writelog "Description   :${PDESC}"
                                 sadm_writelog " "
                            else sadm_writelog "[ERROR] NAME=$PNAME PDATE=$PDATE PSECTION=$PSECTION PVER=$PVER"
                                 sadm_writelog " "
                         fi
                 fi 
                 continue
        fi 
        sadm_writelog "[OK] NAME=$PNAME PDATE=$PDATE PSECTION=$PSECNAME PVER=$PVER"
        echo "${PSECNAME};${PNAME};${RNOTE_DATE};${PVER};${PDESC}" >> $SADM_TMP_FILE3
        valid_count=$((valid_count+1))
        done < $FILE 

    sadm_writelog "-----"
    sadm_writelog "End of validation."
    sadm_writelog "   - Total warning : $warning_count" 
    sadm_writelog "   - Total error   : $error_count" 
    sadm_writelog "   - Total valid   : $valid_count" 
    sadm_writelog "-----"
    sadm_writelog " "
    return $error_count
}





#===================================================================================================
#                               Script Main Processing Function
#===================================================================================================
main_process()
{

    # Make sure work file exist and are empty
    if [ -f "$SADM_TMP_FILE1" ] ; then rm -f $SADM_TMP_FILE1 ; touch $SADM_TMP_FILE1 ; fi

    # Search for '^#@' in source and config files within every Directories selected 
    for WDIR in "${SEARCH_DIR[@]}"                                 
        do
        sadm_writelog "Searching in $WDIR for '^#@' ..."
        find $WDIR -type f -regex '.*\(sh\|pl\|php\|py|cfg|txt\)$' -exec grep -H "^#@" {} \; >>$SADM_TMP_FILE1
        done
    
    # Eliminate template line example and sort by Type of changes and version number
    grep -v "#@YYYY_MM_DD" $SADM_TMP_FILE1 | sort -t':' -k2,2 >$SADM_TMP_FILE2 

    # Remove #@ from every lines
    sed -i 's/\#@//g' $SADM_TMP_FILE2                                   # Remove #@ from every lines
 
    # Validate file and create a valid $SADM_TMP_FILE3 file.
    validate_input_file "$SADM_TMP_FILE2" "E" 

    # Write Markdown Change to the screen ready to include in changelog.md
    wrel=$(sadm_get_release)                                            # Get Release Number
    printf "## Release [${wrel}](https://github.com/jadupl2/sadmin/releases) (${CUR_DATE})\n   " > $CHANGELOG
    SECTION=""
    sort $SADM_TMP_FILE3 | while read wline                              # Read each line in file
        do
        if [ $SADM_DEBUG -gt 4 ] ; then printf "\nLine from SADM_TMP_FILE3: ${wline}" ; fi
        PSECNAME=`echo $wline | awk -F ';' '{ print $1 }'`
        PDATE=` echo $wline   | awk -F ';' '{ print $2 }'`
        PNAME=` echo $wline   | awk -F ';' '{ print $3 }'`
        PVER=`  echo $wline   | awk -F ';' '{ print $4 }'`
        PDESC=` echo $wline   | awk -F ';' '{ print $5 }'`
        SECTION_DESC=""
        if [ "$PSECNAME" != "$SECTION" ]                                # If Section Name change
            then PSECDESC="Section $PSECNAME"                           # Default Section Title
                 for key in "${!section_array[@]}"                      # Loop through title array
                    do 
                    if [ "$PSECNAME" = "$key" ]                         # Found section in array
                        then PSECDESC=${section_array[$key]}            # Get Section Title in Array
                    fi
                    done
#            printf "\n- $PSECDESC" >> $CHANGELOG                        # Write Section Desc in log
            printf "\n\n### $PSECDESC" >> $CHANGELOG                        # Write Section Desc in log
            SECTION=$PSECNAME                                           # Save new section name
        fi 
        if [ $SADM_DEBUG -gt 4 ] 
            then sadm_writelog "Line written to changelog : ..$PDATE.. ..${PNAME}.. ..${PSECDESC}.. ..$PVER.. ..$PDESC.."
        fi 
        printf "\n  - %s (%s %s) - %s"  "$PDATE" "$PVER" "$PNAME" "$PDESC"  >> $CHANGELOG
        done
  
    printf "\n   \n   " >> $CHANGELOG
    printf "\n\n----- Start of Markdown changelog ($CHANGELOG)\n\n"
    chmod 664 $CHANGELOG
    cat $CHANGELOG
    printf "\n----- End of Markdown changelog\n"
    return $SADM_EXIT_CODE                                              # Return ErrorCode to Caller

}




# --------------------------------------------------------------------------------------------------
# Function is used to remove the "@" in the comment line describing a change in the source.
# Normally the recent change change have a line similar to "#@2021_08_23".
# Function change that line to "# 2021_08_23" (removing the '@') in filename received.
#
# Parameters to receive:
#   1- Name of the source (with full path) that we need to change the line.
#   2- String to replace, normally something like this (#@2021_12_25) 
# Return value: 
#   0- Changed with success the source.
#   1- Error trying to make the change. 
# --------------------------------------------------------------------------------------------------
function deactivate_line()
{
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters."
             sadm_writelog "Function received $* and this isn't valid."
             sadm_writelog "Should receive a filename and string to change." 
             return 1
    fi

    # Save parameters received
    FILE=$1                                                             # Save Source file name
    KEY=$2                                                              # Key to change

    # Check if the source file exist and readable.
    if [ ! -r "$FILE" ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} File ($FILE) don't exist."
             return 1
    fi    

    # Minimum test on the key received must begin with "#@20"
    if [ "${KEY:0:4}" != "#@20" ] 
        then sadm_writelog "Error: Function ${FUNCNAME[0]} Invalid key received '${KEY:0:4}'."
             return 1
    fi    

    # Replace $KEY by $NEW in file.

    sadm_writelog "Untag '$KEY' in $FILE."
    NEW=$(echo $KEY | tr '@' ' ')                                       # Replace '@' by ' '
    sadm_writelog "Replacing '$KEY' by '$NEW' in $FILE."
    sed -i "s/$KEY/$NEW/" $FILE                                         # Replace $KEY without '@'
    RC=$?                                                               # Save return code 
    if [ $RC -ne 0 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} Couldn't remove '@' with 'sed' command."
             return 1
    fi    
    return 0 
}





# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# (-s) Start Date
# (-u) (Untag only new sources with tag date after last release date)"
# (-o) (Untag only old sources with tag date before last release date)"
# (-r) (Release the new version - It include -u -o)"
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "s:d:hvuor" opt ; do                                  # Loop to process Switch
        case $opt in
            u) OPTION_U="Y"                                             # Untag only new sources
               ;; 
            o) OPTION_O="Y"                                             # Untag only old sources
               ;; 
            r) OPTION_U="Y"                                             # Untag only new sources
               OPTION_O="Y"                                             # Untag only old sources
               OPTION_R="Y"                                             # Untag and Release process
               ;; 
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
               num=`echo "$LAST_DATE" | tr -d '_' | grep -E ^\-?[0-9]?\.?[0-9]+$`  
               if [ "$num" = "" ]                                       # No it's not numeric 
                    then sadm_writelog "[ ERROR ] Date not in valid format, should be YYYY_MM_DD."   
                         show_usage                                     # Display Help Usage
                         exit 1                                         # Exit Script with Error
               fi
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

    # Ask for a confirmation before replace "^#@" by "^# " in source files
    if [ "$OPTION_U" = "Y" ] 
        then sadm_ask "Are you sure you want to replace '#@' by '# ' in all sources" 
             if [ $? -eq 0 ] ; then printf "\nProcess aborted !\n" ; exit 0 ; fi 
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
    
