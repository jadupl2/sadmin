<?php
$uploadDir = __DIR__ . '/saved_files/';

// Create directory if it doesn't exist
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// Check if a file was uploaded via POST
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_FILES['file'])) {
    $file = $_FILES['file'];
    $targetPath = $uploadDir . basename($file['name']);

    // Move the file from temp storage to your saved directory
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        echo json_encode(["status" => "success", "filename" => $file['name']]);
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Failed to save file."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "No file received."]);
}

