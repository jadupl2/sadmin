<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
    <title>SADMIN Web Site</title>    

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <meta name="description" content="SADMIN - Unix System Administration">
    <meta name="author" content="Jacques Duplessis (duplessis.jacques@gmail.com)">
    <link rel="icon" href="/icons/favicon.ico">
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />

    <!-- Bootstrap -->
    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Optional theme -->
    <link href="/css/bootstrap-theme.min.css" rel="stylesheet">
    <!-- DataTable CSS -->
    <link href="/css/jquery.dataTables.min.css" rel="stylesheet">
    
    <!-- Sadmin  -->
    <link href="/css/sadmin.css"  rel="stylesheet" type="text/css"/>
     
    <script> 
    $(document).ready(function(){ $('#example').DataTable();    } ); 
    </script>   
    </head>
<script>
function goBack() {
    windows.history.back()
}
</script>

<body>
    <div id="sadmContainer">
        <div id="sadmHeader">
            <div id="sadmLogo"> 
                <img width=64 height=64 src=/images/sadmin_logo.png> 
            </div>
            <div id="sadmEntete1L"> 
                SADMIN Control Center<br>
                <small>Your Company Name</small><br>
            </div>
            <div id="sadmEntete1R"> 
                The Unix Servers Farm Control Environment<br>
                <small>Version 0.75</small>
            </div>
        </div>
        
        <div id="sadmMenu">
            <ul>
                <li><a href="#">Home</a></li>
                <li><a href="/sadmin/sadm_view_servers.php?selection=all_servers">Servers</a>
                    <ul>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=all_servers">List All Servers</a></li>
                    <li><a href="/sadmin/sadm_search_input.php">Edit Server Data</a></li>
                    </ul></li>
                <li><a href="/sadmin/sadm_category_main.php">Category</a>
                    <ul>
                    <li><a href="/sadmin/sadm_category_main.php">Edit Categories</a></li>
                    <li><a href="/sadmin/sadm_category_list.php">List Categories</a></li>
                    </ul></li>
                <li><a href="/sadmin/sadm_view_rch_summary.php?selection=all">Script Status</a></li>
                <li><a href="#">Performance</a></li>
                <li><a href="/sadmin/sadm_subnet.php?net=192.168.1">IP Inventory</a>
                    <ul>
                    <li><a href="/sadmin/sadm_subnet.php?net=192.168.1">Subnet 192.168.1/24</a></li>
                    <li><a href="/sadmin/sadm_subnet.php?net=192.168.0">Subnet 192.168.0/24</a></li>
                    </ul></li>
                <li><a href="#">About</a></li>
            </ul>
        </div>

        <div id="sadmSideBarAndBodyContainer">
            <div id="sadmSideBar">
            
<?php
	# ---------------------------   O/S REPARTITION SIDEBAR     ------------------------------------
	#$sadm_array = build_sidebar_servers_info($sidebar_array);
	$sadm_array = build_sidebar_servers_info();
    $SERVER_COUNT=0;
    echo "<br>";
    echo "<p><strong>O/S Repartition</strong></p>\n";
    echo "<ul>\n";
    foreach($sadm_array as $key=>$value)
    {
        list($kpart1,$kpart2) = explode(",",$key);
        if ($kpart1 == "srv_osname") {
           echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=os";
		   echo "&value=" . $kpart2 ."'>$value $kpart2 server(s)</a></li>\n";
           $SERVER_COUNT = $SERVER_COUNT + $value;
        }
    }
    # All Servers Link 
    echo "<li><a href='/sadmin/sadm_view_servers.php?selection=all_servers'";
	echo ">All (" . $SERVER_COUNT . ") Servers</a></li>\n";
    echo "</ul>\n";
  
	# SERVERS ATTRIBUTES SIDEBAR
    echo "<br>";
    echo "<p><strong>Servers Attributes</strong></p>\n";
    echo "<ul>\n";

    # Number of Active Servers
    $kpart2 = $sadm_array["srv_active,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_active'>";
    if ( ${kpart2} == 0 ) {
        echo "No active servers</a></li>\n";
    }else{
        echo "${kpart2} active servers</a></li>\n";
    }    

    # Number of Inactive Servers
    $kpart2 = $sadm_array["srv_inactive,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_inactive'>";
    if ( ${kpart2} == 0 ) {
        echo "No inactive server</a></li>\n";
    }else{
        echo "${kpart2} inactive servers</a></li>\n";
    }
    
    # Number of Virtual Servers
    $kpart2 = $sadm_array["srv_vm,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_vm'>";
    if ( ${kpart2} == 0 ) {
        echo "No virtual servers</a></li>\n";
    }else{
        echo "${kpart2} virtual(s) server(s)</a></li>\n";
    }

    # Number of physical Servers
    $kpart2 = $sadm_array["srv_physical,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_physical'>";
    if ( ${kpart2} == 0 ) {
        echo "No physical server</a></li>\n";
    }else{
        echo "${kpart2} physical(s) server(s)</a></li>\n";
    }

    # Number of Sporadic Servers
    $kpart2 = $sadm_array["srv_sporadic,"];
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_servers.php?selection=all_sporadic'>";
    if ( ${kpart2} == 0 ) {
        echo "No sporadic server</a></li>\n";
    }else{
        echo "${kpart2} sporadic(s) server(s)</a></li>\n";
    }

    echo "</ul>\n";
	
	
	# ---------------------------   SCRIPTS STATUS SIDEBAR      ------------------------------------
    echo "<br>\n";                                                      # Insert White Line
    echo "<p><strong>Scripts Status</strong></p>\n";                    # Display Section Title
	$script_array = build_sidebar_scripts_info();                       # Build $script_array
    $TOTAL_SCRIPTS=count($script_array);                                # Get Nb. Scripts in Array
    $TOTAL_FAILED=0; $TOTAL_SUCCESS=0; $TOTAL_RUNNING=0;                # Initialize Total to Zero
    
    # Loop through Script Array to count Different Return Code 
    foreach($script_array as $key=>$value) { 
        list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$ccode,$cfile) 
            = explode(",", $value);
        if ($ccode == 0) { $TOTAL_SUCCESS += 1; }
        if ($ccode == 1) { $TOTAL_FAILED  += 1; }
        if ($ccode == 2) { $TOTAL_RUNNING += 1; }
    } 
    
    # Display Total number of Scripts
    echo "<ul>\n";
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=all'>";
	echo "All (" . $TOTAL_SCRIPTS . ") Scripts</a></li>\n";
    
    # Display Total Number of Failed Scripts
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=failed'>";
    if ( $TOTAL_FAILED == 0 ) {
        echo "No Failed Script</a></li>\n";
    }else{
        echo "$TOTAL_FAILED Script(s)</a></li>\n";
    }

    # Display Total Number of Running Scripts
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=running'>";
    if ( $TOTAL_RUNNING == 0 ) {
        echo "No Running Script</a></li>\n";
    }else{
        echo "$TOTAL_RUNNING Running Script(s)</a></li>\n";
    }

    # Display Total Number of Succeeded Scripts
    echo "<li class='text-capitalize'><a href='/sadmin/sadm_view_rch_summary.php?sel=success'>";
    if ( $TOTAL_SUCCESS == 0 ) {
        echo "No Script Succeeded</a></li>\n";
    }else{
        echo "$TOTAL_SUCCESS Success Script(s)</a></li>\n";
    }
    echo "</ul>\n";
?>


                </div>

            <div id="sadmMainBody">
