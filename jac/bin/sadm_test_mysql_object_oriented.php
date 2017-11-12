<?php
$mysqli = new mysqli("localhost", "sadmin", "Nimdas17!", "sadmin");

/* check connection */
if ($mysqli->connect_errno) {
    printf("Connect failed: %s\n", $mysqli->connect_error);
    exit();
}

$query = "SELECT * from server_category";

if ($result = $mysqli->query($query)) {

    /* fetch associative array */
    while ($row = $result->fetch_assoc()) {
        printf ("%s (%s)\n", $row["cat_code"], $row["cat_desc"]);
    }

    /* free result set */
    $result->free();
}

/* close connection */
$mysqli->close();
?>
