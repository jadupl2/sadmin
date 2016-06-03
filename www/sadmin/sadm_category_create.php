<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/connection.php'); ?>
<?php include      ($_SERVER['DOCUMENT_ROOT'].'/includes/header.php')  ; ?>
<?php require_once ($_SERVER['DOCUMENT_ROOT'].'/includes/functions.php'); ?>
<?php include($_SERVER['DOCUMENT_ROOT'].'/cfg/config_menu.php')  ; ?>

<script language="JavaScript1.2">
function popup(mess) {
    alert(mess);
    return true;
}
</script>

<?php 
if  (isset($_POST['submitted'])) { 
    foreach($_POST AS $key => $value) {
      $_POST[$key] = mysql_real_escape_string($value);
    } 
    $sql = "INSERT INTO `sysinfo`.`servers` (
            `server_no` ,
            `server_vm` ,
            `server_name` ,
            `server_desc` ,
            `server_type` ,
            `server_os` ,
            `server_active` ,
            `server_graphic` ,
            `server_upddate` ,
            `server_domain` ,
            `server_drnote` ,
            `server_note` ,
            `server_user_admin` ,
            `server_storix` ,
            `server_doc_only` ,
            `server_os_update`      ,
            `server_os_update_mth`  ,
            `server_os_update_week` ,
            `server_os_update_day`  ,
            `server_use_ad` ,
            `server_pvu` ,
            `server_dr`
            )
            VALUES (
            NULL ,
            '{$_POST['server_vm']}',
            '{$_POST['server_name']}',
            '{$_POST['server_desc']}',
            '{$_POST['server_type']}',
            '{$_POST['server_os']}',
            '{$_POST['server_active']}',
            '{$_POST['server_graphic']}',
            '{$_POST['server_upddate']}',
            '{$_POST['server_domain']}',
            '{$_POST['server_drnote']}',
            '{$_POST['server_note']}',
            '{$_POST['server_user_admin']}',
            '{$_POST['server_storix']}',
            '{$_POST['server_doc_only']}',
            '{$_POST['server_os_update']}',
            '{$_POST['server_os_update_mth']}',
            '{$_POST['server_os_update_week']}',
            '{$_POST['server_os_update_day']}',
            '{$_POST['server_use_ad']}',
            '{$_POST['server_pvu']}',
            '{$_POST['server_dr']}'
            )";


    mysql_query($sql) or die(mysql_error());
    $CMD  = "touch /tmp/update_host_file.activate" ;
    $outline    = exec ("$CMD", $array_out, $retval);
    header("location:config_server_edit_list.php");
} 
?>

<form action='' method='POST'>
<?php
$row = array("server_name" => ''         ,
		"server_desc" => ''         ,
		"server_type" => 'Prod'     ,
		"server_os"   => 'Linux'    ,
		"server_graphic" => 1   ,
		"server_domain" => 'slac.ca'  ,
		"server_user_admin" => 1        ,
		"server_monitor" => 1  ,
		"server_storix" => 0  ,
		"server_doc_only" => 0  ,
		"server_use_ad" => 0  ,
		"server_dr" => 0        ,
        "server_os_update" => 1 ,
        "server_os_update_mth"  => 6 , 
        "server_os_update_week" => 1 , 
        "server_os_update_day"  => 5 ,
        "server_pvu"  => 50 ,
		"server_active" => 1 );

//set_record_default_value($row);
display_record( $row , "Create Unix - Server information");
?>
<p><input type='submit' value='Save' /><input type='hidden' value='1' name='submitted' /> 
</form>

<a href='/cfg/config_server_edit_list.php'><button name="cancel" value="0" type="button">Cancel</button></a>
<?php require      ($_SERVER['DOCUMENT_ROOT'].'/includes/footer.php')  ; ?>

