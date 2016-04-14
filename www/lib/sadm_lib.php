<?php
	// This file is the place to store all SADMIN functions

// ================================================================================================
//           All page Heading 
// ================================================================================================
function sadm_page_heading($msg) {
    $message = $msg;
    
	echo "<div id='PageHeading'>\n";
        echo "<div id='PageHeadingLeft'>\n";
            echo "${msg}\n";
        echo "</div>\n";
        echo "<div id='PageHeadingRight'>\n";
            echo date('l jS \of F Y, h:i:s A');
        echo "</div>\n";
    echo "</div>\n";
    echo "<br>\n";
    
}





// ================================================================================================
//            Popup Message received as parameter and wait for OK to be pressed 
// ================================================================================================
function alert($msg) {
    $message = $msg;
    $message = preg_replace("/\r?\n/", "\\n", addslashes($message));
    echo "<script type=\"text/javascript\">\n";
    echo " alert(\"$message\");\n";
    echo "</script>\n\n";
}


// ================================================================================================
//                       Transform date (DD/MM/YYY) into MYSQL format
// ================================================================================================
function DDMMYYYY_2_mysqldate( $input_date ) {
    $date_array = explode("/",$input_date);
    $mysql_date = $date_array[2] . '/' . $date_array[1] . '/' . $date_array[0] . " 00:00:00";
    return $mysql_date ;
}

	
// ================================================================================================
//           Transform MYSQL date (YYYY/MM/DD HH:MM:SS) format into user format (DD/MM/YYY)
// ================================================================================================
function mysql_date_2_DDMMYYYY( $mysql_date ) {
    $wyear  = substr($mysql_date, 0, 4); 
    $wmonth = substr($mysql_date, 5, 2); 
    $wday   = substr($mysql_date, 8, 2); 
    $input_date = $wday . '/' . $wmonth . '/' . $wyear ;
    return $input_date ;
}
	


// ================================================================================================
//  Calculate elepsed time between two times value passed as arguments
//  Parameters are in this format HH:MM:SS in 24 hours format - Will return difference in HH:MM:
// ================================================================================================
function time_difference ( $wstart, $wend)
{
    #echo "<br>Start $wstart End $wend";
    list ($shour, $smin,   $ssec) = split(":", $wstart, 3);
    $wtime1 = ($shour*60*60)+ ($smin*60) + $ssec;

    list ($ehour, $emin,   $esec) = split(":", $wend, 3);
    $wtime2 = ($ehour*60*60)+ ($emin*60) + $esec;
    
    #echo "<br>Time 2 = $wtime2 Time 1 = $wtime1 Difference = " . ($wtime2 -$wtime1) . "<br>" ;
    $TOTAL_SEC = $wtime2 - $wtime1 ;
    
    #echo "<BR>Total Sec before is $TOTAL_SEC";
    if ($TOTAL_SEC < 0) { $TOTAL_SEC = ((24*60*60) - $wtime1) + $wtime2 ;}
    #echo "<BR>Total Sec after is $TOTAL_SEC";
    
    $fhrs = 0 ;
    if ($TOTAL_SEC > 3600) {
        $fhrs = intval($TOTAL_SEC/3600);
        $WORK = trim($TOTAL_SEC - ($fhrs*3600));
        $TOTAL_SEC = $WORK; 
    }
    $HOURS = sprintf("%02d",number_format( $fhrs,0 ));
    $fmin = 0 ;
    if ($TOTAL_SEC > 60  ) {
        $fmin = intval($TOTAL_SEC/60) ;
        $WORK = trim($TOTAL_SEC - ($fmin*60)) ; 
        $TOTAL_SEC = $WORK; 
    }
    $MIN = sprintf("%02d",number_format($fmin,0));
    $fsec = $TOTAL_SEC ;
    $SEC = sprintf("%02d",number_format($fsec,0));
    $DUREE = $HOURS . ":" . $MIN . ":" . $SEC ;
    return ($DUREE);  
}


