<?php
// 1. Create a database connection
$connString = "host=".DB_SERVER." dbname=".DB_NAME." user=".DB_USER." password=".DB_PASS ;

$connection = pg_connect($connString);
if (!$connection) { die("Database connection failed: " . mysql_error()); }
?>
