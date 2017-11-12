<?php
list($HOSTNAME) = explode ('.', gethostname());                         # HOSTNAME without domain
echo "<br>HOSTNAME = " . $HOSTNAME;

define("SADM_BASE_DIR", "/sadmin");                                # Default SADM Root Base Dir
echo "<br>SADMIN Default = " . SADM_BASE_DIR;

$TMPVAR = getenv('SADMIN');   
echo "<br>GetEnv returned $TMPVAR - LEN = " .  strlen($TMPVAR)    ;                                      # Get Env. SADMIN Variable
#if (strlen($TMPVAR) != 0 ) { 
echo "<br>define('SADM_BASE_DIR',$TMPVAR);"; 
define('SADM_BASE_DIR',$TMPVAR); 
    echo "<br>TMPVAR Not equal 0";
#}

echo "<br>SADMIN At the end 2 is " . SADM_BASE_DIR;
echo "<br>TMPVAR = " . $TMPVAR;
?>

