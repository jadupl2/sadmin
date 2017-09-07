<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_div_header.php
*   Version     :  1.8
*   Date        :  21 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Use to display Header at the top of every page.
*
*   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
*
*   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
*   of the GNU General Public License as published by the Free Software Foundation; either
*   version 2 of the License, or (at your option) any later version.
*
*   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*   See the GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License along with this program.
*   If not, see <http://www.gnu.org/licenses/>.
* ==================================================================================================
*/   
echo "\n\n\n<!-- ============================================================================= -->";
echo "\n<div id='sadmHeader'>";

echo "\n    <div id='sadmLogo'>";
echo "\n    <a href='http://sadmin.maison.ca/index.php'>";
echo "\n        <img width=64 height=64 src=/images/sadmin_logo.png>"; 
echo "\n    </a>";
echo "\n    </div>                                      <!-- End of Div sadmLogo -->\n";
            
echo "\n    <div id='sadmEntete1L'>"; 
echo "\n    <a href='http://sadmin.maison.ca/index.php'>";
echo "\n        SADMIN Control Center<br>";
echo "\n    </a>";
echo "\n        <small>" . SADM_CIE_NAME .  " <br>";
echo "\n    </div>                                      <!-- End of Div sadmEntete1L -->\n";

echo "\n    <div id='sadmEntete1R'>"; 
echo "\n        The Unix Servers Farm Control Environment<br>"; 
echo "\n        <small>Release " . SADM_VERSION . "</small>";
echo "\n    </div>                                      <!-- End of Div sadmEntete1R -->";

echo "\n</div>                                          <!-- End of Div sadmHeader -->\n";
echo "\n<!-- ================================================================================= -->";

?>
       