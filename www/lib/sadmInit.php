<?php
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadmInit.php
#   Synopsis :  Initialization File Read when SADMIN Web pages are loaded
#               Set All Common Variable used in SADMIN Web Environment
#   Version  :  1.0 
#   Date     :  14 August 2015
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
# Change Log
# 2017_12_31 web V2.2 Define New Variable loaded from sadmin.cfg 
# 2017_11_11 web V2.1 Switching from PostGres to MySQL
# 2018_01_10 web V2.3 Correct Problem When SADMIN Env. Variable was not pointing to /sadmin  
# 2018_01_25 web V2.4 Add RRD Tools Variable 
# 2018_03_13 web V2.5 Get Root directory of SADMIN from /etc/environment
# 2018_04_02 web V2.6 Get SADMIN Environment Variable from /etc/profile.d/samin.sh now
# 2018_04_04 web V2.8 Message when error while reading sadmin.cfg and sadmin.sh
# 2018_05_04 web V2.9 User/Password for Database access moved from sadmin.cfg to .dbpass file
# 2018_05_28 web V3.0 Added Load Backup Parameters coming from sadmin.cfg now
# 2018_06_10 web V3.1 Change name of O/S Update script 
# 2018_11_22 web v3.2 Read SADMIN root directory from /etc/environment on all platform now.
# 2019_01_11 web v3.3 Definitions of Backup List & Backup Exclude file.
# 2019_02_11 web v3.4 Add $SADMIN/www to PHP Path
# 2019_07_16 web Remove repeating error message when not connecting to Database.
# 2019_08_16 web v3.5 Correct Typo for number of rear backup to keep
# 2019_08_19 web v3.6 Added Global Var. SADM_REAR_EXCLUDE_INIT for Rear Initial Options file.
# 2020_12_26 web v3.7 Added Global Var. SADM_WWW_ARC_DIR for Server archive when deleted.
# 2021_08_02 web v3.8 Added 'SADM_PGM2DOC' for Doc to Links file definition.
# 2021_08_17 web v3.9 Added "SADM_MONITOR_UPDATE_INTERVAL" 
# 2021_09_15 web v3.10 Load new Var. SADM_MONITOR_RECENT_COUNT,SADM_MONITOR_RECENT_EXCLUDE
# 2022_07_26 web v3.11 Set the TimeZone to America/Toronto
# 2023_03_11 web v3.12 Load Rear backup diff & Interval at start, used on Rear Backup status page.
# --------------------------------------------------------------------------------------------------
$DEBUG=False ;  
#
    date_default_timezone_set('America/Toronto');


    # Set SADMIN PHP Library Version NUmber
    define("SADM_PHP_LIBVER","3.12");

    # Setting the HOSTNAME Variable
    list($HOSTNAME) = explode ('.', gethostname());                     # HOSTNAME without domain

    # Check the Existence of SADMIN Environment file (/etc/environment)
    define("SADM_ENV" , "/etc/environment") ;                           # Name O/S Environment file
    if (!is_readable(SADM_ENV)) {                                       # Can't read environment 
        exit ("SADMIN environment file " . SADM_ENV . " wasn't found or not readable") ;
    }
    $handle = fopen(SADM_ENV , "r");                                    # Open O/S Environment file
    if ($handle) {                                                      # If Successfully Open
        while (($line = fgets($handle)) !== false) {                    # If Still Line to read                                                 # Increase Line Number
            #$line = trim($line);
            #if ($DEBUG) { echo "\n<br>line = " . $line . " <br>" ; }
            $pos = strpos($line,'=');
            if ($pos !== false) {
                if (strpos(trim($line),'#') === 0)                      # if 1st Non-WhiteSpace is #
                    { continue; }                                       # Skip comment line
                list($fname,$fvalue) = explode ('=',$line);             # Split Line by Name & Value
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
    if ($DEBUG) { echo  "\n<br>SADMIN DIR = " . SADM_BASE_DIR . " <br>\n" ; }



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
define("SADM_DOC_DIR"      , SADM_BASE_DIR . "/doc");                   # Documentation Directory
define("SADM_CFG_DIR"      , SADM_BASE_DIR . "/cfg");                   # Configuration Directory
define("SADM_SYS_DIR"      , SADM_BASE_DIR . "/sys");                   # System related scripts
define("SADM_DAT_DIR"      , SADM_BASE_DIR . "/dat");                   # Data directory
define("SADM_PKG_DIR"      , SADM_BASE_DIR . "/pkg");                   # Package rpm,deb  directory
define("SADM_NMON_DIR"     , SADM_DAT_DIR  . "/nmon");                  # Where nmon file reside
define("SADM_DR_DIR"       , SADM_DAT_DIR  . "/dr");                    # Disaster Recovery  files
define("SADM_RCH_DIR"      , SADM_DAT_DIR  . "/rch");                   # Result Code History Dir
define("SADM_NET_DIR"      , SADM_DAT_DIR  . "/net");                   # Network SubNet Info Dir
define("SADM_WWW_DIR"      , SADM_BASE_DIR . "/www");                   # Web Site Dir.

# SADMIN WEB SITE DIRECTORIES DEFINITION
define("SADM_WWW_DOC_DIR"  , SADM_WWW_DIR  . "/doc");                   # Web server Doc Dir
define("SADM_WWW_CFG_DIR"  , SADM_WWW_DIR  . "/cfg");                   # Web Server CFG Dir
define("SADM_WWW_DAT_DIR"  , SADM_WWW_DIR  . "/dat");                   # Web Server Data Dir
define("SADM_WWW_ARC_DIR"  , SADM_WWW_DAT_DIR  . "/archive");           # Web Server Archive Dir
define("SADM_WWW_LIB_DIR"  , SADM_WWW_DIR  . "/lib");                   # Web Server Library Dir
define("SADM_WWW_RRD_DIR"  , SADM_WWW_DIR  . "/rrd");                   # Web servers RRD Dir
define("SADM_WWW_TMP_DIR"  , SADM_WWW_DIR  . "/tmp");                   # Web Server Temp Dir
define("SADM_WWW_NET_DIR"  , SADM_WWW_DAT_DIR . "/" .$HOSTNAME. "/net");    # Web net dir
#define("SADM_WWW_TMP_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/tmp");    # Web TMP Dir


# SADMIN FILES DEFINITION
define("SADM_CFG_FILE"            , SADM_CFG_DIR     . "/sadmin.cfg");          # SADMIN Config File
define("SADM_PGM2DOC"             , SADM_WWW_DOC_DIR . "/pgm2doc_link.cfg");    # PGM to Doc link
define("SADM_BACKUP_LIST_INIT"    , SADM_CFG_DIR     . "/.backup_list.txt");    # BackupList Init
define("SADM_BACKUP_EXCLUDE_INIT" , SADM_CFG_DIR     . "/.backup_exclude.txt"); # Backup Exclude Init
define("SADM_REAR_EXCLUDE_INIT"   , SADM_CFG_DIR     . "/.rear_exclude.txt");   # ReaR Exclude Init
define("SADM_ALERT_FILE"          , SADM_CFG_DIR     . "/alert_group.cfg");     # Alert Grp File
define("SADM_DBPASS_FILE"         , SADM_CFG_DIR     . "/.dbpass") ;            # Name Db Usr Pwd
define("SADM_REL_FILE"            , SADM_CFG_DIR     . "/.release") ;           # Name Release File
define("SADM_CRON_FILE"           , SADM_WWW_LIB_DIR . "/.crontab.txt");        # SADM Crontab File
define("SADM_WWW_TMP_FILE1"       , SADM_WWW_TMP_DIR . "www_tmpfile1_" . getmypid() ); # TempFile1
define("SADM_WWW_TMP_FILE2"       , SADM_WWW_TMP_DIR . "www_tmpfile2_" . getmypid() ); # TempFile2
define("SADM_WWW_TMP_FILE3"       , SADM_WWW_TMP_DIR . "www_tmpfile3_" . getmypid() ); # TempFile3
define("SADM_WWW_NETDEV"          , "netdev.txt");                              # NetInterface list



# Check the Existence of SADMIN Environment file (sadmin.cfg)
if (!is_readable(SADM_CFG_FILE)) {
    exit ("The SADMIN configuration file " . SADM_CFG_FILE . " wasn't found or not readable") ;
}

# LOADING CONFIGURATION FILE AND DEFINE GLOBAL SADM ENVIRONMENT VARIABLE
$lineno = 0;                                                            # Clear Line Number
$fname = "" ; $fvalue="" ;
$handle = fopen(SADM_CFG_FILE , "r");                                   # Set Configuration Filename
if ($handle) {                                                          # If Successfully Open
    while (($line = fgets($handle)) !== false) {                        # If Still Line to read
          $lineno++;                                                    # Increase Line Number
          if (empty($line)) { continue; }                               # Skip blank Line
          if (strpos(trim($line),'#') === 0) { continue; }              # Skip comments line
          if (strlen($line) < 10)  { continue; }                        # Skip line less than 10 chr
          if (strpos(trim($line),'=') === false) { continue; }          # Skip Line with no '='
          list($fname,$fvalue) = explode ('=',$line);                   # Split Line by Name & Value
          if ($DEBUG) {
                $long = strlen($line);
                echo "\n<BR>------------\n<br>$lineno $long : $line ";
                echo "\n<BR>The Parameter is : " . $fname ;
                echo "\n<BR>The Value is     : " . $fvalue ;
          }
          if (trim($fname) == "SADM_MAIL_ADDR")     { define("SADM_MAIL_ADDR"     , trim($fvalue));}
          if (trim($fname) == "SADM_ALERT_TYPE")    { define("SADM_ALERT_TYPE"    , trim($fvalue));}
          if (trim($fname) == "SADM_CIE_NAME")      { define("SADM_CIE_NAME"      , trim($fvalue));}
          if (trim($fname) == "SADM_USER")          { define("SADM_USER"          , trim($fvalue));}
          if (trim($fname) == "SADM_GROUP")         { define("SADM_GROUP"         , trim($fvalue));}
          if (trim($fname) == "SADM_WWW_USER")      { define("SADM_WWW_USER"      , trim($fvalue));}
          if (trim($fname) == "SADM_WWW_GROUP")     { define("SADM_WWW_GROUP"     , trim($fvalue));}
          if (trim($fname) == "SADM_MAX_LOGLINE")   { define("SADM_MAX_LOGLINE"   , trim($fvalue));}
          if (trim($fname) == "SADM_MAX_RCHLINE")   { define("SADM_MAX_RCHLINE"   , trim($fvalue));}
          if (trim($fname) == "SADM_NMON_KEEPDAYS") { define("SADM_NMON_KEEPDAYS" , trim($fvalue));}
          if (trim($fname) == "SADM_RCH_KEEPDAYS")  { define("SADM_RCH_KEEPDAYS"  , trim($fvalue));}
          if (trim($fname) == "SADM_LOG_KEEPDAYS")  { define("SADM_LOG_KEEPDAYS"  , trim($fvalue));}
          if (trim($fname) == "SADM_DBNAME")        { define("SADM_DBNAME"        , trim($fvalue));}
          if (trim($fname) == "SADM_DBHOST")        { define("SADM_DBHOST"        , trim($fvalue));}
          if (trim($fname) == "SADM_DBPORT")        { define("SADM_DBPORT"        , trim($fvalue));}
          if (trim($fname) == "SADM_SERVER")        { define("SADM_SERVER"        , trim($fvalue));}
          if (trim($fname) == "SADM_DOMAIN")        { define("SADM_DOMAIN"        , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK1")      { define("SADM_NETWORK1"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK2")      { define("SADM_NETWORK2"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK3")      { define("SADM_NETWORK3"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK4")      { define("SADM_NETWORK4"      , trim($fvalue));}
          if (trim($fname) == "SADM_NETWORK5")      { define("SADM_NETWORK5"      , trim($fvalue));}
          if (trim($fname) == "SADM_SSH_PORT")      { define("SADM_SSH_PORT"      , trim($fvalue));}
          if (trim($fname) == "SADM_BACKUP_NFS_SERVER")      { define("SADM_BACKUP_NFS_SERVER"      , trim($fvalue));}
          if (trim($fname) == "SADM_BACKUP_NFS_MOUNT_POINT") { define("SADM_BACKUP_NFS_MOUNT_POINT" , trim($fvalue));}
          if (trim($fname) == "SADM_DAILY_BACKUP_TO_KEEP")   { define("SADM_DAILY_BACKUP_TO_KEEP"   , trim($fvalue));}
          if (trim($fname) == "SADM_WEEKLY_BACKUP_TO_KEEP")  { define("SADM_WEEKLY_BACKUP_TO_KEEP"  , trim($fvalue));}
          if (trim($fname) == "SADM_MONTHLY_BACKUP_TO_KEEP") { define("SADM_MONTHLY_BACKUP_TO_KEEP" , trim($fvalue));}
          if (trim($fname) == "SADM_YEARLY_BACKUP_TO_KEEP")  { define("SADM_YEARLY_BACKUP_TO_KEEP"  , trim($fvalue));}
          if (trim($fname) == "SADM_WEEKLY_BACKUP_DAY")      { define("SADM_WEEKLY_BACKUP_DAY"      , trim($fvalue));}
          if (trim($fname) == "SADM_MONTHLY_BACKUP_DATE")    { define("SADM_MONTHLY_BACKUP_DATE"    , trim($fvalue));}
          if (trim($fname) == "SADM_YEARLY_BACKUP_MONTH")    { define("SADM_YEARLY_BACKUP_MONTH"    , trim($fvalue));}
          if (trim($fname) == "SADM_YEARLY_BACKUP_DATE")     { define("SADM_YEARLY_BACKUP_DATE"     , trim($fvalue));}
          if (trim($fname) == "SADM_BACKUP_DIF")             { define("SADM_BACKUP_DIF"             , trim($fvalue));}
          if (trim($fname) == "SADM_BACKUP_INTERVAL")        { define("SADM_BACKUP_INTERVAL"        , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_NFS_SERVER")        { define("SADM_REAR_NFS_SERVER"        , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_NFS_MOUNT_POINT")   { define("SADM_REAR_NFS_MOUNT_POINT"   , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_BACKUP_TO_KEEP")    { define("SADM_REAR_BACKUP_TO_KEEP"    , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_BACKUP_DIF")        { define("SADM_REAR_BACKUP_DIF"        , trim($fvalue));}
          if (trim($fname) == "SADM_REAR_BACKUP_INTERVAL")   { define("SADM_REAR_BACKUP_INTERVAL"   , trim($fvalue));}
          if (trim($fname) == "SADM_MONITOR_UPDATE_INTERVAL") {define("SADM_MONITOR_UPDATE_INTERVAL", trim($fvalue));}
          if (trim($fname) == "SADM_MONITOR_RECENT_COUNT")   { define("SADM_MONITOR_RECENT_COUNT"   , trim($fvalue));}
          if (trim($fname) == "SADM_MONITOR_RECENT_EXCLUDE") { define("SADM_MONITOR_RECENT_EXCLUDE" , trim($fvalue));}
          if (trim($fname) == "SADM_VM_EXPORT_NFS_SERVER")   { define("SADM_VM_EXPORT_NFS_SERVER"   , trim($fvalue));}
          if (trim($fname) == "SADM_VM_EXPORT_MOUNT_POINT")  { define("SADM_VM_EXPORT_MOUNT_POINT"  , trim($fvalue));}
          if (trim($fname) == "SADM_VM_EXPORT_TO_KEEP")      { define("SADM_VM_EXPORT_TO_KEEP"      , trim($fvalue));}
          if (trim($fname) == "SADM_VM_EXPORT_INTERVAL")     { define("SADM_VM_EXPORT_INTERVAL"     , trim($fvalue));}
          if (trim($fname) == "SADM_VM_EXPORT_ALERT")        { define("SADM_VM_EXPORT_ALERT"        , trim($fvalue));}
          if (trim($fname) == "SADM_VM_USER")                { define("SADM_VM_USER"                , trim($fvalue));}
          if (trim($fname) == "SADM_VM_STOP_TIMEOUT")        { define("SADM_VM_STOP_TIMEOUT"        , trim($fvalue));}
          if (trim($fname) == "SADM_VM_START_INTERVAL")      { define("SADM_VM_START_INTERVAL"      , trim($fvalue));}
          if (trim($fname) == "SADM_VM_EXPORT_DIF")          { define("SADM_VM_EXPORT_DIF"          , trim($fvalue));}
    }
    if (! defined('SADM_MONITOR_RECENT_COUNT'))    {define("SADM_MONITOR_RECENT_COUNT" , 10);}
    if (! defined('SADM_MONITOR_UPDATE_INTERVAL')) {define("SADM_MONITOR_UPDATE_INTERVAL", 60);}
    if (! defined('SADM_MONITOR_RECENT_EXCLUDE'))  {define("SADM_MONITOR_RECENT_EXCLUDE", "sadm_nmon_watcher");}
    define ("SADM_RRDTOOL" , '/usr/bin/rrdtool') ;
    fclose($handle);
} else {
    echo "<BR>\nError opening the SADMIN configuration file " . SADM_CFG_FILE . "<BR>";
}

# Check the Existence of Alert Group File ($SADMIN/cfg/alert_group.cfg) ----------------------------
if (!is_readable(SADM_ALERT_FILE)) {
    exit ("The Alert Group File " . SADM_ALERT_FILE . " wasn't found or not readable") ;
}


# Get SADMIN Tool release number form the .release file --------------------------------------------
    if (file_exists(SADM_REL_FILE)) {                                 # If Release file exist
        $f = fopen(SADM_REL_FILE, 'r');                         # Open Release FIle
        $release = fgets($f);                                           # Read Rel No. from File
        fclose($f);                                                     # Close .release file
        define("SADM_VERSION" , trim($release));  # Create Var. from Release
    }else{
        define("SADM_VERSION" , "00.00");         # Default if File Not Exist
        echo "<BR>\nRelease file is missing " . SADM_REL_FILE ;         # Error Mess. - File Missing
    }

# Get 'sadmin' and 'squery' password from .dbpass file ---------------------------------------------
    define("SADM_RW_DBUSER" , 'sadmin');                                # DB Read/Write User Name
    $sadmin_pwd = "";                                                   # DB Read/Write Default Pwd 
    define("SADM_RO_DBUSER" , 'squery');                                # DB Read Only User
    $squery_pwd = "";                                                   # DB Read Only Default Pwd
    if (file_exists(SADM_DBPASS_FILE)) {                                # If .dbpass file exist
        $file = fopen(SADM_DBPASS_FILE, "r") or exit ("Unable to open " .SADM_DBPASS_FILE. " file, check permission.");
        while(!feof($file)) {                                           # Read File Until EndOfFile
            $line = trim(fgets($file));                                 # Read Line and trim it
            if ((strpos(trim($line),'#') === 0) or (strlen($line) < 2)) # If 1st Non-WhiteSpace is #
                continue;                                               # Go Read the next line
            $strpos = strpos($line,'sadmin,');                          # Get Pos of 'sadmin,'
            if ($strpos !== False) {                                    # If at beginning of line OK
                list($fuser,$fpwd) = explode (',',$line);               # Split Line User,Password
                $sadmin_pwd = $fpwd;                                    # Save sadmin user password
                continue;
            }
            $strpos = strpos($line,'squery,');                          # Get Pos of 'squery,'
            if ($strpos !== False) {                                    # If at beginning of line OK
                list($fuser,$fpwd) = explode (',',$line);               # Split Line User,Password
                $squery_pwd = $fpwd;                                    # Save squery user password
                continue;
            }
        }
        fclose($file);                                                  # Close Database Passwd file
        define("SADM_RW_DBPWD"  , $sadmin_pwd);                         # DB Read/Write Password
        define("SADM_RO_DBPWD"  , $squery_pwd);                         # DB Read Only Password
    }else{
        echo "<BR>\nDatabase password file missing " .SADM_DBPASS_FILE; # Error Mess. - File Missing
    }
     # ADD Web site root and Library Directory to search path
    #echo ini_get('include_path');
    set_include_path(get_include_path() . PATH_SEPARATOR . SADM_WWW_DIR);
    set_include_path(get_include_path() . PATH_SEPARATOR . SADM_WWW_LIB_DIR);
    #echo ini_get('include_path');

    # Connect to MySQL DataBase
    if ($DEBUG) { 
        echo "\n<br>SADM_RW_DBUSER = ..." . SADM_RW_DBUSER  ."...";
        echo "\n<br>SADM_RW_DBPWD  = ..." . SADM_RW_DBPWD   ."...";
        echo "\n<br>SADM_RO_DBUSER = ..." . SADM_RO_DBUSER  ."...";
        echo "\n<br>SADM_RO_DBPWD  = ..." . SADM_RO_DBPWD   ."...";
        echo "\n<br>SADM_DBHOST    = ..." . SADM_DBHOST     ."...";
        echo "\n<br>SADM_DBNAME    = ..." . SADM_DBNAME     ."...";
    }
    $con = mysqli_connect(SADM_DBHOST,SADM_RW_DBUSER,SADM_RW_DBPWD,SADM_DBNAME);
    if (mysqli_connect_errno()) {                                   # Check if Error Connecting
        echo "<BR>\n>>>>> Failed to connect to MySQL Database: '" . SADM_DBNAME . "'";
        echo "<BR>\n>>>>> Error (" . mysqli_connect_error() . ") " . "'<br/>";
    }
?>
