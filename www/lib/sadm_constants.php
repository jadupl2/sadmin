<?php

# Setting the HOSTNAME Variable
list($HOSTNAME) = explode ('.', gethostname());                         # HOSTNAME without domain

// Database Constants
define("DB_SERVER", "sadmin.maison.ca");
define("HOME_URL" , "http://sadmin.maison.ca");
define("DB_USER"  , "sadmin");
define("DB_PASS"  , "nimdas");
define("DB_NAME"  , "sadmin");



# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
define("SADM_BASE_DIR"     , "/sadmin");                                # Default SADM Root Base Dir
$TMPVAR = getenv('SADMIN');                                             # Get Env. SADMIN Variable
if (strlen($TMPVAR) != 0 ) { define("SADM_BASE_DIR",$TMPVAR); }         # Use Env. SADMIN Var Base
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

# ADD PHP LIBRARY DIRECTORY TO PATH
//echo ini_get('include_path');
set_include_path(get_include_path() . PATH_SEPARATOR . SADM_WWW_LIB_DIR);
//echo ini_get('include_path');

define("SADM_VERSION"       ,"0.75" );  # Temp Hard Code will get it from cfg file
?>
