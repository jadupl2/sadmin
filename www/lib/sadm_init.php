<?php

define("SADM_VERSION"       ,"0.84" );  # Temp Hard Code will get it from cfg file


# Setting the HOSTNAME Variable
list($HOSTNAME) = explode ('.', gethostname());                         # HOSTNAME without domain

# SET SADMIN BASE DIRECTORIES 
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
#
# SADMIN WEB SITE DIRECTORIES DEFINITION
define("SADM_WWW_DIR"      , SADM_BASE_DIR . "/www");                   # Web Site Dir.
define("SADM_WWW_HTML_DIR" , SADM_WWW_DIR  . "/html");                  # Web server html Dir
define("SADM_WWW_DAT_DIR"  , SADM_WWW_DIR  . "/dat");                   # Web Server Data Dir
define("SADM_WWW_LIB_DIR"  , SADM_WWW_DIR  . "/lib");                   # Web Server Library Dir
define("SADM_WWW_RCH_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/rch");    # Web rch dir
define("SADM_WWW_SAR_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/sar");    # Web sar dir
define("SADM_WWW_NET_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/net");    # Web net dir
define("SADM_WWW_DR_DIR"   , SADM_WWW_DAT_DIR . "/${HOSTNAME}/dr");     # Web Disaster Recovery Dir
define("SADM_WWW_NMON_DIR" , SADM_WWW_DAT_DIR . "/${HOSTNAME}/nmon");   # Web nmon Dir
define("SADM_WWW_TMP_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/tmp");    # Web TMP Dir
define("SADM_WWW_LOG_DIR"  , SADM_WWW_DAT_DIR . "/${HOSTNAME}/log");    # Web LOG Dir

// Database Constants
define("DB_SERVER", "sadmin.maison.ca");
define("HOME_URL" , "http://sadmin.maison.ca");
define("DB_USER"  , "sadmin");
define("DB_PASS"  , "nimdas");
define("DB_NAME"  , "sadmin");

# Loading Configuration File 
$lineno = 0;
$handle = fopen(SADM_CFG_DIR . "/sadmin.cfg", "r");
#echo "Location of config file is " . SADM_CFG_DIR . "/sadmin.cfg";
if ($handle) {
    while (($line = fgets($handle)) !== false) {
          $lineno++;                                                    # Increase Line Number
          if ( strpos(trim($line), '#') === 0  )                        # If 1st Non-WhiteSpace is #
             continue;                                                  # Go Read the next line
          #echo "\n$lineno : $line";
          list($fname,$fvalue) = explode ('=',$line); 
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
    echo "Error opening the file";
} 



# ADD PHP LIBRARY DIRECTORY TO PATH
//echo ini_get('include_path');
set_include_path(get_include_path() . PATH_SEPARATOR . SADM_WWW_LIB_DIR);
//echo ini_get('include_path');

// 1. Create a database connection
#$connString = "host=".DB_SERVER." dbname=".DB_NAME." user=".DB_USER." password=".DB_PASS ;
$connString = "host=".SADM_PGHOST." dbname=".SADM_PGDB." user=".SADM_RW_PGUSER." password=".SADM_RW_PGPWD ;

$connection = pg_connect($connString);
if (!$connection) { die("Database connection failed: " . mysql_error()); }

?>