// ================================================================================================
//                  Simple form to accept the server name and function to perform
// ================================================================================================
function accept_key($server_key) {
    echo "<form action='' method='POST'>";
    echo '<br><table frame="border" bgcolor="99FF66" border="0" cellspacing="2" width="600">';
    echo '<tr bgcolor="99FF66"><td valign="bottom" width=150 align=left><b>Server name</b></td>';
    echo '<td><input type="text" name="server_key" size="12" value="" /></td>';
    //echo "<td><input type='submit' value='Submit'/><a href='server_list.php'></td>";
    //echo '<td><input type="button" value="Google" onClick="window.location="http://www.google.com" /></td>';
    echo '<td><a href=server_create.php?id="$server_key"><button name="test" value=0 type="button">Create</button></td>';
    echo "<td><button name='create' value='0' type='button'>Create</button></td>";
    echo "<td><button name='query'  value='0' type='button'>Query </button></td>";
    echo "<td><button name='modify' value='0' type='button'>Modify</button></td>";
    echo "<td><button name='delete' value='0' type='button'>Delete</button></td>";
    echo "<td><button name='exit'   value='0' type='button'>Exit  </button></td>";
    echo '</tr><tr><td colspan="7" height="20" >Enter the server name you wish to to Create, Modify, Query or Delete & press corresponding button.</td></tr>';
    echo '<tr><td colspan=7><hr></td></tr></table>';
    echo '</form>';
}









