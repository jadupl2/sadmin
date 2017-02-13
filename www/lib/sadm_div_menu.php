<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis 
*   Email       :  jacques.duplessis@sadmin.ca
*   Title       :  sadm_div_header.php
*   Version     :  1.8
*   Date        :  21 June 2016
*   Requires    :  php - BootStrap - PostGresSql
*   Description :  Use to display menu bar at the top of every page.
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
echo "\n<div id='sadmMenu'>";
echo "\n   <ul>";
echo "\n";

echo "\n   <li><a href='http://sadmin.maison.ca/index.php'>Home</a></li>";
echo "\n";

echo "\n   <li><a href='/sadmin/sadm_view_servers.php?selection=all_servers'>Servers</a>";
echo "\n     <ul>";
echo "\n       <li><a href='/sadmin/sadm_view_servers.php?selection=all_servers'>List Servers</a></li>";
echo "\n       <li><a href='/crud/sadm_server_main.php'>Edit Server Data</a></li>";
echo "\n     </ul>"; 
echo "\n   </li>";
echo "\n";

echo "\n   <li><a href='/sadmin/sadm_view_category.php'>Category</a>";
echo "\n     <ul>";
echo "\n       <li><a href='/sadmin/sadm_view_category.php'>List Categories</a></li>"; 
echo "\n       <li><a href='/crud/sadm_category_main.php'>Edit Categories</a></li>"; 
echo "\n     </ul>"; 
echo "\n   </li>";
echo "\n";

echo "\n    <li><a href='/sadmin/sadm_view_rch_summary.php'>Script Status</a></li>";
echo "\n";

echo "\n    <li><a href='/sadmin/sadm_view_sysmon.php'>Servers Alerts</a></li>";
echo "\n";

echo "\n    <li><a href='#'>Performance</a></li>"; 
echo "\n";
echo "\n    <li><a href='/sadmin/sadm_subnet.php?net=192.168.1&option=all'>IP Inventory</a>";
echo "\n    <ul>";
echo "\n        <li><a href='/sadmin/sadm_subnet.php?net=192.168.1&option=all'>192.168.1/24</a></li>";
echo "\n        <li><a href='/sadmin/sadm_subnet.php?net=192.168.0&option=all'>192.168.0/24</a></li>";
echo "\n    </ul>";
echo "\n    </li>";
echo "\n";

echo "\n    <li><a href='#'>About</a></li>";
echo "\n";
echo "\n    </ul>";
echo "\n</div>                             <!-- End of Div sadmMenu -->\n";  
echo "\n<!-- ================================================================================= -->";
?>