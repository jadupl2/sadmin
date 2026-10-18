<?php
echo "I am IN" ;
// Handle POST form-urlencoded or raw data
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    echo "ok POST";  
    $input = file_get_contents('php://input');
    $data = $_POST; // for standard -d "key=value"
    
    // Log or process data
    file_put_contents('received_data.txt', print_r($data, true) . "\nRaw: " . $input);
    echo "Data received successfully.";
}
// Handle PUT requests
elseif ($_SERVER['REQUEST_METHOD'] == 'PUT') {
    $putdata = fopen("php://input", "r");
    $fp = fopen("uploaded_file.txt", "w");
    while ($data = fread($putdata, 1024)) {
        fwrite($fp, $data);
    }
    fclose($putdata);
    fclose($fp);
    echo "File PUT received.";
}
?>

