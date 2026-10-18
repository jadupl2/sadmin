<?php
// Define where you want to save the incoming logs
define('LOG_FILE', __DIR__ . '/received_payloads.log');

// 1. Capture the raw input stream (works for JSON, XML, or plain text)
$rawData = file_get_contents('php://input');

// 2. Fallback to standard POST data if the raw body is empty (works for standard form data)
if (empty($rawData) && !empty($_POST)) {
    $rawData = json_encode($_POST);
}

// 3. Check if we actually received anything
if (!empty($rawData)) {
    // Format the log entry with a timestamp
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[{$timestamp}] Received payload:\n" . $rawData . "\n" . str_repeat('-', 40) . "\n";

    // Save the payload to the log file (FILE_APPEND ensures data isn't overwritten)
    if (file_put_contents(LOG_FILE, $logEntry, FILE_APPEND | LOCK_EX) !== false) {
        // Respond with success
        http_response_code(200);
        echo json_encode(["status" => "success", "message" => "Payload saved successfully."]);
    } else {
        // Respond with server error if writing failed
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Failed to write payload to file."]);
    }
} else {
    // Respond with a bad request error if no data was sent
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "No data received."]);
}
