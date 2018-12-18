<?php
    echo "</head>";
    echo "\n<body>\n";

    echo "\n<div id='sadmWrapper'>                  <!-- Start Of sadmWrapper -->\n";
    echo "\n<div id='sadmHeader'>                   <!-- Start Of sadmHeader  -->";
?>


    <center><table border=0 bgcolor="#124f44" cellspacing="1" cellpadding="5" width=90% >
    <tr>
        <td bgcolor="#124f44" rowspan="2" align="center" valign="middle">
            <img width=80 height=80 src=/images/sadmin_logo.png>
        </td>
        <td bgcolor="#124f44" align="center">
            <img width=200 height=40 src=/images/sadmin_text.png>
        </td> 
        <td bgcolor="#124f44" align="right">
            <font size="3"><font color="#ffffff"><strong>
            <?php echo SADM_CIE_NAME ?></strong></font>
        </td> 
    </tr>
    <tr>
        <td bgcolor="#124f44" align="center"> 
            <img width=575 height=40 src=/images/UnixSystemAdminTools.png>
        </td>
        <td bgcolor="#124f44" align="right" valign="bottom">
            <font size="1"><font color="#ffffff"><strong>
            <?php echo "Release "  . SADM_VERSION ?></strong></font>
        </td> 
    </tr>
    </table></center>


<?php
    echo "\n</div>                                  <!-- End of sadmHeader -->\n\n";
    # ----------------------------------------------------------------------------------------------
    # HEADING MENU LINE 
    # ----------------------------------------------------------------------------------------------
    #echo "\n<div id='sadmTopMenu'>                  <!-- Start Of sadmTopMenu -->\n";
    #echo "\n<ul>"; 
    #echo "\n    <li><a href='/index.php'>Home Page</a></li>";
    #echo "\n    <li><a href='/view/sys/sadm_view_schedule.php'>O/S Update</a></li>";
    #echo "\n    <li><a href='/view/sys/sadm_view_sysmon.php'>Monitor</a></li>";
    #echo "\n    <li><a href='/view/rch/sadm_view_rch_summary.php?sel=all'>Scripts Status</a></li>";
    #echo "\n    <li><a href='/view/sys/sadm_subnet.php?net=192.168.1&option=all'>Network</a></li>";
    #echo "\n    <li><a href='/view/perf/sadm_server_perf_menu.php'>Performance</a></li>";
    #echo "\n</ul>";
    #echo "\n</div>                                  <!-- End Of sadmTopMenu -->\n\n";

    # ----------------------------------------------------------------------------------------------
    #echo "\n</div>                                  <!-- End of Div sadmHeader -->\n\n";

    # ----------------------------------------------------------------------------------------------
    echo "\n<div id='sadmPageContents'>             <!-- Start Of sadmPageContents -->\n\n";
    require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');# Display SideBar on Left 
    echo "\n<div id='sadmRightColumn'>              <!-- Start Of sadmRightColumn -->\n\n";                              # Beginning Content Page
?>


