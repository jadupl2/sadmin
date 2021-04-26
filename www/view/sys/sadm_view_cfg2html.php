<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
/*
* ==================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  template.php
*   Version  :  1.5
*   Date     :  14 April 2016
*   Requires :  php
*
*   Copyright (C) 2016 Jacques Duplessis <sadmlinux@gmail.com>
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
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');
?> 


<?php
    if (! isset($_GET['net']) ) { 
       echo "<br>No Subnet received\n<br>Correct the situation and retry request\n";
       echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
       exit ;
    }    
    $SUBNET = $_GET['net'];
    
    $subnet_file =  SADM_WWW_NET_DIR . "/subnet_" . $SUBNET . ".txt";
    if (! file_exists($subnet_file))  {
       echo "<br>The subnet file " . $subnet_file . " does not exist.\n";
       echo "<br>Correct the situation and retry request\n";
       echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>\n";
       exit ;
    }
    
    sadm_page_heading ("Subnet ${SUBNET}/24");

    
    $HDR_BGCOLOR="#462066"; $FNT_COLOR="#FFFFFF";
    $HDR_COLOR="bgcolor=$HDR_BGCOLOR><font color=$FNT_COLOR";

    echo "<center><br><table width=90% border=0>";
    echo "<tr>";
    echo "<td width=110  align=center $HDR_COLOR><b>IP</b></td>";
    echo "<td width=70   align=center $HDR_COLOR><b>Ping?</b></td>";
    echo "<td width=150  align=center $HDR_COLOR><b>Hostname</b></td>";
    echo "<td width=110  align=center $HDR_COLOR><b>IP</b></td>";
    echo "<td width=70   align=center $HDR_COLOR><b>Ping?</b></td>";
    echo "<td width=150  align=center $HDR_COLOR><b>Hostname</b></td>";
    echo "<td width=110  align=center $HDR_COLOR><b>IP</b></td>";
    echo "<td width=70   align=center $HDR_COLOR><b>Ping?</b></td>";
    echo "<td width=150  align=center $HDR_COLOR><b>Hostname</b></td>";
    echo "</tr>";
	
    $fh = fopen($subnet_file, "r") or exit("Unable to open file" . $subnet_file);
	
            $FREE_COLOR="#FCF4D9" ;
            $DEAD_COLOR="#FFB85F" ;
            $USED_COLOR="#8ED2C9" ;
            $count=0;
            $total=0;
            while(!feof($fh)) {
                $count = $count + 1;
                $total = $total + 1;
                list($wip, $wstatus, $wname) = explode(",", fgets($fh));
                $wname  = trim($wname);
                $wstatus= trim($wstatus);

                $BGCOLOR=$USED_COLOR ;
                if  ($wstatus == "No") {
                    if (strlen($wname) != 0) {
                        $BGCOLOR = $DEAD_COLOR ;
                    }else{
                        $BGCOLOR = $FREE_COLOR ;
                        $wname = "Free" ;
                    }
                }
        
                switch ($count) {
                    case 1 :
                        echo "<tr>";
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wip     . "</td>";
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wstatus . "</td>";
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wname   . "</td>";
                        break;
                    case 2 :
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wip     . "</td>";
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wstatus . "</td>";
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wname   . "</td>";
                        break;
                    case 3 :
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wip     . "</td>";
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wstatus . "</td>";
                        echo "<td align='center' bgcolor=$BGCOLOR>" . $wname   . "</td>";
                        echo "</tr>";
                        $count=0;
                        break;
                }
            }
            fclose($fh);
            echo "</table></center><br>";
?>

<?php include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ; ?>
