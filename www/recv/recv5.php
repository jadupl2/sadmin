<?php
// Check if the request is a POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Grab individual form parameters
    $username = isset($_POST['username']) ? $_POST['username'] : 'Unknown';
    $message = isset($_POST['message']) ? $_POST['message'] : '';

    // Format how you want the data saved in the text file
    $logEntry = date('Y-m-d H:i:s') . " - User: $username | Message: $message\n";

    // Append the data to data.txt
    // FILE_APPEND keeps previous data; LOCK_EX prevents concurrent write errors
    file_put_contents('data.txt', $logEntry, FILE_APPEND | LOCK_EX);

    echo "Data successfully saved.\n";
} else {
    echo "Invalid request method.\n";
}
?>

