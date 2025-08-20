<?php
class ResponseUtil {
    public static function success($message, $data = null, $statusCode = 200) {
        http_response_code($statusCode);
        
        $response = [
            'success' => true,
            'message' => $message,
            'timestamp' => date('Y-m-d H:i:s')
        ];
        
        if ($data !== null) {
            $response['data'] = $data;
        }
        
        return $response;
    }
    
    public static function error($message, $statusCode = 400, $errors = null) {
        http_response_code($statusCode);
        
        $response = [
            'success' => false,
            'message' => $message,
            'timestamp' => date('Y-m-d H:i:s')
        ];
        
        if ($errors !== null) {
            $response['errors'] = $errors;
        }
        
        return $response;
    }
    
    public static function sendSuccess($message, $data = null, $statusCode = 200) {
        $response = self::success($message, $data, $statusCode);
        echo json_encode($response);
        exit;
    }
    
    public static function sendError($message, $statusCode = 400, $errors = null) {
        $response = self::error($message, $statusCode, $errors);
        echo json_encode($response);
        exit;
    }
    
    public static function sendValidationErrors($errors) {
        $response = self::error('Validation failed', 422, $errors);
        echo json_encode($response);
        exit;
    }
    
    public static function sendNotFound($message = 'Resource not found') {
        $response = self::error($message, 404);
        echo json_encode($response);
        exit;
    }
    
    public static function sendUnauthorized($message = 'Unauthorized access') {
        $response = self::error($message, 401);
        echo json_encode($response);
        exit;
    }
    
    public static function sendForbidden($message = 'Access forbidden') {
        $response = self::error($message, 403);
        echo json_encode($response);
        exit;
    }
    
    public static function sendServerError($message = 'Internal server error') {
        $response = self::error($message, 500);
        echo json_encode($response);
        exit;
    }
    
    public static function sendMethodNotAllowed($message = 'Method not allowed') {
        $response = self::error($message, 405);
        echo json_encode($response);
        exit;
    }
    
    public static function sendTooManyRequests($message = 'Too many requests') {
        $response = self::error($message, 429);
        echo json_encode($response);
        exit;
    }
}
?> 