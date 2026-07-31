<?php
/**
 * POST /api/notifications/devices
 * POST /api/notifications/devices/remove
 *
 * Register or unregister a Firebase Cloud Messaging device token
 * so push notifications can be delivered to the user's device.
 *
 * Register:
 *   Body: { "token": "fcm_token_abc123", "platform": "android" }
 *   Response: { "message": "Device registered" }
 *
 * Remove:
 *   Body: { "token": "fcm_token_abc123" }
 *   Response: { "message": "Device removed" }
 */

require_once __DIR__ . '/init.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed. Use POST.', 405);
}

$user = authenticate();
$body = jsonBody();
$token = trim($body['token'] ?? '');

if ($token === '') {
    jsonError('Field "token" is required.', 400);
}

// Determine if this is register or remove based on the URL path.
// The endpoint rewriting maps:
//   notifications/devices       → register
//   notifications/devices/remove → unregister
$uri = $_SERVER['REQUEST_URI'];
$isRemove = str_contains($uri, '/remove');

$db = getDB();

// Adjust table/column names to match your schema.
// Expected schema:
//   CREATE TABLE user_devices (
//       id          INT AUTO_INCREMENT PRIMARY KEY,
//       user_id     INT NOT NULL,
//       user_type   VARCHAR(20) NOT NULL,  -- 'student' or 'staff'
//       fcm_token   VARCHAR(255) NOT NULL,
//       platform    VARCHAR(20) DEFAULT 'android',
//       created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
//       updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
//       UNIQUE KEY unique_token (fcm_token)
//   );

$userType = ($user['account_type'] === 'student') ? 'student' : 'staff';

if ($isRemove) {
    // Remove the device token
    $stmt = $db->prepare('
        DELETE FROM user_devices
        WHERE fcm_token = ? AND user_id = ? AND user_type = ?
    ');
    $stmt->execute([$token, $user['id'], $userType]);

    echo json_encode(['message' => 'Device removed']);
    exit;
}

// Register / upsert device token
$platform = trim($body['platform'] ?? 'android');
if (!in_array($platform, ['android', 'ios'], true)) {
    $platform = 'android';
}

$stmt = $db->prepare('
    INSERT INTO user_devices (user_id, user_type, fcm_token, platform, created_at, updated_at)
    VALUES (?, ?, ?, ?, NOW(), NOW())
    ON DUPLICATE KEY UPDATE
        user_id   = VALUES(user_id),
        user_type = VALUES(user_type),
        platform  = VALUES(platform),
        updated_at = NOW()
');
$stmt->execute([$user['id'], $userType, $token, $platform]);

echo json_encode(['message' => 'Device registered']);
