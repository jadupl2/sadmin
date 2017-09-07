<?php
  try
  {
    //open the database
    $db = new PDO('sqlite:/sadmin/www/db/sadm.db');

    //create the database
    $db->exec("CREATE TABLE server (
            Id INTEGER PRIMARY KEY, 
            sname TEXT, 
            sdate_creation TEXT, 
            sactive INTEGER
            ) ");    

    //insert some data...
    $db->exec(" INSERT INTO server (
                sname, sdate_creation, 
                sactive) 
                VALUES (
                'holmes' , '2017-09-01 16:44:56',
                1
                ); " .
               "INSERT INTO server (sname, sdate_creation, sactive) VALUES ('nomad'  , '2017-09-01 16:44:56', 1); " .
               "INSERT INTO server (sname, sdate_creation, sactive) VALUES ('centos7', '2017-09-01 16:44:56', 0); ");

    //now output the data to a simple html table...
    print "<table border=1>";
    print "<tr><td>Id</td><td>serverName</td><td>creationDate</td><td>Active</td></tr>";
    $result = $db->query('SELECT * FROM server');
    foreach($result as $row)
    {
      print "<tr><td>".$row['Id']."</td>";
      print "<td>".$row['sname']."</td>";
      print "<td>".$row['sdate_creation']."</td>";
      print "<td>".$row['sactive']."</td></tr>";
    }
    print "</table>";

    // Updating
    #$update = "UPDATE server SET sactive = 2 WHERE sactive = 1";
    #$database->exec($update);
    $result = $db->query('UPDATE server SET sactive = 2 WHERE sactive = 1');

        //now output the data to a simple html table...
        print "<table border=1>";
        print "<tr><td>Id</td><td>serverName</td><td>creationDate</td><td>Active</td></tr>";
        $result = $db->query('SELECT * FROM server');
        foreach($result as $row)
        {
          print "<tr><td>".$row['Id']."</td>";
          print "<td>".$row['sname']."</td>";
          print "<td>".$row['sdate_creation']."</td>";
          print "<td>".$row['sactive']."</td></tr>";
        }
        print "</table>";
    // close the database connection
    $db = NULL;
  }
  catch(PDOException $e)
  {
    print 'Exception : '.$e->getMessage();
  }
?>

