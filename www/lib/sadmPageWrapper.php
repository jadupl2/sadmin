<?php
    echo "</head>";
    echo "\n<body>\n";

    echo "\n<div id='sadmWrapper'>                  <!-- Start Of sadmWrapper -->\n";

    echo "\n<div id='sadmHeader'>                   <!-- Start Of sadmHeader  -->";
    echo "\n<div id='sadmEnteteLine1'>              <!-- Start Of sadmEnteteLine1 -->\n";
    echo "\n    <div id='sadmLogo'><a href='/index.php'>";
    echo "           <img width=48 height=48 src=/images/sadmin_logo.png></a>";
    echo "</div>";
    echo "\n    <div id='sadmEntete1L'>SADMIN Control Center</div>";
    echo "\n    <div id='sadmEntete1R'>The Unix Servers Farm Control Environment - Release " .SADM_VERSION."</div>"; 
    echo "\n    <div id='sadmEntete1C'> - " . SADM_CIE_NAME . "</div>";
    echo "\n</div>                                  <!-- End Of sadmEnteteLine1 -->\n";
    echo "\n    <div style='clear: both;'> </div>";
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


