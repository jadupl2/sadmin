#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadmmin_to_psadmin
#   Synopsis    :   Create Production SADMIN Environment from Development Environment
#   Version     :   1.0
#   Date        :   20 April 2018
#   Requires    :   sh and SADMIN Library
#   Description :
#
#   This code was originally written by Jacques Duplessis <duplessis.jacques@gmail.com>,
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2017_04_20    V1.0 - Initial Version
# 2017_04_20    V1.2 - First Production Release
# 2017_04_24    V1.3 - Exclude __pycache__ file from update - Setup msg Directory Added
# 2017_05_01    V1.4 - Test if not root at beginning
# 2017_06_03    V1.5 - Added usr directory and .backup file in cfg Dir.
# 2017_06_04    V1.6 - Added usr directory and .backup file in cfg Dir.
# 2017_06_13    V1.7 - Add Documentation files, Remove .bashrc, .bash_profile from package.
# 2018_06_15    v1.8 Make template read-only
# 2018_06_20    v1.9 Don't copy .dbpass when doing new Package
# 2018_06_23    v2.0 Change location of default service file (.sadmin.rc, sadmin.service) to cfg dir.
# 2018_07_09    v2.1 Copy .version & .versum from psadmin to sadmin at end so git = release version
# 2018_07_18    v2.2 Copy system monitor script template, nmon monitor & service restart in PSADMIN
# 2018_08_25    v2.3 Added .gitkeep file to empty directory so they exist in clone image & tgz file.
# 2018_08_26    v2.4 Rewritten to use rsync between sadmin to psadmin, cause want to use git (.git).
# 2018_09_14    v2.5 Added alert group, alert slack and alert History file to SADM
#@2018_09_14    v2.6 Added /usr/mon error message text file to process
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
    export SADM_VER='2.6'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    export SADM_ALERT_GROUP="default"                   # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
SADM_DASH=`printf %80s |tr " " "="`         ; export SADM_DASH          # 80 equals sign line
PSADMIN="/psadmin"                          ; export PSADMIN            # Prod. SADMIN Root Dir.
PSBIN="${PSADMIN}/bin"                      ; export PSBIN              # Prod. bin Directory
PSCFG="${PSADMIN}/cfg"                      ; export PSCFG              # Prod. cfg Directory
PSMON="${PSADMIN}/usr/mon"                  ; export PSMON              # Prod. SysMon Script Dir.
REL=`cat $SADM_REL_FILE`                    ; export REL                # Save Release Number
EPOCH=`date +%s`                            ; export EPOCH              # Current EPOCH Time
#



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
    printf "\n\n" 
}


#---------------------------------------------------------------------------------------------------
#  ASK USER THE QUESTION RECEIVED  -  RETURN 0 (FOR NO) OR  1 (FOR YES)
#---------------------------------------------------------------------------------------------------
ask_user()
{
    wmess="$1 [y,n] ? "                                                 # Save MEssage Received 
    wreturn=0                                                           # Function Default Value
    while :
        do
        echo -n "$wmess"                                                   # Write mess rcv + [ Y/N ] ?
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;; 
           n|N ) wreturn=0                                              # No = Return Value of 0
                 break                                                  # Break of the loop
                 ;;
             * ) ;;                                                     # Other stay in the loop
         esac
    done
   return $wreturn                                                      # Return 0=No 1=Yes
}


#===================================================================================================
# RUN O/S COMMAND RECEIVED AS PARAMETER - RETURN 0 IF SUCCEEDED - RETURN 1 IF ERROR ENCOUNTERED
#===================================================================================================
run_oscommand()
{
    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "Invalid number of parameter received by $FUNCNAME function"
             sadm_writelog "Please correct script please, script aborted" # Advise that will abort
             return 1                                                   # Prepare to exit gracefully
        else CMD="$1"                                                   # Save Command to execute
    fi

    if [ $DEBUG_LEVEL -gt 4 ] 
        then sadm_writelog "Command to execute is $CMD"
    fi
    $CMD >>$SADM_LOG 2>&1 
    RC=$?
    if [ $RC -ne 0 ]
        then sadm_writelog "[ ERROR ] ($RC) Running : $CMD"
             return 1
        else sadm_writelog "[ OK ] Command '$CMD' succeeded" 
    fi      
    return 0
}


