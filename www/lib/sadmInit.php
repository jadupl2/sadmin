<?php
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadmInit.php
#   Synopsis :  Initialization File Read when SADMIN Web pages are loaded
#               Set All Common Variable used in SADMIN Web Environment
#   Version  :  1.0 
#   Date     :  14 August 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) template.sh 1.0 2015/08/14
# --------------------------------------------------------------------------------------------------
# Change Log
#   2017_11_111 JDuplessis
#       V2.1 Switching from PostGres to MySQL
#   2017_12_31 JDuplessis
#       V2.2 Define New Variable loaded from sadmin.cfg 
#   2018_01_10 JDuplessis
#       V2.3 Correct Problem When SADMIN Env. Variable was not pointing to /sadmin  
#   2018_01_25 JDuplessis
#       V2.4 Add RRD Tools Variable 
#   2018_03_13 JDuplessis
#       V2.5 Get Root directory of SADMIN from /etc/environment
#   2018_04_02 JDuplessis
#       V2.6 Get SADMIN Environment Variable from /etc/profile.d/samin.sh now
#   2018_04_04 JDuplessis
#       V2.8 Message when error while reading sadmin.cfg and sadmin.sh
# --------------------------------------------------------------------------------------------------
$DEBUG=False ;  
#

# Setting the HOSTNAME Variable
list($HOSTNAME) = explode ('.', gethostname());                         # HOSTNAME without domain

# GET THE SADMIN ENVIRONMENT VARIABLE CONTENT FROM /ETC/PROFILE.D/SADMIN.SH
define("SADM_ENV" , "/etc/profile.d/sadmin.sh") ;                       # Name of O/S Environment file

# Check the Existence of SADMIN Environment file (/etc/profile.d/sadmin.sh)
if (!is_readable(SADM_ENV)) {
    exit ("The SADMIN environment file " . SADM_ENV . " wasn't found or not readable") ;
}

$handle = fopen(SADM_ENV , "r");                                        # Open O/S Environment file
if ($handle) {                                                          # If Successfully Open
    while (($line = fgets($handle)) !== false) {                        # If Still Line to read                                                 # Increase Line Number
        #$line = trim($line);
        #if ($DEBUG) { echo "\n<br>line = " . $line . " <br>" ; }
        $pos = strpos($line,'=');
        if ($pos !== false) {
            if (strpos(trim($line),'#') === 0)                          # if 1st Non-WhiteSpace is #
                { continue; }                                           # Skip comment line
            list($fname,$fvalue) = explode ('=',$line);                 # Split Line by Name & Value
            if ($DEBUG) { echo "\n<br>fname = " . $fname .   " Trim = " . trim($fname) . "<br>" ; }
            if ($DEBUG) { echo "\n<br>fvalue = " . $fvalue . " Trim = " . trim($fvalue) . "<br>" ; }
            if (trim($fname) == "SADMIN")        { define("SADM_BASE_DIR", trim($fvalue)); }
            if (trim($fname) == "export SADMIN") { define("SADM_BASE_DIR", trim($fvalue)); }
        }
    }
    fclose($handle);
}else{
    exit ("Error opening the SADMIN Environment file " . SADM_ENV) ;
}
if ($DEBUG) { 
    exit ("\n<br>SADMIN DIR = " . SADM_BASE_DIR . " <br>\n") ;
}


#
# Validate SADM_BASE_DIR by checking the existence of the lib directory in that Directory
$LIBDIR=SADM_BASE_DIR . "/lib";
if (!is_dir($LIBDIR)) {
    exit("SADMIN environment variable in " .SADM_ENV. " isn't set correctly (" .SADM_BASE_DIR.")");
}

# SET SADMIN ROOT BASE DIRECTORY
#$TMPVAR = getenv('SADMIN');                                             # Get SADMIN Env. Variable
#if (strlen($TMPVAR) != 0 ) {                                            # If Was Defined
#     define("SADM_BASE_DIR",$TMPVAR);                                   # Set SADMIN_BASE_DIR to Env
#}else{                                                                  # If SADMIN Not Defined        
#     define("SADM_BASE_DIR", "/sadmin");                                # Default SADM Root Base Dir 
#}  

# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
define("SADM_BIN_DIR"      , SADM_BASE_DIR . "/bin");                   # Script Root binary Dir.
define("SADM_TMP_DIR"      , SADM_BASE_DIR . "/tmp");                   # Script Temp  directory
define("SADM_LIB_DIR"      , SADM_BASE_DIR . "/lib");                   # Script Lib directory
define("SADM_LOG_DIR"      , SADM_BASE_DIR . "/log");                   # Script log directory
define("SADM_CFG_DIR"      , SADM_BASE_DIR . "/cfg");                   # Configuration Directory
define("SADM_SYS_DIR"      , SADM_BASE_DIR . "/sys");                   # System related scripts
define("SADM_DAT_DIR"      , SADM_BASE_DIR . "/dat");                   # Data directory
define("SADM_PKG_DIR"      , SADM_BASE_DIR . "/pkg");                   # Package rpm,deb  directory
define("SADM_NMON_DIR"     , SADM_DAT_DIR  . "/nmon");                  # Where nmon file reside
define("SADM_DR_DIR"       , SADM_DAT_DIR  . "/dr");                    # Disaster Recovery  files
define("SADM_SAR_DIR"      , SADM_DAT_DIR  . "/sar");                   # System Activty Report Dir
define("SADM_RCH_DIR"      , SADM_DAT_DIR  . "/rch");                   # Result Code History Dir
define("SADM_NET_DIR"      , SADM_DAT_DIR  . "/net");                   # Network SubNet Info Dir
define("SADM_WWW_DIR"      , SADM_BASE_DIR . "/www");                   # Web Site Dir.

# SADMIN WEB SITE DIRECTORIES DEFINITION
define("SADM_WWW_DOC_DIR"  , SADM_WWW_DIR  . "/doc");                   # Web server Doc Dir
define("SADM_WWW_CFG_DIR"  , SADM_WWW_DIR  . "/cfg");                   # Web Server CFG Dir
define("SADM_WWW_DAT_DIR"  , SADM_WWW_DIR  . "/dat");                   # Web Server Data Dir
define("SADM_WWW_LIB_DIR"  , SADM_WWW_DIR  . "/lib");                   # Web Server Library Dir
define("SADM_WWW_RRD_DIR"  , SADM_WWW_DIR  . "/rrd");                   # Web servers RRD Dir
define("SADM_WWW_TMP_DIR"  , SADM_WWW_DIR  . "/tmp");                   # Web Server Temp Dir
define("SADM_WWW_RCH_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/rch");    # Web rch dir
define("SADM_WWW_SAR_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/sar");    # Web sar dir
define("SADM_WWW_NET_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/net");    # Web net dir
define("SADM_WWW_DR_DIR"   , SADM_WWW_DAT_DIR . "/${HOSTNAME}/dr");     # Web Disaster Recovery Dir
define("SADM_WWW_NMON_DIR" , SADM_WWW_DAT_DIR . "/${HOSTNAME}/nmon");   # Web nmon Dir
#define("SADM_WWW_TMP_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/tmp");    # Web TMP Dir
define("SADM_WWW_LOG_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/log");    # Web LOG Dir


# SADMIN FILES DEFINITION
define("SADM_CFG_FILE"     , SADM_CFG_DIR . "/sadmin.cfg");             # SADM Config File
define("SADM_CRON_FILE"    , SADM_WWW_CFG_DIR . "/.crontab.txt");       # SADM Crontab File
define("SADM_WWW_TMP_FILE1", SADM_WWW_TMP_DIR . "www_tmpfile1_" . getmypid() ); # SADM Temp File1
define("SADM_WWW_TMP_FILE2", SADM_WWW_TMP_DIR . "www_tmpfile2_" . getmypid() ); # SADM Temp File1
define("SADM_WWW_TMP_FILE3", SADM_WWW_TMP_DIR . "www_tmpfile3_" . getmypid() ); # SADM Temp File1
define("SADM_WWW_NETDEV"   , "netdev.txt");                             # File Network Interface lst

#
define("SADM_UPDATE_SCRIPT", "sadm_osupdate_server.sh -s ");            # O/S Update Script Name