// ================================================================================================
//                                        Standard Page footer
// ================================================================================================
function display_row_footer() {
	echo "</table></center><br>";	
}
		


		
// ================================================================================================
//                      Display Server Data used in the data input form
// ================================================================================================
function display_record( $rarray , $title) {
	echo "<h2>$title</h2>";
	echo '<br><table frame="border" border="0" cellspacing="0" width="900" >';
	$BGCOLOR="blue" ; $FNT_COLOR="#FFFFFF";

	// Create two columns (Static Info and Updated Daily Column
	echo '<tr>';
	echo "<td bgcolor=$BGCOLOR colspan=2 align=center><font color=$FNT_COLOR><b>Static Information</b></font></td>";
	echo '<td colspan=1></td>';
	echo "<td bgcolor=$BGCOLOR colspan=2 align=center><b><font color=$FNT_COLOR>Information Updated Automatically</font></b></td>";
	echo '</tr>';

	// SERVER NAME & NETWORK INTERFACE 0
	$BGCOLOR="lavender";
	echo '<tr>';
	echo "<td bgcolor=$BGCOLOR width=230 align=left><b>Server Name   </b></td>";
	echo "<td width=220 bgcolor=$BGCOLOR ><input type='text' name='server_name' size=12 value='" . stripslashes($rarray["server_name"]) . "' /></td>";
	echo '<td width=20> </td>';
	echo "<td width=200 bgcolor=$BGCOLOR ><b>Network interface 0</b></td>";
    $IP = $rarray["server_ip1a"] . '.' . $rarray["server_ip1b"] . '.' . $rarray["server_ip1c"] . '.' . $rarray["server_ip1d"];
	echo "<td width=210 bgcolor=$BGCOLOR>$IP</td>";
	echo '</tr>';

	// SERVER DESC. & NETWORK INTERFACE 1
	echo "<tr><td  bgcolor=$BGCOLOR><b>Server Description</b></td>";
	echo "<td bgcolor=$BGCOLOR><input type='text' name='server_desc' size=30 value='" . stripslashes($rarray["server_desc"]) . "' /></td>";
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR><b>Network interface 1</b></td>";
    $IP = $rarray["server_ip2a"] . '.' . $rarray["server_ip2b"] . '.' . $rarray["server_ip2c"] . '.' . $rarray["server_ip2d"];
	echo "<td width=210 bgcolor=$BGCOLOR>$IP</td>";
	echo '</tr>';
	  
	// SERVER TYPE & NETWORK INTERFACE 2
	echo "<tr><td bgcolor=$BGCOLOR><b>Server Type</b></td>";
	echo "<td bgcolor=$BGCOLOR><select name='server_type' size=1>";
	if (stripslashes($rarray['server_type']) == "Dev" ) { echo '<option selected>Dev</option>';}  else {echo '<option>Dev</option>';}
	if (stripslashes($rarray['server_type']) == "Prod") { echo '<option selected>Prod</option>';} else {echo '<option>Prod</option>';}
	if (stripslashes($rarray['server_type']) == "Test" ) { echo '<option selected>Test</option>';}  else {echo '<option>Test</option>';}
	if (stripslashes($rarray['server_type']) == "Lab" ) { echo '<option selected>Lab</option>';}  else {echo '<option>Lab</option>';}
	echo '</select></td>';
	echo '<td> </td>';
	echo "<td  bgcolor=$BGCOLOR><b>Network interface 2</b></td>";
    $IP = $rarray["server_ip3a"] . '.' . $rarray["server_ip3b"] . '.' . $rarray["server_ip3c"] . '.' . $rarray["server_ip3d"];
	echo "<td width=210 bgcolor=$BGCOLOR>$IP</td>";
	echo '</tr>';
      
	// DOMAIN NAME & INTERNAL DISK CAPACITY
	echo '<tr>';
	echo "<td bgcolor=$BGCOLOR><b>Domain Name</b></td>";
	echo "<td bgcolor=$BGCOLOR><input type='text' name='server_domain' size=20 value='" . stripslashes($rarray["server_domain"]) . "' /></td>";
	echo '<td></td>';
	echo "<td bgcolor=$BGCOLOR><b>Internal Disk</b></td>";
	echo "<td  bgcolor=$BGCOLOR>" . $rarray['server_disk_int'] . " GB" . '</td>';
	echo '</tr>';

	// SERVER ACTIVE & EXTERNAL DISK CAPACITY
	echo "<tr><td bgcolor=$BGCOLOR><b>Server Status</b></td>";
	if (stripslashes($rarray['server_active']) == 1 ) {
	   echo "<td  bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_active" value="1" checked >Active';
	   echo '<input type="radio" name="server_active" value="0">Inactive</td>';
	}else{
	   echo "<td  bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_active" value="1">Active';
	   echo '<input type="radio" name="server_active" value="0" checked >Inactive</td>';
	}
	echo '<td></td>';
	echo "<td bgcolor=$BGCOLOR><b>External Disk</b></td>";
	echo "<td bgcolor=$BGCOLOR>" . $rarray['server_disk_ext'] . " GB" . '</td>';
	echo '</tr>';

	// Graphic STATUS & CPU NUMBER & SPEED
	echo "<tr><td bgcolor=$BGCOLOR><b>Perf. Graph Generated ?</b></td>";
	if (stripslashes($rarray['server_graphic']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_graphic" value="1" checked >Yes';
	   echo '<input type="radio" name="server_graphic" value="0">No</td>';
	}else{
	   echo "<td  bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_graphic" value="1">Yes';
	   echo '<input type="radio" name="server_graphic" value="0" checked >No</td>';
	}
	echo '<td></td>';
	echo "<td bgcolor=$BGCOLOR><b>Number of cpu</b></td>";
	echo "<td bgcolor=$BGCOLOR>" . $rarray["server_cpu_nb"]  . ' X ' . $rarray["server_cpu_speed"] . '  Mhz';
	echo '</tr>';

	// MONITOR SERVER & MEMORY SIZE
	echo '<tr>';
	echo "<td bgcolor=$BGCOLOR><b>Server O/S</b></td>";
	echo "<td bgcolor=$BGCOLOR><select name='server_os' size=1>";
	if (stripslashes($rarray['server_os']) == "Linux"    ) { echo '<option selected>Linux</option>'    ;} else {echo '<option>Linux</option>';}
	if (stripslashes($rarray['server_os']) == "Aix"      ) { echo '<option selected>Aix</option>'      ;} else {echo '<option>Aix</option>';}
	if (stripslashes($rarray['server_os']) == "Windows"  ) { echo '<option selected>Windows</option>'  ;} else {echo '<option>Windows</option>';}
	if (stripslashes($rarray['server_os']) == "Mainframe") { echo '<option selected>Mainframe</option>';} else {echo '<option>Mainframe</option>';}
	if (stripslashes($rarray['server_os']) == "AS400"    ) { echo '<option selected>AS400</option>'    ;} else {echo '<option>AS400</option>';}
	if (stripslashes($rarray['server_os']) == "VMware"   ) { echo '<option selected>VMware</option>'   ;} else {echo '<option>VMware</option>';}
	echo '</select></td>';
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR><b>Memory</b></td>";
	echo "<td bgcolor=$BGCOLOR>" . $rarray["server_memory"] . ' MB';
	echo '</td></tr>';

	// Disaster Recovery
	echo "<tr><td bgcolor=$BGCOLOR><b>Recover at DR Test ?</b></td>";
	if (stripslashes($rarray['server_dr']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_dr" value="1" checked >Yes';
	   echo '<input type="radio" name="server_dr" value="0">No</td>';
	}else{
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_dr" value="1">Yes';
	   echo '<input type="radio" name="server_dr" value="0" checked >No</td>';
	}
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR><b>Serial Number</b></td>";
	echo "<td bgcolor=$BGCOLOR>" . $rarray["server_serial"] . "</td>";
	echo '</tr>';

	// SERVERVER ADMIN & SERVER MODEL
	echo "<tr><td bgcolor=$BGCOLOR><b>In User Admin Interface ?</b></td>";
	if (stripslashes($rarray['server_user_admin']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_user_admin" value="1" checked >Yes';
	   echo '<input type="radio" name="server_user_admin" value="0">No</td>';
	}else{
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_user_admin" value="1">Yes';
	   echo '<input type="radio" name="server_user_admin" value="0" checked >No</td>';
	}
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR align=left><b>Server Model   </b></td>";
	echo "<td bgcolor=$BGCOLOR>" . $rarray["server_model"] . "</td>";
	echo '</tr>';

	// USE STORIX 
	echo "<tr><td bgcolor=$BGCOLOR><b>Burn Storix ISO ?</b></td>";
	if (stripslashes($rarray['server_storix']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_storix" value="1" checked >Yes';
	   echo '<input type="radio" name="server_storix" value="0">No</td>';
	}else{
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_storix" value="1">Yes';
	   echo '<input type="radio" name="server_storix" value="0" checked >No</td>';
	}
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR align=left><b>Server 32/64 Bits </b></td>";
	if (stripslashes($rarray['server_bits']) == 1 ) {
	    echo "<td bgcolor=$BGCOLOR>64</td>";
	}else{
	    echo "<td bgcolor=$BGCOLOR>32</td>";
	}
	echo '</tr>';

	// USE FOR DOCUMENTATION ONLY 
	echo "<tr><td bgcolor=$BGCOLOR><b>Use only for documentation ?</b></td>";
	if (stripslashes($rarray['server_doc_only']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_doc_only" value="1" checked >Yes';
	   echo '<input type="radio" name="server_doc_only" value="0">No</td>';
	}else{
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_doc_only" value="1">Yes';
	   echo '<input type="radio" name="server_doc_only" value="0" checked >No</td>';
	}
	echo '<td> </td>';
    echo "<td bgcolor=$BGCOLOR></td>";
    echo "<td bgcolor=$BGCOLOR></td>";
	echo '</tr>';

	// DR NOTES & VMWARE 
	echo '<tr>';
	echo "<td bgcolor=$BGCOLOR><b>DR Notes</b></td>";
	echo "<td bgcolor=$BGCOLOR>";
	echo '<input type="text" name="server_drnote" size="25" value="' . stripslashes($rarray["server_drnote"]) . '" /></td>';
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR><b>Virtual Server</b></td>";
	if (stripslashes($rarray['server_vm']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>Yes</td>";
	}else{
	   echo "<td bgcolor=$BGCOLOR>No</td>";
	}
	echo '</tr>';
	  
	// General Notes & SERVER OS VERSION
	echo '<tr>';
	echo "<td bgcolor=$BGCOLOR><b>General Notes</b></td>";
	echo "<td bgcolor=$BGCOLOR>";
	echo '<input type="text" name="server_note" size="25" value="' . stripslashes($rarray["server_note"]) . '" /></td>';
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR><b>Server OS version</b></td>";
	echo "<td bgcolor=$BGCOLOR>" . $rarray['server_osver1'] . '.' . $rarray['server_osver2']  . '.' . $rarray['server_osver3'];
	echo '</td>';
	echo '</tr>';
	
	  
	// INCLUDE IN OS UPDATE SCHEDULE AND USING AD TO LOGIN
	echo '<tr>';
	echo "<tr><td bgcolor=$BGCOLOR><b>O/S Update in the Sched. ?</b></td>";
	if (stripslashes($rarray['server_os_update']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_os_update" value="1" checked >Yes';
	   echo '<input type="radio" name="server_os_update" value="0">No</td>';
	}else{
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_os_update" value="1">Yes';
	   echo '<input type="radio" name="server_os_update" value="0" checked >No</td>';
	}
	#echo "<td bgcolor=$BGCOLOR></td>";
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR><b>Use Active Directory ?</b></td>";
	if (stripslashes($rarray['server_use_ad']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>Yes</td>";
	}else{
	   echo "<td bgcolor=$BGCOLOR>No</td>";
	}
	echo '</tr>';


	  
	// FREQUENCE OF O/S UPDATE (1/4/6 MTH) AND DATE OF NEXT UPDATE
	echo '<tr>';
	echo "<tr><td bgcolor=$BGCOLOR><b>O/S Update every x Mth.</b></td>";
	if (stripslashes($rarray['server_os_update_mth']) == 1 ) {
	   echo "<td bgcolor=$BGCOLOR>";
	   echo '<input type="radio" name="server_os_update_mth" value="1" checked>1 mth ';
	   echo '<input type="radio" name="server_os_update_mth" value="4">4 mth ';
	   echo '<input type="radio" name="server_os_update_mth" value="6">6 mth </td>';
	}else{
		if (stripslashes($rarray['server_os_update_mth']) == 4 ) {
			echo "<td bgcolor=$BGCOLOR>";
			echo '<input type="radio" name="server_os_update_mth" value="1">1 mth ';
			echo '<input type="radio" name="server_os_update_mth" value="4" checked>4 mth ';
			echo '<input type="radio" name="server_os_update_mth" value="6">6 mth </td>';
		}else{
			echo "<td bgcolor=$BGCOLOR>";
			echo '<input type="radio" name="server_os_update_mth" value="1">1 mth ';
			echo '<input type="radio" name="server_os_update_mth" value="4">4 mth ';
			echo '<input type="radio" name="server_os_update_mth" value="6" checked>6 mth </td>';
		}
	}
	#echo "<td bgcolor=$BGCOLOR></td>";
	echo '<td> </td>';
	echo "<td bgcolor=$BGCOLOR><b>Date of Next O/S Update</b></td>";
    echo "<td bgcolor=$BGCOLOR>" . $rarray['server_os_next_update']. "</td>";
	echo '</tr>';
	  


	// WEEK IN THE MONTH TO DO THE UPDATE AND CHOOSE SATURDAY OR SUNDAY TO PERFORM UPDATE
	echo '<tr>';
	echo "<tr><td bgcolor=$BGCOLOR><b>O/S Update week in the month</b></td>";
	
	echo "<td bgcolor=$BGCOLOR>";
	switch ($rarray['server_os_update_week']) {
    case 1:
		echo '<input type="radio" name="server_os_update_week" value="1" checked>1st ';
		echo '<input type="radio" name="server_os_update_week" value="2">2nd ';
		echo '<input type="radio" name="server_os_update_week" value="3">3rd ';
		echo '<input type="radio" name="server_os_update_week" value="4">4th </td>';
        break;
    case 2:
		echo '<input type="radio" name="server_os_update_week" value="1">1st ';
		echo '<input type="radio" name="server_os_update_week" value="2" checked>2nd ';
		echo '<input type="radio" name="server_os_update_week" value="3">3rd ';
		echo '<input type="radio" name="server_os_update_week" value="4">4th </td>';
        break;
    case 3:
		echo '<input type="radio" name="server_os_update_week" value="1">1st ';
		echo '<input type="radio" name="server_os_update_week" value="2">2nd ';
		echo '<input type="radio" name="server_os_update_week" value="3" checked>3rd ';
		echo '<input type="radio" name="server_os_update_week" value="4">4th </td>';
        break;
    case 4:
		echo '<input type="radio" name="server_os_update_week" value="1">1st ';
		echo '<input type="radio" name="server_os_update_week" value="2">2nd ';
		echo '<input type="radio" name="server_os_update_week" value="3">3rd ';
		echo '<input type="radio" name="server_os_update_week" value="4" checked>4th </td>';
        break;
	default:
		echo '<input type="radio" name="server_os_update_week" value="1" checked>1st ';
		echo '<input type="radio" name="server_os_update_week" value="2">2nd ';
		echo '<input type="radio" name="server_os_update_week" value="3">3rd ';
		echo '<input type="radio" name="server_os_update_week" value="4">4th </td>';
        break;
	}
	echo "<td></td>";
	echo "<td bgcolor=$BGCOLOR><b>TSM Version</b></td>";
    echo "<td bgcolor=$BGCOLOR>" . $rarray['server_tsm_ver']. "</td>";
	echo '</tr>';
	  


	// Choose Saturday or Sunday to perform update
	echo '<tr>';
	echo "<tr><td bgcolor=$BGCOLOR><b>O/S Update day</b></td>";
	
	echo "<td bgcolor=$BGCOLOR>";
	switch ($rarray['server_os_update_day']) {
    case 5:
		echo '<input type="radio" name="server_os_update_day" value="5" checked>Saturday ';
		echo '<input type="radio" name="server_os_update_day" value="6">Sunday </td>';
        break;
    case 6:
		echo '<input type="radio" name="server_os_update_day" value="5">Saturday ';
		echo '<input type="radio" name="server_os_update_day" value="6" checked>Sunday ';
        break;
	default:
		echo '<input type="radio" name="server_os_update_day" value="5" checked>Saturday ';
		echo '<input type="radio" name="server_os_update_day" value="6">Sunday </td>';
        break;
	}
	echo "<td></td>";
	#echo "<td bgcolor=$BGCOLOR></td>";
	echo "<td bgcolor=$BGCOLOR><b>TSM TDP</b></td>";
    echo "<td bgcolor=$BGCOLOR>" . $rarray['server_tsm_tdp']. "</td>";
	echo '</tr>';


	// IBM PVU
	echo '<tr>';
	echo "<td bgcolor=$BGCOLOR><b>IBM PVU Number</b></td>";
	echo "<td bgcolor=$BGCOLOR>";
	echo '<input type="text" name="server_pvu" size="6" value="' . $rarray["server_pvu"] . '" /></td>';	
	echo "<td></td>";
    echo "<td bgcolor=$BGCOLOR></td>";
    echo "<td bgcolor=$BGCOLOR></td>";
	echo '</tr>';



	//echo '<tr><td align=left colspan=5><hr width=500></td></tr>';
	echo '</table>';
}
	


// ================================================================================================
//                   Display Content of file receive as parameter
// ================================================================================================
function display_file( $nom_du_fichier ) {
	$url = htmlspecialchars($_SERVER['HTTP_REFERER']);
    echo "<a href='$url'>Back</a>";

	echo '<table style="background-color: #EFCFFE"  frame="border" border="0" width="700">';
	echo '<tr><td><pre>';
	///$myFile = "testFile.txt";
	//$fh = fopen($nom_du_fichier, 'r');
	//$theData = fgets($fh);
	//fclose($fh);
	//echo $theData;
	@readfile($nom_du_fichier);
	echo '</pre></td></tr>';
	echo '</table>';
}


	
// ================================================================================================
//                   Display Server Data used in General Server Information Page
// ================================================================================================
function display_server_info( $rarray ) {
	echo '<table frame="border" border="1" cellspacing="2" width="900">';
	
	// ======================= G E N E R A L    I N F O R M A T I O N ============================
    echo '<br>';
	echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
	echo '<tr><td colspan=5 align=center bgcolor="blue"><font color=#FFFFFF><b>General Information</b></font></td></tr>';
	echo '<tr>';
	$myheader = stripslashes($rarray["server_name"]) . '.'  . stripslashes($rarray["server_domain"]) ;
	$myheader = $myheader . ' - ' . stripslashes($rarray["server_desc"]) ;
	echo '<td width=120 align=left><b>Server</b></td>';
	echo '<td colspan=3 width=300 align=left>' . $myheader . '</td>';
	echo '</tr>';

	// ============== Server Type and Server Notes 
	echo '<td width=120 align=left><b>Server Type</b></td>';
	echo '<td width=300 align=left>' . stripslashes($rarray['server_type']) . '</td>';
   	echo '<td align=left><b>General Note</b></td>';
	echo '<td align=left>' . stripslashes($rarray["server_note"]) . '</td>';
	echo '</tr>';

	// Server Active/Inactive & DR Notes
	echo '<tr>';
	echo '<td width=150 align=left><b>Server Status</b></td>';
	if (stripslashes($rarray['server_active']) == 1 ) {
	   echo '<td>Active</td>';
	}else{
	   echo '<td>Inactive</td>' ;
	}
   	echo '<td align=left><b>D.R. Note</b></td>';
	echo '<td align=left>' . stripslashes($rarray["server_drnote"]) . '</td>';
	echo '</tr>';
	
	// Virtual Server & Server Recover at DR
	echo '<tr>';
	echo '<td width=150 align=left><b>Virtual Server</b></td>';
	if (stripslashes($rarray['server_vm']) == 1 ) {
	   echo '<td>Yes</td>';
	}else{
	   echo '<td>No</td>' ;
	}
   	echo '<td align=left><b>Recover at DR</b></td>';
	if (stripslashes($rarray['server_dr']) == 1 ) {
	   echo '<td>Yes</td>';
	}else{
	   echo '<td>No</td>' ;
	}
	echo '</tr>';
	
	// Edit Server Information & Operating System 
	echo '<tr>';
	echo '<td colspan=2 align=left><b><a href=/cfg/config_server_update.php?id=' . $rarray["server_name"] . '>Edit Server Information</a></b></td>';
	// Server O/S and Version number
	$myheader = stripslashes($rarray['server_os']) . ' ' . stripslashes($rarray['server_osver1']) . '.' ;
	$myheader = $myheader . stripslashes($rarray['server_osver2']) . '.' . stripslashes($rarray['server_osver3']);
	echo '<td width=200 align=left><b>Operating system</b></td>';
	echo '<td width=300 align=left>' . $myheader . '</td>';
	echo '</tr>';

	// Performance And Backup Links 
	echo '<tr>';
	echo '<td colspan=2 align=left><b><a href=/unix/server_performance.php?host=' . $rarray["server_name"] . '>View Graphic Performance</a></b></td>';
	#echo '<td width=150 align=left></td>';
	echo '<td colspan=2 align=left><b><a href=/unix/server_rcfiles.php?host=' . $rarray["server_name"] . '>View Backup results</a></b></td>';
	echo '</tr>';

	echo '</table>';

	// ============================================ N E T W O R K   I N F O R M A T I O N =================================================
    echo '<br>';
	echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
	echo '<tr><td colspan=3 align=center bgcolor="blue"><font color=#FFFFFF><b>Network Information</b></font></td></tr>';
	$myheader = stripslashes($rarray["server_ip1a"]) . '.' .stripslashes($rarray["server_ip1b"]) . '.' ;
	$myheader = $myheader . stripslashes($rarray["server_ip1c"]) . '.' . stripslashes($rarray["server_ip1d"]) ;
	echo '<tr><td width=170 align=left><b>Network Interface #1</b></td>';
	echo '<td width=300 align=left>' . $myheader . '</td>';
	echo '<td width=300 align=center><a href=server_view_text_file.php?file=data/hw/ifconfig&server=' . stripslashes($rarray["server_name"]) . '>' . 'View ifconfig command output'  . '</a></td>';
	echo '</tr>';
	$myheader = stripslashes($rarray["server_ip2a"]) . '.' .stripslashes($rarray["server_ip2b"]) . '.' ;
	$myheader = $myheader . stripslashes($rarray["server_ip2c"]) . '.' . stripslashes($rarray["server_ip2d"]) ;
	echo '<tr><td width=170 align=left><b>Network Interface #2</b></td>';
	echo '<td width=300 align=left>' . $myheader . '</td>';
	echo '<td width=300 align=center><a href=server_view_text_file.php?file=data/hw/netstat&server=' . stripslashes($rarray["server_name"]) . '>' . 'View netstat command output' . '</a></td>';
	echo '</tr>';
	$myheader = stripslashes($rarray["server_ip3a"]) . '.' .stripslashes($rarray["server_ip3b"]) . '.' ;
	$myheader = $myheader . stripslashes($rarray["server_ip3c"]) . '.' . stripslashes($rarray["server_ip3d"]) ;
	echo '<tr><td width=170 align=left><b>Network Interface #3</b></td>';
	echo '<td width=300 align=left>' . $myheader . '</td>';
	echo '<td width=300 align=center>' . ' '  . '</td>';
	echo '</tr>';
	echo '</table>';


	// ======================= H A R D W A R E    I N F O R M A T I O N ============================
    echo '<br>';
	echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
	echo '<tr><td colspan=5 align=center bgcolor="blue"><font color=#FFFFFF><b>Hardware & Filesystem Information</b></font></td></tr>';
	echo '<tr><td><b>Internal Disk</b></td>';
	echo '<td> ' . stripslashes($rarray["server_disk_int"]) . ' GB';
	echo '<td>   </td>';
	echo '<td align=left><b>Server Model   </b></td>';
	echo '<td> ' . stripslashes($rarray["server_model"]) . '</td>';
	echo '</tr>';
	echo '<td><b>External Disk</b></td>';
	echo '<td width=210>' . stripslashes($rarray["server_disk_ext"]) . ' GB';
	echo '<td>   </td>';
	echo '<td><b>Serial Number</b></td>';
	echo '<td> ' . stripslashes($rarray["server_serial"]) . '</td>';
	echo '</tr>';

	echo '<tr>';
	echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/pvs&server=' . stripslashes($rarray["server_name"]) . '>' . 'Physical Volume - pvs command output' . '</a></td>';
	echo '<td>   </td>';
	echo '<td><b>Memory</b></td>';
	echo '<td>'  . stripslashes($rarray["server_memory"]) . ' MB';
	echo '</tr>';

	echo '<tr>';
	echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/vgs&server=' . stripslashes($rarray["server_name"]) . '>' . 'Volume Group - vgs command output' . '</a></td>';
	echo '<td>   </td>';
	echo '<td><b>CPU</b></td>';
	echo '<td>' . stripslashes($rarray["server_cpu_nb"]) . ' X ' . stripslashes($rarray["server_cpu_speed"]) . ' Mhz</td>';
	echo '</tr>';

	echo '<tr>';
	echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/lvs&server=' . stripslashes($rarray["server_name"]) . '>' . 'Logical Volume - lvs command output' . '</a></td>';
	echo '</tr>';

	echo '<tr>';
	echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/df&server=' . stripslashes($rarray["server_name"]) . '>' . 'Filesystem - df command output' . '</a></td>';
	echo '</tr>';
	echo '</table>';
	


	// ======================= D I S A S T E R    R E C O V E R Y   I N F O R M A T I O N ============================
    echo '<br>';
	echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
	echo '<tr><td align=center colspan=5 bgcolor="blue"><font color=#FFFFFF><b>Disaster Recovery Information</b></font></td></tr>';


	# STORIX RECOVERY PROCEDURE
	if ( stripslashes($rarray['server_os']) == "Linux") {
		$DRDOC = 'data/dr/doc/dr_storix_restore.doc';
		$WFILE = SADM_WWW_DIR . $DRDOC;
		if (file_exists($WFILE)) {
			echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Storix Recovery Procedure (' . $WFILE . ').</a></b></td>';
		} else {
			echo '<tr><td colspan=5><b>Storix Recovery Procedure is missing (' . $WFILE . ').</b></td>';
		}
	}


	# SPECIFIC PROCEDURE FOR SERVER - IF FILE EXIST WITH NAME "DR_{SERVERNAME}.doc" THEN DISPLAY LINK
	$DRDOC = 'data/dr/doc/dr_' . stripslashes($rarray["server_name"]) . '.doc';
	$WFILE = SADM_WWW_DIR . $DRDOC;
	if (file_exists($WFILE)) {
		echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Specific Recovery procedure of ' . stripslashes($rarray["server_name"]) . ' (' . $WFILE . ').</a></b></td>';
	} else {
		echo '<tr><td colspan=5><b>Recovery procedure of ' . stripslashes($rarray["server_name"]) . ' is missing (' . $WFILE . ').</b></td>';
	}

	$DRDOC = 'data/dr/doc/dr_' . stripslashes($rarray["server_name"]) . '_a.doc';
	$WFILE = SADM_WWW_DIR . $DRDOC;
	if (file_exists($WFILE)) {
		echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Special note for recovering ' . stripslashes($rarray["server_name"]) . ' (' . $WFILE . ').</a></b></td>';
	}


	# ON LINUX - DISPLAY PROCEDURE TO RESTORE FILE WITH TSM
	if ( stripslashes($rarray['server_os']) == "Linux") {
		$FSREST = 'data/dr/doc/linux_filesystem_restore_script.doc';
		$WFILE = SADM_WWW_DIR . $FSREST;
		if (file_exists($WFILE)) {
			echo '<tr><td colspan=5><b><a href=/' . $FSREST . '>TSM Filesystem Restore Procedure (' . $WFILE . ').</a></b></td>';
		} else {
			echo '<tr><td colspan=5><b>Filesystem restore procedure with TSM is ' . stripslashes($rarray["server_name"]) . ' is missing (' . $WFILE . ').</b></td>';
		}
	}


	# ON AIX DISPLAY PROCEDURE TO RECREATE VOLUME GROUP
	if ( stripslashes($rarray['server_os']) == "Aix") {
		$DRDOC = 'data/dr/doc/aix_recreate_volume_group.doc';
		$WFILE = SADM_WWW_DIR . $DRDOC;
		if (file_exists($WFILE)) {
			echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Recreate volume group procedure (' . $WFILE . ').</a></b></td></tr>';
		} else {
			echo '<tr><td colspan=5><b>Recreate volume group procedure is missing (' . $WFILE . ').</b></td></tr>';
		}
	}

	# RESTORE KMA DOCUMENTATION FOR SERVER SPMQ1022
	if (( stripslashes($rarray['server_os']) == "Aix") and  ( stripslashes($rarray["server_name"]) == "spmq1022")) {
		$DRDOC = 'data/dr/doc/dr_restoring_kma_at_sungard.doc';
		$WFILE = SADM_WWW_DIR . $DRDOC;
		if (file_exists($WFILE)) {
			echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Restoring KMA at DR site (' . $WFILE . ').</a></b></td></tr>';
		} else {
			echo '<tr><td colspan=5><b>Procedure for restoring KMA at DR site is missing (' . $WFILE . ').</b></td></tr>';
		}
	}

	// Configuration cfg2html
	echo '<tr>';
	echo '<td colspan=5 align=left><b><a href=/unix/server_detail_config.php?host=' . $rarray["server_name"] . '>Detailled server configuration</a></b></td>';
	echo '</tr>';
	echo '<tr>';
	echo '<td colspan=5 align=left><b><a href=/unix/server_system_config.php?host=' . $rarray["server_name"] . '>Summarized server configuration</a></b></td>';
	echo '</tr>';
	echo '</table>';

	echo '</table>';
}
?>
