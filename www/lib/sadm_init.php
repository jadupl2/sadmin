<?php
# V2.0 Now Switching from PostGres to SQLite3 (To Simplify installation and ease of use)



# Setting the HOSTNAME Variable
list($HOSTNAME) = explode ('.', gethostname());                         # HOSTNAME without domain


# SET SADMIN ROOT BASE DIRECTORY
define("SADM_BASE_DIR"     , "/sadmin");                                # Default SADM Root Base Dir
$TMPVAR = getenv('SADMIN');                                             # Get Env. SADMIN Variable
if (strlen($TMPVAR) != 0 ) { define("SADM_BASE_DIR",$TMPVAR); }         # Use Env. SADMIN Var Base


# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
define("SADM_BIN_DIR"      , SADM_BASE_DIR . "/bin");                   # Script Root binary Dir.
define("SADM_TMP_DIR"      , SADM_BASE_DIR . "/tmp");                   # Script Temp  directory
define("SADM_LIB_DIR"      , SADM_BASE_DIR . "/lib");                   # Script Lib directory
define("SADM_LOG_DIR"      , SADM_BASE_DIR . "/log");                   # Script log directory
define("SADM_CFG_DIR"      , SADM_BASE_DIR . "/cfg");                   # Configuration Directory
define("SADM_SYS_DIR"      , SADM_BASE_DIR . "/sys");                   # System related scripts
define("SADM_DAT_DIR"      , SADM_BASE_DIR . "/dat");                   # Data directory
define("SADM_PG_DIR"       , SADM_BASE_DIR . "/pgsql");                 # PostGres DataBase Dir
define("SADM_PKG_DIR"      , SADM_BASE_DIR . "/pkg");                   # Package rpm,deb  directory
define("SADM_NMON_DIR"     , SADM_DAT_DIR  . "/nmon");                  # Where nmon file reside
define("SADM_DR_DIR"       , SADM_DAT_DIR  . "/dr");                    # Disaster Recovery  files 
define("SADM_SAR_DIR"      , SADM_DAT_DIR  . "/sar");                   # System Activty Report Dir
define("SADM_RCH_DIR"      , SADM_DAT_DIR  . "/rch");                   # Result Code History Dir
define("SADM_NET_DIR"      , SADM_DAT_DIR  . "/net");                   # Network SubNet Info Dir
define("SADM_WWW_DIR"      , SADM_BASE_DIR . "/www");                   # Web Site Dir.
define("SADM_DB_DIR"       , SADM_WWW_DIR  . "/db");                    # SQLite3 Database Directory


# SADMIN WEB SITE DIRECTORIES DEFINITION
define("SADM_WWW_HTML_DIR" , SADM_WWW_DIR  . "/html");                  # Web server html Dir
define("SADM_WWW_CFG_DIR"  , SADM_WWW_DIR  . "/cfg");                   # Web Server CFG Dir
define("SADM_WWW_DAT_DIR"  , SADM_WWW_DIR  . "/dat");                   # Web Server Data Dir
define("SADM_WWW_LIB_DIR"  , SADM_WWW_DIR  . "/lib");                   # Web Server Library Dir
define("SADM_WWW_TMP_DIR"  , SADM_WWW_DIR  . "/tmp");                   # Web Server Temp Dir
define("SADM_WWW_RCH_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/rch");    # Web rch dir
define("SADM_WWW_SAR_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/sar");    # Web sar dir
define("SADM_WWW_NET_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/net");    # Web net dir
define("SADM_WWW_DR_DIR"   , SADM_WWW_DAT_DIR . "/${HOSTNAME}/dr");     # Web Disaster Recovery Dir
define("SADM_WWW_NMON_DIR" , SADM_WWW_DAT_DIR . "/${HOSTNAME}/nmon");   # Web nmon Dir
define("SADM_WWW_TMP_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/tmp");    # Web TMP Dir
define("SADM_WWW_LOG_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/log");    # Web LOG Dir


# SADMIN FILE DEFINITION
define("SADM_CFG_FILE"     , SADM_CFG_DIR . "/sadmin.cfg");             # SADM Config File
define("SADM_DB_FILE"      , SADM_DB_DIR  . "/sadm.db");                # SADM SQLite3 Database
define("SADM_CRON_FILE"    , SADM_WWW_CFG_DIR . "/.crontab.txt");       # SADM Crontab File
define("SADM_WWW_TMP_FILE1", SADM_WWW_TMP_DIR . "www_tmpfile1_" . getmypid() ); # SADM Temp File1
define("SADM_UPDATE_SCRIPT",SADM_BIN_DIR."/sadm_osupdate_server.sh -s");# O/S Update Script Name


