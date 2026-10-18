echo "I Am in !" 
<br>
<?php
// Handle POST form-urlencoded or raw data
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    echo "A1"; 
    $input = file_get_contents('php://input');
    $data = $_POST; // for standard -d "key=value"
    echo "A22; 
    
    // Log or process data
    file_put_contents('received_data.txt', print_r($data, true) . "\nRaw: " . $input);
    echo "Data received successfully.";
}
?>