#===================================================================================================
# CREATE SADMIN DIRECTORY RECEIVED AND CHOWN, CHMOD
#===================================================================================================
create_dir()
{
    WDIR="${PSADMIN}/${1}"
    sadm_writelog " "
    sadm_writelog "Creating Directory ${WDIR}"
    if [ ! -d ${WDIR} ] 
        then    mkdir ${WDIR} 
                RC=$?
                if [ $RC -ne 0 ]
                    then sadm_writelog "[ ERROR ] Trying to create Directory $WDIR ($RC)"
                         return 1
                    else sadm_writelog "[ OK ] Directory Creation Succeeded" 
                fi   
    fi
    run_oscommand "chmod 775 $WDIR"
    run_oscommand "chown sadmin.sadmin $WDIR"
    return 0
}

#---------------------------------------------------------------------------------------------------
# CREATE LATEST VERSION OF TGZ AND TXT FILE
#---------------------------------------------------------------------------------------------------
create_release_file()
{
    wreturn=0                                                           # Return Default Value
#
    REL=`cat ${SADM_CFG_DIR}/.release`               ; export REL       # Save Release Number
    EPOCH=`date +%s`                                 ; export EPOCH     # Current EPOCH Time
    WSADMIN="/wsadmin"                               ; export WSADMIN   # Root Dir of Web Site

    # Increase Minor Release Number
    #RELMIN_FILE="$WSADMIN/jack/cfg/relmin"                              # Minor Release file No.
    #relmin=`cat $RELMIN_FILE`                                           # Get Previous Minor Rel No.
    #relmin=$(($relmin+1))                                               # Increase Nimor Release No.    
    #RELMIN=`echo $relmin | awk '{ printf "%02d", $1}'`                  # Minor Rel always 2 digits
    #echo "$RELMIN" > $RELMIN_FILE                                       # Update Minor Release File

    # Create Version tgz file
    WCUR_DATE=$(date "+%C%y%m%d")                                       # Save Current Date
    TGZ_DIR="$WSADMIN/jack/version_history"                             # Where Ver. are stored
    TGZ_FILE="${TGZ_DIR}/sadmin_${REL}_${WCUR_DATE}.tgz"                # Update TGZ File Version
    echo "sadmin_${REL}_${WCUR_DATE}" > ${PSADMIN}/cfg/.version         # Create version file in tgz
    cd $PSADMIN                                                         # cd in production root
    #

    # Create New Release CheckSum file
    sadm_writelog " " 
    sadm_writelog "Creation Release ${REL}_${WCUR_DATE} Snapshot File (${PSADMIN}/cfg/.versum)" 
    find  . -type f -exec md5sum {} \; | grep -iv "__pycache__" > ${PSADMIN}/cfg/.versum  
    #
    sadm_writelog "Creation Release ${REL}_${WCUR_DATE} tgz file ($TGZ_FILE)" # Show Usr backup begin
    tar -cvzf $TGZ_FILE . >> $SADM_LOG 2>&1                             # Create tgz file
    wreturn=$?                                                          # Save Return code

    # Create Version txt File
    TXT_FILE="${TGZ_DIR}/sadmin_${REL}_${WCUR_DATE}_checksum.txt"       # SADMIN TXT Version File
    sadm_writelog "Creating Release CheckSum File $TXT_FILE ..."
    echo "SADMIN Release ${REL} - sadmin_${REL}_${WCUR_DATE}.tgz"   > $TXT_FILE
    sha1sum   $TGZ_FILE | awk '{ printf "sha1sum   : %s \n", $1 }' >> $TXT_FILE
    md5sum    $TGZ_FILE | awk '{ printf "md5sum    : %s \n", $1 }' >> $TXT_FILE
    sha256sum $TGZ_FILE | awk '{ printf "sha256sum : %s \n", $1 }' >> $TXT_FILE

    return $wreturn                                                     # Return 0=No 1=Yes
}