# LOADING CONFIGURATION FILE AND DEFINE GLOBAL SADM ENVIRONMENT VARIABLE
$lineno = 0;                                                            # Clear Line Number
$handle = fopen(SADM_CFG_FILE , "r");                                   # Set Configuration Filename
if ($handle) {                                                          # If Successfully Open
    while (($line = fgets($handle)) !== false) {                        # If Still Line to read
          $lineno++;                                                    # Increase Line Number
          if ( strpos(trim($line), '#') === 0  )                        # If 1st Non-WhiteSpace is #
             continue;                                                  # Go Read the next line
          list($fname,$fvalue) = explode ('=',$line);                   # Split Line by Name & Value
          #echo "\n$lineno : $line";
          #echo "\nThe Parameter is : " . $fname ;
          #echo "\nThe Value is     : " . $fvalue ;
          if (trim($fname) == "SADM_MAIL_ADDR")     { define("SADM_MAIL_ADDR"     , trim($fvalue));}
          if (trim($fname) == "SADM_CIE_NAME")      { define("SADM_CIE_NAME"      , trim($fvalue));}
          if (trim($fname) == "SADM_MAIL_TYPE")     { define("SADM_MAIL_TYPE"     , trim($fvalue));}
          if (trim($fname) == "SADM_SERVER")        { define("SADM_SERVER"        , trim($fvalue));}
          if (trim($fname) == "SADM_SSH_PORT")      { define("SADM_SSH_PORT"      , trim($fvalue));}
          if (trim($fname) == "SADM_DOMAIN")        { define("SADM_DOMAIN"        , trim($fvalue));}
          if (trim($fname) == "SADM_USER")          { define("SADM_USER"          , trim($fvalue));}
          if (trim($fname) == "SADM_GROUP")         { define("SADM_GROUP"         , trim($fvalue));}
          if (trim($fname) == "SADM_PGUSER")        { define("SADM_PGUSER"        , trim($fvalue));}
          if (trim($fname) == "SADM_PGGROUP")       { define("SADM_PGGROUP"       , trim($fvalue));}
          if (trim($fname) == "SADM_WWW_USER")      { define("SADM_WWW_USER"      , trim($fvalue));}
          if (trim($fname) == "SADM_WWW_GROUP")     { define("SADM_WWW_GROUP"     , trim($fvalue));}
          if (trim($fname) == "SADM_RW_PGUSER")     { define("SADM_RW_PGUSER"     , trim($fvalue));}
          if (trim($fname) == "SADM_RW_PGPWD")      { define("SADM_RW_PGPWD"      , trim($fvalue));}
          if (trim($fname) == "SADM_RO_PGUSER")     { define("SADM_RO_PGUSER"     , trim($fvalue));}
          if (trim($fname) == "SADM_RO_PGPWD")      { define("SADM_RO_PGPWD"      , trim($fvalue));}
          if (trim($fname) == "SADM_PGDB")          { define("SADM_PGDB"          , trim($fvalue));}
          if (trim($fname) == "SADM_PGSCHEMA")      { define("SADM_PGSCHEMA"      , trim($fvalue));}
          if (trim($fname) == "SADM_PGHOST")        { define("SADM_PGHOST"        , trim($fvalue));}
          if (trim($fname) == "SADM_PGPORT")        { define("SADM_PGPORT"        , trim($fvalue));}
          if (trim($fname) == "SADM_MAX_LOGLINE")   { define("SADM_MAX_LOGLINE"   , trim($fvalue));}
          if (trim($fname) == "SADM_MAX_RCHLINE")   { define("SADM_MAX_RCHLINE"   , trim($fvalue));}
          if (trim($fname) == "SADM_NMON_KEEPDAYS") { define("SADM_NMON_KEEPDAYS" , trim($fvalue));}
          if (trim($fname) == "SADM_SAR_KEEPDAYS")  { define("SADM_SAR_KEEPDAYS"  , trim($fvalue));}
          if (trim($fname) == "SADM_RCH_KEEPDAYS")  { define("SADM_RCH_KEEPDAYS"  , trim($fvalue));}
          if (trim($fname) == "SADM_LOG_KEEPDAYS")  { define("SADM_LOG_KEEPDAYS"  , trim($fvalue));}
    }
    fclose($handle);
} else {
    echo "Error opening the file " . SADM_CFG_DIR . "/sadmin.cfg";
} 


# GET THE SADMIN RELEASE NUMBER FORM THE .RELEASE FILE
$REL_FILE = SADM_CFG_DIR . "/.release" ;                                # Name of the Release File
if (file_exists($REL_FILE)) {                                           # If Release file exist
    $f = fopen($REL_FILE, 'r');                                         # Open Release FIle
    $release = fgets($f);                                               # Read Rel No. from File
    fclose($f);                                                         # Close .release file
    define("SADM_VERSION" , trim($release));                            # Create Var. from Release 
}else{
    define("SADM_VERSION" , "00.00");                                   # Default if File Not Exist
    echo "Release file is missing " . $REL_FILE ;                       # Error Mess. - File Missing
}


# ADD PHP LIBRARY DIRECTORY TO PATH
//echo ini_get('include_path');
set_include_path(get_include_path() . PATH_SEPARATOR . SADM_WWW_LIB_DIR);
//echo ini_get('include_path');

# CREATE DATABASE CONNECTION STRING
$connString = "host=".SADM_PGHOST." dbname=".SADM_PGDB." user=".SADM_RW_PGUSER." password=".SADM_RW_PGPWD ;

# CONNECT TO POSTGRESQL DATABASE
$connection = pg_connect($connString);
if (!$connection) { die("Database connection failed: " . mysql_error()); }

# Connect to SQLite3 Database
#$sadmPDO = new PDO('sqlite:'. SADM_DB_FILE);
?>
