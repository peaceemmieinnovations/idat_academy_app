<?php
/**
 * Shared initialisation for all IDAT Academy API endpoints.
 * Include this at the top of every endpoint file.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Key');

// Handle CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

const API_KEY = 'idat_live_k8x2m9p4q7w1e5r3t6y0u';

// ─── Database ────────────────────────────────────────────────────────────
// Adjust these to match your server's database credentials
const DB_HOST = 'localhost';
const DB_NAME = 'idat_academy';
const DB_USER = 'root';
const DB_PASS = '';

function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]
        );
    }
    return $pdo;
}

// ─── Auth helpers ────────────────────────────────────────────────────────

/** Return JSON error and stop. */
function jsonError(string $message, int $status = 400): void {
    http_response_code($status);
    echo json_encode(['error' => $message, 'status' => $status]);
    exit;
}

/** Read JSON body from php://input */
function jsonBody(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        jsonError('Invalid JSON body', 400);
    }
    return $data;
}

/**
 * Authenticate the request.
 * Returns the authenticated user row (with id, account_type, role, etc.)
 * Checks X-API-Key header first (admin bypass), then Bearer token.
 */
function authenticate(): array {
    $apiKey = $_SERVER['HTTP_X_API_KEY'] ?? '';
    if ($apiKey === API_KEY) {
        // API key grants admin-level access — return a minimal admin stub
        return ['id' => 0, 'account_type' => 'admin', 'role' => 'admin', 'email' => 'api@idat.ng'];
    }

    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (empty($authHeader)) {
        jsonError('Authentication required. Provide X-API-Key or Bearer token.', 401);
    }

    if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $m)) {
        jsonError('Invalid Authorization header format. Use: Bearer <token>', 401);
    }

    $token = $m[1];
    $db = getDB();

    // Look up the token in your personal_access_tokens table
    // Adjust table/column names to match your schema
    $stmt = $db->prepare('
        SELECT t.tokenable_id AS user_id, t.tokenable_type,
               u.*
        FROM personal_access_tokens t
        JOIN users u ON u.id = t.tokenable_id
        WHERE t.token = ? AND t.expires_at > NOW()
        LIMIT 1
    ');
    $stmt->execute([$token]);
    $user = $stmt->fetch();

    if (!$user) {
        // Alternative: try hashed token lookup (Laravel stores hash of token)
        $hashed = hash('sha256', $token);
        $stmt = $db->prepare('
            SELECT t.tokenable_id AS user_id,
                   u.*
            FROM personal_access_tokens t
            JOIN users u ON u.id = t.tokenable_id
            WHERE t.token = ? AND t.expires_at > NOW()
            LIMIT 1
        ');
        $stmt->execute([$hashed]);
        $user = $stmt->fetch();
    }

    if (!$user) {
        jsonError('Invalid or expired token.', 401);
    }

    return $user;
}

/** Authorize: ensure the authenticated user has one of the given account types. */
function authorize(array $user, array $allowedTypes): void {
    if ($user['account_type'] === 'admin') return; // admin bypasses
    if (!in_array($user['account_type'], $allowedTypes, true)) {
        jsonError('Forbidden: insufficient permissions.', 403);
    }
}