#===================================================================================================
#    Function use to rsync Development Directory (/sadmin) with Production Directory (/psadmin)
#===================================================================================================
rsync_function()
{
    # Parameters received should always be two 
    # If not write error to log and return to caller
    if [ $# -ne 2 ]
        then sadm_writelog "[ERROR] Function ${FUNCNAME[0]} didn't receive 2 parameters"
             sadm_writelog "Function received $* and this isn't valid"
             return 1
    fi

    # Save rsync information
    SRC_DIR=$1                                                          # Source Directory
    DEST_DIR=$2                                                         # Destination directory

    # If Source directory doesn't exist - Return to caller with error 
    if [ ! -d "${SRC_DIR}" ] 
        then sadm_writelog "[ERROR] Source Directory ${SRC_DIR} don't exist"
             return 1
    fi

    # Rsync Source directory with Destination - On error try 3 times before signaling error
    # Consider Error 24 as none critical (Partial transfer due to vanished source files)
    RETRY=0                                                             # Set Retry counter to zero
    while [ $RETRY -lt 3 ]                                              # Retry rsync 3 times
        do
        RETRY=`expr $RETRY + 1`                                         # Incr Retry counter.
        rsync -var --delete ${SRC_DIR} ${DEST_DIR} | tee -a $SADM_LOG   # rsync selected directory
        RC=$?                                                           # save error number
        if [ $RC -eq 24 ] ; then RC=0 ; fi                              # Source File Gone = OK
        if [ $RC -ne 0 ]                                                # If Error doing rsync
           then if [ $RETRY -lt 3 ]                                     # If less than 3 retry
                   then sadm_writelog "[RETRY ${RETRY}] rsync -var --delete ${SRC_DIR} ${DEST_DIR} "
                   else sadm_writelog "[ERROR ${RETRY}] rsync -var --delete ${SRC_DIR} ${DEST_DIR} "
                        break
                fi
           else sadm_writelog "[ OK ] rsync -var --delete ${SRC_DIR} ${DEST_DIR} "
                break
        fi
    done
    return $RC
}


#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    sadm_writelog " "
    sadm_writelog "Main Process as started ..."
    ERROR_COUNT=0;                                                      # Reset Server/Error Counter

    # Delete Everything in ${PSADMIN} then start copying/rsyncing from $SADMIN
    if [ ! -d ${PSADMIN} ]
        then sadm_writelog "The ${PSADMIN} directory not found - Abort Process"
             return 1
    fi
    cd ${PSADMIN} 
    if [ "`pwd`" != "${PSADMIN}" ]
       then sadm_writelog "Could not cd to ${PSADMIN}, please check that - Abort Process" 
            return 1
    fi
    sadm_writelog "Currently in `pwd` directory"

    # Rsync Bin/Scripts Directory -----------------------------------------------------------------------
    sadm_writelog " "                                                   # Insert Blank Line
    sadm_writelog "$SADM_DASH"                                          # Insert a dash line.
    SDIR="$SADM_BIN_DIR" ; DDIR="${PSADMIN}/bin"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform USer
    rsync_function "${SDIR}/" "${DDIR}/"                                # RSync Source/Dest. Dir.
    if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] while syncing ${SDIR} to ${DDIR}" ; return 1 ; fi
    #
    run_oscommand "chmod  444 ${DDIR}/sadm_template*"                   # Make Template Read Only

    # Rsync Documentation Directories --------------------------------------------------------------------
    sadm_writelog " "                                                   # Insert Blank Line
    sadm_writelog "$SADM_DASH"                                          # Insert a dash line.
    SDIR="$SADM_DOC_DIR" ; DDIR="${PSADMIN}/doc"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform USer
    rsync_function "${SDIR}/" "${DDIR}/"                                # RSync Source/Dest. Dir.
    if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] while syncing ${SDIR} to ${DDIR}" ; return 1 ; fi


    # Rsync Package Directories --------------------------------------------------------------------
    sadm_writelog " "                                                   # Insert Blank Line
    sadm_writelog "$SADM_DASH"                                          # Insert a dash line.
    SDIR="$SADM_PKG_DIR" ; DDIR="${PSADMIN}/pkg"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform USer
    rsync_function "${SDIR}/" "${DDIR}/"                                # RSync Source/Dest. Dir.
    if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] while syncing ${SDIR} to ${DDIR}" ; return 1 ; fi

    # Rsync Library Directories --------------------------------------------------------------------
    sadm_writelog " "                                                   # Insert Blank Line
    sadm_writelog "$SADM_DASH"                                          # Insert a dash line.
    SDIR="$SADM_LIB_DIR" ; DDIR="${PSADMIN}/lib"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform USer
    rsync_function "${SDIR}/" "${DDIR}/"                                # RSync Source/Dest. Dir.
    if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] while syncing ${SDIR} to ${DDIR}" ; return 1 ; fi

    # Rsync Setup Directories ----------------------------------------------------------------------
    sadm_writelog " "                                                   # Insert Blank Line
    sadm_writelog "$SADM_DASH"                                          # Insert a dash line.
    SDIR="${SADMIN}/setup" ; DDIR="${PSADMIN}/setup"                    # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    rsync -var --delete --exclude 'jac' ${SDIR}/ ${DDIR}/ | tee -a $SADM_LOG   # rsync selected directory
    RC=$?                                                           # save error number
    if [ $RC -eq 24 ] ; then RC=0 ; fi                              # Source File Gone = OK
    if [ $RC -ne 0 ] ; then sadm_writelog "[ERROR] while syncing ${SDIR} to ${DDIR}" ; return 1 ; fi
    find ${DDIR} -name "*.log" -exec rm -f {} \;

    # Rsync System Directories ---------------------------------------------------------------------
    sadm_writelog " "                                                   # Insert Blank Line
    sadm_writelog "$SADM_DASH"                                          # Insert a dash line.
    SDIR="$SADM_SYS_DIR" ; DDIR="${PSADMIN}/sys"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform USer
    rsync_function "${SDIR}/" "${DDIR}/"                                # RSync Source/Dest. Dir.
    if [ $? -ne 0 ] ; then sadm_writelog "[ERROR] while syncing ${SDIR} to ${DDIR}" ; return 1 ; fi

    # Rsync www Directories ----------------------------------------------------------------------
    sadm_writelog " "                                                   # Insert Blank Line
    sadm_writelog "$SADM_DASH"                                          # Insert a dash line.
    SDIR="${SADMIN}/www" ; DDIR="${PSADMIN}/www"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    rsync -var --delete --exclude 'dat' --exclude 'rrd' --exclude 'tmp' /sadmin/www/ /psadmin/www/ | tee -a $SADM_LOG   # rsync selected directory
    RC=$?                                                           # save error number
    if [ $RC -eq 24 ] ; then RC=0 ; fi                              # Source File Gone = OK
    if [ $RC -ne 0 ] ; then sadm_writelog "[ERROR] while syncing ${SDIR} to ${DDIR}" ; return 1 ; fi
    find ${DDIR} -name "*.log" -exec rm -f {} \;

    # Copy Configuration File from COPY $SADMIN/cfg to /psadmin/cfg --------------------------------
    sadm_writelog " "
    sadm_writelog "Syncing cfg directory $SADM_CFG_DIR to ${PSCFG}"
    #run_oscommand "touch ${PSCFG}/.dbpass"                              # Just make sure it exist
    #run_oscommand "chmod 644 ${PSCFG}/.dbpass"                          # and have the proper perm.
    #run_oscommand "chown sadmin.sadmin ${PSCFG}/.dbpass"                # And belong to sadmin user
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.release ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.release"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.release"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.sadmin.cfg ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.sadmin.cfg"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.sadmin.cfg"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.template.smon ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.template.smon"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.template.smon"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.backup_list.txt ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.backup_list.txt"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.backup_list.txt"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.backup_exclude.txt ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.backup_exclude.txt"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.backup_exclude.txt"    
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.sadmin.service ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.sadmin.service"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.sadmin.service"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.sadmin.rc ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.sadmin.rc"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.sadmin.rc"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.alert_group.cfg ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.alert_group.cfg"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.alert_group.cfg"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.alert_slack.cfg ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.alert_slack.cfg"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.alert_slack.cfg"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.alert_history.txt ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.alert_history.txt"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.alert_history.txt"
    #
    run_oscommand "cp ${SADM_CFG_DIR}/.alert_history.seq ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.alert_history.seq"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.alert_history.seq"


    # COPY SADMIN LICENCE / README FILE------------------------------------------------------------
    sadm_writelog " "
    sadm_writelog "Copy Licence File to ${PSADMIN}"
    run_oscommand "cp ${SADMIN}/LICENSE ${PSADMIN}"
    run_oscommand "chmod 444 ${PSADMIN}/LICENSE"
    run_oscommand "chown sadmin.sadmin ${PSADMIN}/LICENSE"
    #
    sadm_writelog " "
    sadm_writelog "Copy README File to ${PSADMIN}"
    run_oscommand "cp ${SADMIN}/README.md ${PSADMIN}"
    run_oscommand "chmod 664 ${PSADMIN}/README.md"
    run_oscommand "chown sadmin.sadmin ${PSADMIN}/README.md"
    

    # COPY SYSTEM MONITOR SCRIPT TEMPLATE, NMON MONITOR and Service Retart Script ------------------
    sadm_writelog " "
    sadm_writelog "Copy SysMon Script Template to ${PSMON}"
    run_oscommand "cp ${SADM_UMON_DIR}/stemplate.sh ${PSMON}"
    run_oscommand "chmod 775 ${PSMON}/stemplate.sh"
    run_oscommand "chown sadmin.sadmin ${PSMON}/stemplate.sh"
    run_oscommand "cp ${SADM_UMON_DIR}/stemplate.txt ${PSMON}"
    run_oscommand "chmod 664 ${PSMON}/stemplate.txt"
    run_oscommand "chown sadmin.sadmin ${PSMON}/stemplate.txt"
    #
    sadm_writelog " "
    sadm_writelog "Copy NMON Watcher to ${PSMON}"
    run_oscommand "cp ${SADM_UMON_DIR}/swatch_nmon.sh ${PSMON}"
    run_oscommand "chmod 775 ${PSMON}/swatch_nmon.sh"
    run_oscommand "chown sadmin.sadmin ${PSMON}/swatch_nmon.sh"
    run_oscommand "cp ${SADM_UMON_DIR}/swatch_nmon.txt ${PSMON}"
    run_oscommand "chmod 664 ${PSMON}/swatch_nmon.txt"
    run_oscommand "chown sadmin.sadmin ${PSMON}/swatch_nmon.txt"
    #
    sadm_writelog " "
    sadm_writelog "Copy Service Restart to ${PSMON}"
    run_oscommand "cp ${SADM_UMON_DIR}/srestart.sh ${PSMON}"
    run_oscommand "chmod 775 ${PSMON}/srestart.sh"
    run_oscommand "chown sadmin.sadmin ${PSMON}/srestart.sh"
    #

    # Touch Empty Directory to Keep
    touch ${PSADMIN}/usr/bin/.gitkeep
    touch ${PSADMIN}/usr/doc/.gitkeep
    touch ${PSADMIN}/usr/lib/.gitkeep
    touch ${PSADMIN}/dat/.gitkeep
    touch ${PSADMIN}/tmp/.gitkeep
    touch ${PSADMIN}/log/.gitkeep
    touch ${PSADMIN}/dat/nmon/.gitkeep
    

    # COPY .bashrc and .bash_profile file-----------------------------------------------------------
    #
    #sadm_writelog " "
    #SFILE="${SADMIN}/.bashrc" ; DFILE="${PSADMIN}/.bashrc"
    #sadm_writelog "Copying $SFILE to $DFILE"
    #run_oscommand "cp ${SFILE} ${DFILE}"
    #run_oscommand "chmod 775 ${DFILE}"
    #run_oscommand "chown sadmin.sadmin ${DFILE}"
    #    
    #sadm_writelog " "
    #SFILE="${SADMIN}/.bash_profile" ; DFILE="${PSADMIN}/.bash_profile"
    #sadm_writelog "Copying $SFILE to $DFILE"
    #run_oscommand "cp ${SFILE} ${DFILE}"
    #run_oscommand "chmod 775 ${DFILE}"
    #run_oscommand "chown sadmin.sadmin ${DFILE}"
    #    

    return 0                                                            # Return No Error to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$DEBUG_LEVEL" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi

    # Call SADMIN Initialization Procedure
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Del PID
             exit 1                                                     # Exit To O/S with error
    fi

    # MAIN SCRIPT PROCESS HERE ---------------------------------------------------------------------
    ask_user "Do you want to sync Development with Production environment"
    if [ $? -eq 0 ]                                                     # If don't want to Sync       
        then sadm_stop 0                                                # Close log,rch - rm tmp&pid
             exit $SADM_EXIT_CODE                                       # Exit to O/S
    fi

    main_process                                                        # rsync sadmin to psadmin
    SADM_EXIT_CODE=$?
    if [ $SADM_EXIT_CODE -ne 0 ] 
       then sadm_writelog "[ERROR] Something went wrong when syncing with Prod. Environment"
            sadm_writelog "Do not release this version"
       else create_release_file                                                 # Create tgz and md5sum file
            SADM_EXIT_CODE=$?
            if [ $SADM_EXIT_CODE -ne 0 ] 
                then sadm_writelog "[ERROR] Creating tgz file"
                else sadm_writelog " " 
                     sadm_writelog "Copy version file back to $SADM_CFG_DIR"
                     sadm_writelog "cp ${PSADMIN}/cfg/.versum  $SADM_CFG_DIR"
                     cp ${PSADMIN}/cfg/.versum  $SADM_CFG_DIR
                     if [ $? -ne 0 ] ; then sadm_writelog "Error on copy ${PSADMIN}/cfg/.versum" ;fi
                     sadm_writelog "cp ${PSADMIN}/cfg/.version $SADM_CFG_DIR"
                     cp ${PSADMIN}/cfg/.version $SADM_CFG_DIR
                     if [ $? -ne 0 ] ; then sadm_writelog "Error on copy ${PSADMIN}/cfg/.version" ;fi
            fi
    fi 

    SADM_EXIT_CODE=$?                                                   # Save Error Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
