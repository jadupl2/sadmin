<?php
$link = mysqli_connect("localhost", "sadmin", "Nimdas17!", "sadmin");

/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}

$query = "SELECT * from server_category";

if ($result = mysqli_query($link, $query)) {

    /* fetch associative array */
	while ($row = mysqli_fetch_assoc($result)) {
		printf ("%s (%s)\n", $row["cat_code"], $row["cat_desc"]);
    }

/* free result set */
mysqli_free_result($result);
}

/* close connection */
mysqli_close($link);
?>
