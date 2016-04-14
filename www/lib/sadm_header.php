<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>SADMIN Web Site</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />
    <link href="/css/sadmin.css"  rel="stylesheet" type="text/css"/>
</head>

<body>
    <div id="Container">
        <div id="Header">
            <div id="sadm_logo"> 
                <img width=64 height=64 src=/img/sadmin_logo.png> 
            </div>
                <h2>SADMIN Web Site</h2>
                The Servers Farm control environment<br>
                Version 1.00
        </div>
        
        <div id="Menu">
            <ul>
                <li><a href="#">Home</a></li>
                <li><a href="/sadmin/sadm_view_servers.php">Servers</a>
                    <ul>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=server">By Server Name</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=osname">By O/S Name</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=osversion">By O/S Version</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=ostype">By O/S Type</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=server_type">By Server Type</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=inactive">List Inactive Server(s)</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=linux">List Only Linux Server(s)</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=aix">List Only Aix Server(s)</a></li>
                    <li><a href="/sadmin/sadm_search.php">Edit Server Data</a></li>
                    </ul></li>
                <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=status">Job Status</a>
                    <ul>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=status">By Status</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=server">By Server</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=jobname">By Name</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=elapse">By Elapse Time</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=date">By Date</a></li>
                    </ul></li>
                <li><a href="#">Performance</a></li>
                <li><a href="/sadmin/sadm_subnet.php?net=192.168.1">IP Inventory</a>
                    <ul>
                    <li><a href="/sadmin/sadm_subnet.php?net=192.168.1">Subnet 192.168.1/24</a></li>
                    <li><a href="/sadmin/sadm_subnet.php?net=192.168.0">Subnet 192.168.0/24</a></li>
                    </ul></li>
                <li><a href="#">About</a></li>
            </ul>
        </div>

        <div id="SideBarAndBodyContainer">
            <div id="SideBar">
                <center><h3>Servers</h3></center>
                <ul>
                    <li><a  class="selected" href="/sadmin/sadm_view_servers.php?selection=server">By Server Name</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=osname">By O/S Name</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=osversion">By O/S Version</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=ostype">By O/S Type</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=server_type">By Server Type</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=inactive">List Inactive Server(s)</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=linux">List Only Linux Server(s)</a></li>
                    <li><a href="/sadmin/sadm_view_servers.php?selection=aix">List Only Aix Server(s)</a></li>
                    <li><a href="/sadmin/sadm_search.php">Edit Server Data</a></li>
                </ul>
                <center><h3>IP Inventory</h3></center>
                <ul>
                    <li><a href="/sadmin/sadm_subnet.php?net=192.168.1">Subnet 192.168.1/24</a></li>
                    <li><a href="/sadmin/sadm_subnet.php?net=192.168.0">Subnet 192.168.0/24</a></li>
                </ul>
                <center><h3>Job Status</h3></center>
                <ul>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=status">By Status</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=server">By Server</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=jobname">By Name</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=elapse">By Elapse Time</a></li>
                    <li><a href="/sadmin/sadm_view_rch_summary.php?sortorder=date">By Date</a></li>
                </ul>


                </div>

            <div id="MainBody">
