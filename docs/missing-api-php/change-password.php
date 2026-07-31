<?php
/**
 * POST /api/change-password
 *
 * Allows an authenticated student or staff member to change their password.
 *
 * Request:  { "old_password": "...", "new_password": "..." }
 * Success:  { "message": "Password changed successfully" }
 * Error:    { "error": "...", "status": 400 }
 */

require_once __DIR__ . '/init.php';

// Only POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed. Use POST.', 405);
}

$user  = authenticate();
$body  = jsonBody();
$oldPw = trim($body['old_password'] ?? '');
$newPw = trim($body['new_password'] ?? '');

if ($oldPw === '' || $newPw === '') {
    jsonError('Both old_password and new_password are required.', 400);
}

if (strlen($newPw) < 6) {
    jsonError('New password must be at least 6 characters.', 400);
}

$db = getDB();

// Determine which table the user belongs to
if ($user['account_type'] === 'student') {
    $table = 'students';
    $idCol = 'id';
} else {
    $table = 'staff';
    $idCol = 'id';
}

// Fetch current password hash
$stmt = $db->prepare("SELECT password FROM {$table} WHERE {$idCol} = ? LIMIT 1");
$stmt->execute([$user['id']]);
$row = $stmt->fetch();

if (!$row) {
    jsonError('User not found.', 404);
}

// Verify old password
if (!password_verify($oldPw, $row['password'])) {
    jsonError('Current password is incorrect.', 403);
}

// Update to new password
$newHash = password_hash($newPw, PASSWORD_BCRYPT, ['cost' => 12]);
$stmt = $db->prepare("UPDATE {$table} SET password = ? WHERE {$idCol} = ?");
$stmt->execute([$newHash, $user['id']]);

// Optionally: revoke all existing tokens so user must re-login
// $db->prepare('DELETE FROM personal_access_tokens WHERE tokenable_id = ? AND tokenable_type = ?')
//    ->execute([$user['id'], $user['tokenable_type'] ?? 'App\\Models\\' . ucfirst($table)]);

echo json_encode(['message' => 'Password changed successfully']);
