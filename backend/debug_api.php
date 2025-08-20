<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'debug_info' => [
        'request_method' => $_SERVER['REQUEST_METHOD'] ?? 'NOT_SET',
        'request_uri' => $_SERVER['REQUEST_URI'] ?? 'NOT_SET',
        'script_name' => $_SERVER['SCRIPT_NAME'] ?? 'NOT_SET',
        'php_self' => $_SERVER['PHP_SELF'] ?? 'NOT_SET',
        'path_info' => $_SERVER['PATH_INFO'] ?? 'NOT_SET',
        'query_string' => $_SERVER['QUERY_STRING'] ?? 'NOT_SET',
        'http_host' => $_SERVER['HTTP_HOST'] ?? 'NOT_SET',
        'http_user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'NOT_SET',
        'remote_addr' => $_SERVER['REMOTE_ADDR'] ?? 'NOT_SET',
        'server_name' => $_SERVER['SERVER_NAME'] ?? 'NOT_SET',
        'server_port' => $_SERVER['SERVER_PORT'] ?? 'NOT_SET',
        'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? 'NOT_SET'
    ],
    'headers' => getallheaders(),
    'post_data' => file_get_contents('php://input'),
    'get_data' => $_GET,
    'timestamp' => date('Y-m-d H:i:s')
]);
?> 