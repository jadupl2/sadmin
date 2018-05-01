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
# 2017_04_20 JDuplessis 
#   V1.0 - Initial Version
# 2017_04_20 JDuplessis 
#   V1.2 - First Production Release
# 2017_04_24 JDuplessis 
#   V1.3 - Exclude __pycache__ file from update - Setup msg Directory Added
# 2017_05_01 JDuplessis 
#   V1.4 - Test if not root at beginning
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.3'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#




#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
PSADMIN="/psadmin"                          ; export PSADMIN            # Prod. SADMIN Root Dir.
PSBIN="${PSADMIN}/bin"                      ; export PSBIN              # Prod. bin Directory
PSCFG="${PSADMIN}/cfg"                      ; export PSCFG              # Prod. cfg Directory
#
REL=`cat /sadmin/cfg/.release`              ; export REL                # Save Release Number
EPOCH=`date +%s`                            ; export EPOCH              # Current EPOCH Time
#


#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
#===================================================================================================
help()
{
    echo " "
    echo "${SADM_PN} usage :"
    echo "             -d   (Debug Level [0-9])"
    echo "             -h   (Display this help message)"
    echo " "
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
    REL=`cat /sadmin/cfg/.release`                   ; export REL       # Save Release Number
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
    if [ "`pwd`" != "/psadmin" ]
       then sadm_writelog "Could not cd to ${PSADMIN}, please check that - Abort Process" 
            return 1
    fi
    sadm_writelog "Currently in `pwd` directory"
    sadm_writelog "rm -fr ${PSADMIN} > /dev/null 2>&1"
    rm -fr ${PSADMIN} > /dev/null 2>&1

    # Create SADMIN Directories arborescence
    create_dir "bin"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "pkg"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "tmp"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "sys"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "lib"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "log"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "cfg"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "setup"      ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "setup/etc"  ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "setup/msg"  ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "setup/bin"  ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "setup/log"  ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/tmp"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/rrd"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/dat"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/crud"   ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/css"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/doc"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/icons"  ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/images" ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/js"     ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/lib"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "www/view"   ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "dat"        ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "dat/dbb"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "dat/dr"     ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "dat/net"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "dat/nmon"   ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "dat/rch"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi
    create_dir "dat/rpt"    ; if [ $? -ne 0 ] ; then sadm_writelog "Program Aborted" ; fi


    # Rsync Script Directory -----------------------------------------------------------------------
    sadm_writelog " "
    SDIR="${SADMIN}/bin" ; DDIR="${PSADMIN}/bin"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform USer
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group

    # Rsync Package Directories --------------------------------------------------------------------
    sadm_writelog " "
    SDIR="${SADMIN}/pkg" ; DDIR="${PSADMIN}/pkg"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group

    # Rsync Library Directories --------------------------------------------------------------------
    sadm_writelog " "
    SDIR="${SADMIN}/lib" ; DDIR="${PSADMIN}/lib"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group

    # Rsync Setup Directories ----------------------------------------------------------------------
    sadm_writelog " "
    SDIR="${SADMIN}/setup/bin" ; DDIR="${PSADMIN}/setup/bin"            # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    sadm_writelog " "
    SDIR="${SADMIN}/setup/etc" ; DDIR="${PSADMIN}/setup/etc"            # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    sadm_writelog " "
    SDIR="${SADMIN}/setup/msg" ; DDIR="${PSADMIN}/setup/msg"            # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SFILE="${SADMIN}/setup/setup.sh" ; DFILE="${PSADMIN}/setup/setup.sh"
    sadm_writelog "Copying $SFILE to $DFILE"
    run_oscommand "cp ${SFILE} ${DFILE}"
    run_oscommand "chmod 775 ${DFILE}"
    run_oscommand "chown sadmin.sadmin ${DFILE}"
    #    

    # Rsync System Directories ---------------------------------------------------------------------
    sadm_writelog " "
    SDIR="${SADMIN}/sys" ; DDIR="${PSADMIN}/sys"                        # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group

    # Rsync Web Directories ------------------------------------------------------------------------
    sadm_writelog " "
    SDIR="${SADMIN}/www/crud" ; DDIR="${PSADMIN}/www/crud"              # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SDIR="${SADMIN}/www/css" ; DDIR="${PSADMIN}/www/css"                # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SDIR="${SADMIN}/www/icons" ; DDIR="${PSADMIN}/www/icons"            # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 644 ${DDIR}/*"                              # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SDIR="${SADMIN}/www/images" ; DDIR="${PSADMIN}/www/images"          # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 644 ${DDIR}/*"                              # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SDIR="${SADMIN}/www/js" ; DDIR="${PSADMIN}/www/js"                  # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SDIR="${SADMIN}/www/lib" ; DDIR="${PSADMIN}/www/lib"                # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SDIR="${SADMIN}/www/view" ; DDIR="${PSADMIN}/www/view"              # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 775 ${DDIR}"                                # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    SDIR="${SADMIN}/www/doc" ; DDIR="${PSADMIN}/www/doc"                # Source & Destination Dir.
    sadm_writelog "Syncing directory ${SDIR} to ${DDIR}"                # Inform User
    run_oscommand "rsync -ar --delete ${SDIR}/ ${DDIR}/"                # RSync Source/Dest. Dir.
    run_oscommand "chmod -R 644 ${DDIR}/*"                              # Change Permission
    run_oscommand "chown -R sadmin.sadmin ${DDIR}"                      # Change Owner and Group
    #
    sadm_writelog " "
    SFILE="${SADMIN}/www/index.php" ; DFILE="${PSADMIN}/www/index.php"
    sadm_writelog "Copying $SFILE to $DFILE"
    run_oscommand "cp ${SFILE} ${DFILE}"
    run_oscommand "chmod 644 ${DFILE}"
    run_oscommand "chown sadmin.sadmin ${DFILE}"
    #    

    # COPY $SADMIN/cfg to /psadmin/cfg -------------------------------------------------------------
    sadm_writelog " "
    sadm_writelog "Syncing cfg directory ${SADMIN}/cfg to ${PSCFG}"
    run_oscommand "cp ${SADMIN}/cfg/.dbpass ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.dbpass"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.dbpass"
    #
    run_oscommand "cp ${SADMIN}/cfg/.release ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.release"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.release"
    #
    run_oscommand "cp ${SADMIN}/cfg/.sadmin.cfg ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.sadmin.cfg"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.sadmin.cfg"
    #
    run_oscommand "cp ${SADMIN}/cfg/.template.smon ${PSCFG}"
    run_oscommand "chmod 644 ${PSCFG}/.template.smon"
    run_oscommand "chown sadmin.sadmin ${PSCFG}/.template.smon"

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
    #

    # COPY .bashrc and .bash_profile file-----------------------------------------------------------
    #
    sadm_writelog " "
    SFILE="${SADMIN}/.bashrc" ; DFILE="${PSADMIN}/.bashrc"
    sadm_writelog "Copying $SFILE to $DFILE"
    run_oscommand "cp ${SFILE} ${DFILE}"
    run_oscommand "chmod 775 ${DFILE}"
    run_oscommand "chown sadmin.sadmin ${DFILE}"
    #    
    sadm_writelog " "
    SFILE="${SADMIN}/.bash_profile" ; DFILE="${PSADMIN}/.bash_profile"
    sadm_writelog "Copying $SFILE to $DFILE"
    run_oscommand "cp ${SFILE} ${DFILE}"
    run_oscommand "chmod 775 ${DFILE}"
    run_oscommand "chown sadmin.sadmin ${DFILE}"
    #    

    return 0                                                            # Return No Error to Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then echo  "Script can only be run user 'root'"         # Advise User should be root
             echo  "Process aborted"                            # Abort advise message
             exit 1                                                     # Exit To O/S
    fi

    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN Server
        then sadm_writelog "Script only run on SADMIN system (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi


    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9]) ---------------------------------
    while getopts "hd:" opt ; do                                        # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            h) help_usage                                               # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell
               ;;
           \?) sadm_writelog "Invalid option: -$OPTARG"                 # Invalid Option Message
               help_usage                                               # Display Help Usage
               sadm_stop 1                                              # Close the shop
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ]                                           # If Debug is Activated
        then sadm_writelog "Debug activated, Level ${DEBUG_LEVEL}"      # Display Debug Level
    fi

    # MAIN SCRIPT PROCESS HERE ---------------------------------------------------------------------
    ask_user "Do you want to create production environment"
    if [ $? -eq 1 ]
        then main_process                                               # Upd./psadmin with latest
             create_release_file                                        # Create tgz and txt file
             SADM_EXIT_CODE=$?
             if [ $SADM_EXIT_CODE -ne 0 ] ; then sadm_writelog "[ERROR] Creating tgz file" ; fi
    fi
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
