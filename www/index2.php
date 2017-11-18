<?php
# Connect to MySQL DataBase
$con = mysqli_connect('localhost','sadmin','Nimdas17!','sadmin');
if (mysqli_connect_errno()) {
    echo ">>>>> Failed to connect to MySQL Database: '" . SADM_DBNAME . "'<br/>";
    echo ">>>>> Error (" . mysqli_connect_errno() . ") " . mysqli_connect_error() . "'<br/>";
}else{
    echo "\nopen db work";
}

$sql = 'SELECT * FROM server ;';                                  # Construct SQL Statement
echo "\nSQL = " . $sql . "\n";
#echo "con = $con" ;

if ( ! $result=mysqli_query($con,$sql)) {                       # Execute Update Row SQL
    $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
    $err_msg1 = "Error on select server\nError (";                  # Advise User Message 
    $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
    $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
    $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
    echo $err_msg1 . $err_msg2 . $err_msg3 . $err_msg4;         # Display Msg. Box for User
    exit;
}
while ($row = mysqli_fetch_assoc($result)) {                                                   # Incr Line Counter
    print_r ($row);
}

mysqli_free_result($result);                                        # Free result set 
mysqli_close($con);                                                 # Close Database Connection
?>

