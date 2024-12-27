<?php
# ==================================================================================================
#   Author      :  Jacques Duplessis
#   Title       :  sadmPageWrapper.php
#   Version     :  1.5
#   Date        :  4 February 2017
#   Requires    :  secure.php.net, mysql.org, getbootstrap.com, DataTables.net
#   Description :  This page allow to view the servers alerts information in various ways
#                  depending on parameters received.
#
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
# 2018_01_04 web Initial Version v1.0  
# 2020_03_03 web v1.1 Shortcut Menu added in page header for fast access within the site.
# 2020_04_10 web v1.2 Add Network link shortcut at the top of each page.
# 2020_04_25 web v1.3 Reduce Menu line in header to fit on Ipad.
# 2020_09_23 web v1.4 Add Tooltips to Shortcut in the page header.
# 2020_12_15 web v1.5 Add Storix Report Link in Header, only if Storix html file exist.
#@2024_10_31 web v1.6 Add VirtualBox Button to view the status of VM export.
#
# ==================================================================================================
#
$URL_STORIX_REPORT  = "/view/daily_storix_report.html";                 # Storix Daily Report Page

echo "</head>";
echo "\n<body>\n";
echo "\n<div id='sadmWrapper'>                  <!-- Start Of sadmWrapper -->\n";
echo "\n<div id='sadmHeader'>                   <!-- Start Of sadmHeader  -->";
?>


<center>
<table border=0 bgcolor="#124f44" cellspacing="1" cellpadding="3" width=98% >

<tr>

    <td bgcolor="#124f44" rowspan="3" align="vcenter" valign="middle" style="width:15%">
        <span data-toggle='tooltip' title='Home Page'>
        <a href="/index.php"><img width=90 height=90 src=/images/sadmin_logo.png></span></a>
    </td>

    <td bgcolor="#124f44" align="center" valign="middle">
        <img width=645 height=69 src=/images/sadmin_new_text.png>
    </td>
    
    <td bgcolor="#124f44" align="right" valign="middle" style="width:15%">
        <font size="3"><font color="#ffffff"><strong>
        <?php
         echo SADM_CIE_NAME ;
         ?>
         </strong></font>
    </td>

</tr>

<tr>

<td  bgcolor="#124f44" align="center" valign="top">
    <font size="2"><strong>
        <div id='quick_link'>
            <a href='/view/srv/sadm_view_servers.php?selection=all_servers'>
                <span data-toggle='tooltip' title='List of all systems'>Systems</span></a>
            &nbsp;&nbsp;&nbsp;
            <a href='/view/rch/sadm_view_rch_summary.php?sel=all'><span data-toggle='tooltip' title='Status of all scripts'>Scripts</span></a>
            &nbsp;&nbsp;&nbsp;
            <a href='/view/sys/sadm_view_schedule.php'><span data-toggle='tooltip' title='Status of the operating system update schedule'>O/S Update</span></a>
            &nbsp;&nbsp;&nbsp;
            <a href='/view/sys/sadm_view_sysmon.php'><span data-toggle='tooltip' title='System Monitor status'>Monitor</span></a>
            &nbsp;&nbsp;&nbsp;
            <?php
            echo "<a href='/view/net/sadm_view_subnet.php?net=" . SADM_NETWORK1 . "&option=all'><span data-toggle='tooltip' title='Network IP/Name utilization'>Network</span></a>"
            ?>
            &nbsp;&nbsp;&nbsp;
            <a href='/view/sys/sadm_view_backup.php'><span data-toggle='tooltip' title='Daily Backup Status'>Daily Backup</span></a>
            &nbsp;&nbsp;
            <a href='/view/sys/sadm_view_rear.php'><span data-toggle='tooltip' title='Status of the ReaR Image Backup Schedule'>ReaR Backup</span></a>
            &nbsp;&nbsp;
            <a href='/view/sys/sadm_list_vmexport.php'><span data-toggle='tooltip' title='Status of the virtual machine export'>VM Export</span></a>
            &nbsp;&nbsp;
            <a href='/view/perf/sadm_server_perf_adhoc_all.php'><span data-toggle='tooltip' title='Show Performance Graph of systems'>Performance</span></a>
            </div>
        </div>
    </font>
        </td>

        <td bgcolor="#124f44" align="right" valign="bottom">
            <font size="2"><font color="#ffffff"><strong>
            <?php echo "Release "  . SADM_VERSION ?></strong></font>
        </td>

    </tr>

</table>


<br>
</center>


<?php
    echo "\n</div>                                  <!-- End of sadmHeader -->\n\n";
    echo "\n<div id='sadmPageContents'>             <!-- Start Of sadmPageContents -->\n\n";
    
    # Display SideBar on Left 
    require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');
    #require ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');

    # Set the beginning Content Page
    echo "\n<div id='sadmRightColumn'>              <!-- Start Of sadmRightColumn -->\n\n"; 
?>


