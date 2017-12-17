<?php
    echo "</head>";
    echo "\n<body>";
    echo "\n<div id='sadmWrapper'>";                                    # Whole Page Wrapper Div
    echo "\n\n<div id='sadmHeader'>";

    echo "\n    <div id='sadmLogo'><a href='/index.php'>";
    echo "<img width=64 height=64 src=/images/sadmin_logo.png></a>";
    echo "</div>";

    echo "\n    <div id='sadmEnteteLine1'>";
    echo "\n        <div id='sadmEntete1L'>SADMIN Control Center</div>";
    echo "\n        <div id='sadmEntete1R'>The Unix Servers Farm Control Environment</div>"; 
    echo "\n    </div><BR>";

    // echo "\n    <div id='sadmEnteteLine2'>";
    // echo "\n        <div id='sadmEntete2L'>" . SADM_CIE_NAME . "</div>";
    // echo "\n        <div id='sadmEntete2R'>Release " . SADM_VERSION . "</div>";
    // echo "\n    </div>";

    #echo "\n    <div style='clear: both;'> </div><br>";
    echo "<br>";
    echo "\n\n<div id='sadmTopMenu'>";
    echo "\n<ul>"; 
    echo "\n<li><a href='/index.php'>Home Page</a></li>";
    echo "\n<li><a href='/view/sys/sadm_subnet.php?net=192.168.1&option=all'>Network</a></li>";
    echo "\n</ul>";
    echo "\n</div>   <!-- End Of sadmTopMenu -->\n\n";

    echo "\n</div>  <!-- End of Div sadmHeader -->\n\n";
    #echo "\n    <div style='clear: both;'> </div><br>";

    echo "\n<div id='sadmPageContents'>";                               # Lower Part of Page

    require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');# Display SideBar on Left 
    echo "\n\n<div id='sadmRightColumn'>";                              # Beginning Content Page
?>


