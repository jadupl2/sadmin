<?php
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHead.php');  # <head>CSS,JavaScript</Head>       
echo "\n<body>"; 
echo "\nHello ";

sadm_alert   ("Are you sure you want to delete the group " . scr_code . " ?");
sadm_confirm ("Are you sure you want to delete the group " . scr_code . " ?");
echo "\n</body></html>";
?>

