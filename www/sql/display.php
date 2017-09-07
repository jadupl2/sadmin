<?php
$db = new SQLite3("/sadmin/www/db/sadm.db") or die('Unable to open database');

$query = <<<EOD
  CREATE TABLE IF NOT EXISTS users (
    username STRING PRIMARY KEY,
    password STRING)
EOD;
$db->exec($query) or die('Create db failed');


$user = "Jacques";
$pass = "Password";

$query = <<<EOD
  INSERT INTO users VALUES ( '$user', '$pass' );
  INSERT INTO users VALUES ( 'John', 'secret' );
  INSERT INTO users VALUES ( 'Mary', 'notsosecret' );
  INSERT INTO users VALUES ( 'Chris', 'secret');  
EOD;
$db->exec($query) or die("Unable to add user $user");

$result = $db->query('SELECT * FROM users') or die('Query failed');
while ($row = $result->fetchArray())
{
  echo "User: {$row['username']}\nPasswd: {$row['password']}\n";
}
?>

