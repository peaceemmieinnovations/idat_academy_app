# Missing API Endpoints — Pure PHP

These 3 endpoints are missing from the idat.ng API. Drop them into your
project and route requests accordingly.

## Files

```
init.php                    # DB connection, auth, helpers (shared)
change-password.php         # POST /api/change-password
notifications-devices.php   # POST /api/notifications/devices
                            # POST /api/notifications/devices/remove
migration.sql               # SQL to create required tables
```

## Integration

### Option A: Apache .htaccess routing

Place the files in your API root (e.g. `/api/`) and add to `.htaccess`:

```
RewriteEngine On

# Change password
RewriteCond %{REQUEST_URI} ^/api/change-password$
RewriteRule ^(.*)$ change-password.php [L]

# Device tokens
RewriteCond %{REQUEST_URI} ^/api/notifications/devices(/remove)?$
RewriteRule ^(.*)$ notifications-devices.php [L]
```

### Option B: Simple router file

Create `api/router.php`:

```php
<?php
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = rtrim($uri, '/');

switch (true) {
    case $uri === '/api/change-password':
        require __DIR__ . '/change-password.php';
        break;
    case $uri === '/api/notifications/devices':
    case $uri === '/api/notifications/devices/remove':
        require __DIR__ . '/notifications-devices.php';
        break;
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Not found', 'status' => 404]);
}
```

Then in `.htaccess`:
```
RewriteRule ^api/(.*)$ api/router.php [QSA,L]
```

## Database

Run `migration.sql` to create the required tables.
Adjust column types to match your existing schema.