# Check the Existence of SADMIN Environment file (/etc/profile.d/sadmin.sh)
if (!is_readable(SADM_CFG_FILE)) {
    exit ("The SADMIN configuration file " . SADM_CFG_FILE . " wasn't found or not readable") ;
}

# LOADING CONFIGURATION FILE AND DEFINE GLOBAL SADM ENVIRONMENT VARIABLE
$lineno = 0;                                                            # Clear Line Number
$handle = fopen(SADM_CFG_FILE , "r");                                   # Set Configuration Filename
if ($handle) {                                                          # If Successfully Open
    while (($line = fgets($handle)) !== false) {                        # If Still Line to read
          $lineno++;                                                    # Increase Line Number
          if ($DEBUG) {
            $long = strlen($line);
            echo "\n<BR>$lineno : $line - $long ";
          }
          if ((strpos(trim($line),'#') === 0) or (strlen($line) < 2)) # If 1st Non-WhiteSpace is #
             continue;                                                  # Go Read the next line
          list($fname,$fvalue) = explode ('=',$line);                   # Split Line by Name & Value
          if ($DEBUG) {
                $long = strlen($line);
                echo "\n<BR>$lineno : $line - $long ";
                echo "\n<BR>The Parameter is : " . $fname ;
                echo "\n<BR>The Value is     : " . $fvalue ;
          }
          if (trim($fname) == "SADM_MAIL_ADDR")     { define("SADM_MAIL_ADDR"     , trim($fvalue));}
          if (trim($fname) == "SADM_MAIL_TYPE")     { define("SADM_MAIL_TYPE"     , trim($fvalue));}
          if (trim($fname) == "SADM_CIE_NAME")      { define("SADM_CIE_NAME"      , trim($fvalue));}
          if (trim($fname) == "SADM_USER")          { define("SADM_USER"          , trim($fvalue));}
          if (trim($fname) == "SADM_GROUP")         { define("SADM_GROUP"         , trim($fvalue));}
          if (trim($fname) == "SADM_WWW_USER")      { define("SADM_WWW_USER"      , trim($fvalue));}
          if (trim($fname) == "SADM_WWW_GROUP")     { define("SADM_WWW_GROUP"     , trim($fvalue));}
          if (trim($fname) == "SADM_MAX_LOGLINE")   { define("SADM_MAX_LOGLINE"   , trim($fvalue));}
          if (trim($fname) == "SADM_MAX_RCHLINE")   { define("SADM_MAX_RCHLINE"   , trim($fvalue));}
          if (trim($fname) == "SADM_NMON_KEEPDAYS") { define("SADM_NMON_KEEPDAYS" , trim($fvalue));}
          if (trim($fname) == "SADM_SAR_KEEPDAYS")  { define("SADM_SAR_KEEPDAYS"  , trim($fvalue));}
          if (trim($fname) == "SADM_RCH_KEEPDAYS")  { define("SADM_RCH_KEEPDAYS"  , trim($fvalue));}
          if (trim($fname) == "SADM_LOG_KEEPDAYS")  { define("SADM_LOG_KEEPDAYS"  , trim($fvalue));}
          if (trim($fname) == "SADM_DBNAME")        { define("SADM_DBNAME"        , trim($fvalue));}
          if (trim($fname) == "SADM_DBDIR")         { define("SADM_DBDIR"         , trim($fvalue));}
          if (trim($fname) == "SADM_DBHOST")        { define("SADM_DBHOST"        , trim($fvalue));}
          if (trim($fname) == "SADM_DBPORT")        { define("SADM_DBPORT"        , trim($fvalue));}
          if (trim($fname) == "SADM_RW_DBUSER")     { define("SADM_RW_DBUSER"     , trim($fvalue));}
          if (trim($fname) == "SADM_RW_DBPWD")      { define("SADM_RW_DBPWD"      , trim($fvalue));}
          if (trim($fname) == "SADM_RO_DBUSER")     { define("SADM_RO_DBUSER"     , trim($fvalue));}
          if (trim($fname) == "SADM_RO_DBPWD")      { define("SADM_RO_DBPWD"      , trim($fvalue));}
          if (trim($fname) == "SADM_SERVER")        { define("SADM_SERVER"        , trim($fvalue));}
          if (trim($fname) == "SADM_DOMAIN")        { define("SADM_DOMAIN"        , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK1")      { define("SADM_NETWORK1"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK2")      { define("SADM_NETWORK2"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK3")      { define("SADM_NETWORK3"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK4")      { define("SADM_NETWORK4"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK5")      { define("SADM_NETWORK5"      , trim($fvalue));}
          if (trim($fname) == "SADM_SSH_PORT")      { define("SADM_SSH_PORT"      , trim($fvalue));}
          if (trim($fname) == "SADM_RRDTOOL")       { define("SADM_RRDTOOL"       , trim($fvalue));}
          if (trim($fname) == "SADM_BACKUP_NFS_SERVER")      { define("SADM_BACKUP_NFS_SERVER"      , trim($fvalue));}
          if (trim($fname) == "SADM_BACKUP_NFS_MOUNT_POINT") { define("SADM_BACKUP_NFS_MOUNT_POINT" , trim($fvalue));}
          if (trim($fname) == "SADM_BACKUP_NFS_TO_KEEP")     { define("SADM_BACKUP_NFS_TO_KEEP"     , trim($fvalue));}
          if (trim($fname) == "SADM_MKSYSB_NFS_SERVER")      { define("SADM_MKSYSB_NFS_SERVER"      , trim($fvalue));}
          if (trim($fname) == "SADM_MKSYSB_NFS_MOUNT_POINT") { define("SADM_MKSYSB_NFS_MOUNT_POINT" , trim($fvalue));}
          if (trim($fname) == "SADM_MKSYSB_NFS_TO_KEEP")     { define("SADM_MKSYSB_NFS_TO_KEEP"     , trim($fvalue));}
          if (trim($fname) == "SADM_STORIX_NFS_SERVER")      { define("SADM_STORIX_NFS_SERVER"      , trim($fvalue));}
          if (trim($fname) == "SADM_STORIX_NFS_MOUNT_POINT") { define("SADM_STORIX_NFS_MOUNT_POINT" , trim($fvalue));}
          if (trim($fname) == "SADM_STORIX_NFS_TO_KEEP")     { define("SADM_STORIX_NFS_TO_KEEP"     , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_NFS_SERVER")        { define("SADM_REAR_NFS_SERVER"        , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_NFS_MOUNT_POINT")   { define("SADM_REAR_NFS_MOUNT_POINT"   , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_NFS_TO_KEEP")       { define("SADM_REAR_NFS_TO_KEEP"       , trim($fvalue));}
    }
    fclose($handle);
} else {
    echo "<BR>\nError opening the SADMIN configuration file " . SADM_CFG_FILE . "<BR>";
}


# GET THE SADMIN RELEASE NUMBER FORM THE .RELEASE FILE
define("SADM_REL_FILE" , SADM_CFG_DIR . "/.release") ;                  # Name of the Release File
if (file_exists(SADM_REL_FILE)) {                                       # If Release file exist
    $f = fopen(SADM_REL_FILE, 'r');                                     # Open Release FIle
    $release = fgets($f);                                               # Read Rel No. from File
    fclose($f);                                                         # Close .release file
    define("SADM_VERSION" , trim($release));                            # Create Var. from Release
}else{
    define("SADM_VERSION" , "00.00");                                   # Default if File Not Exist
    echo "<BR>\nRelease file is missing " . SADM_REL_FILE ;             # Error Mess. - File Missing
}


# ADD PHP LIBRARY DIRECTORY TO PATH
//echo ini_get('include_path');
set_include_path(get_include_path() . PATH_SEPARATOR . SADM_WWW_LIB_DIR);
//echo ini_get('include_path');

# Connect to MySQL DataBase
$con = mysqli_connect(SADM_DBHOST,SADM_RW_DBUSER,SADM_RW_DBPWD,SADM_DBNAME);
if (mysqli_connect_errno())                                             # Check if Error Connecting
{
  echo "<BR>\n>>>>> Failed to connect to MySQL Database: '" . SADM_DBNAME . "'";
  echo "<BR>\n>>>>> Error (" . mysqli_connect_errno() . ") " . mysqli_connect_error() . "'<br/>";
}
?>
