<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadm_view_sysmon.php
#   Version     :  1.5
#   Date        :  4 February 2017
#   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
#   Description :  This page allow to view the servers alerts information in various ways
#                  depending on parameters received.
#
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
# 2018_01_04 Initial Version v1.0  
#@2020_03_03 New: v1.1 Shortcut Menu added in page header for fast access within the site.
#
# ==================================================================================================
#
    echo "</head>";
    echo "\n<body vlink='red'>\n";

    echo "\n<div id='sadmWrapper'>                  <!-- Start Of sadmWrapper -->\n";
    echo "\n<div id='sadmHeader'>                   <!-- Start Of sadmHeader  -->";
?>


<center>
<table border=0 bgcolor="#124f44" cellspacing="1" cellpadding="2" width=98s% >

    <tr>
        <td bgcolor="#124f44" rowspan="3" align="center" valign="middle" style="width:15%">
            <a href="/index.php"><img width=80 height=80 src=/images/sadmin_logo.png></a>
        </td>
        <td bgcolor="#124f44" align="center" style="width:70%">
            <img width=200 height=40 src=/images/sadmin_text.png>
        </td>
        <td bgcolor="#124f44" align="right" valign="bottom" style="width:15%">
            <font size="3"><font color="#ffffff"><strong>
            <?php echo SADM_CIE_NAME ?></strong></font>
        </td>
    </tr>

    <tr>
        <td bgcolor="#124f44" align="center">
            <img width=575 height=40 src=/images/UnixSystemAdminTools.png>
        </td>
        <td  rowspan="2" bgcolor="#124f44" align="right" valign="bottom">
            <font size="2"><font color="#ffffff"><strong>
            <?php echo "Release "  . SADM_VERSION ?></strong></font>
        </td>
    </tr>

    <tr> 
        <td colspan="1" bgcolor="#124f44" align="center">
        <a href='/view/srv/sadm_view_servers.php?selection=all_servers'>All Servers</a>
        &nbsp;&nbsp;&nbsp;
        <a href='/view/rch/sadm_view_rch_summary.php?sel=all'>Scripts Status</a>
        &nbsp;&nbsp;&nbsp;
        <a href='/view/sys/sadm_view_schedule.php'>O/S Update</a>
        &nbsp;&nbsp;&nbsp;
        <a href='/view/sys/sadm_view_sysmon.php'>Monitor</a>
        &nbsp;&nbsp;&nbsp;
        <a href='/view/sys/sadm_view_backup.php'>Daily Backup</a>
        &nbsp;&nbsp;&nbsp;
        <a href='/view/sys/sadm_view_rear.php'>ReaR Backup</a>
        &nbsp;&nbsp;&nbsp;
        <a href='/view/perf/sadm_server_perf_menu.php'>Performance</a>
    </td></tr>

</table>
</center>


<?php
    echo "\n</div>                                  <!-- End of sadmHeader -->\n\n";

    echo "\n<div id='sadmPageContents'>             <!-- Start Of sadmPageContents -->\n\n";
    
    # Display SideBar on Left 
    require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');

    # Beginning Content Page
    echo "\n<div id='sadmRightColumn'>              <!-- Start Of sadmRightColumn -->\n\n"; 
?>


