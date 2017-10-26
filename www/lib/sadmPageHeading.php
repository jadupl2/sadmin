<?php
echo "\n<div id='sadmHeader'>";

echo "\n    <div id='sadmLogo'>";
echo "\n    <a href='http://sadmin.maison.ca/index.php'>";
echo "\n        <img width=64 height=64 src=/images/sadmin_logo.png>"; 
echo "\n    </a>";
echo "\n    </div>                                      <!-- End of Div sadmLogo -->\n";
            
echo "\n    <div id='sadmEntete1L'>"; 
echo "\n    <a href='http:/index.php'>";
echo "\n        SADMIN Control Center<br>";
echo "\n    </a>";
echo "\n        <small>" . SADM_CIE_NAME .  " <br>";
echo "\n    </div>                                      <!-- End of Div sadmEntete1L -->\n";

echo "\n    <div id='sadmEntete1R'>"; 
echo "\n        The Unix Servers Farm Control Environment<br>"; 
echo "\n        <small>Release " . SADM_VERSION . "</small>";
echo "\n    </div>                                      <!-- End of Div sadmEntete1R -->";

echo "\n</div>                                          <!-- End of Div sadmHeader -->\n";
?>