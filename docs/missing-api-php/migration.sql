-- ============================================================
-- Migration: Add tables needed by missing API endpoints
-- ============================================================

-- 1. Device tokens for push notifications
--    Used by: POST /api/notifications/devices
--             POST /api/notifications/devices/remove
-- ============================================================
CREATE TABLE IF NOT EXISTS `user_devices` (
    `id`          INT           AUTO_INCREMENT PRIMARY KEY,
    `user_id`     INT           NOT NULL,
    `user_type`   VARCHAR(20)   NOT NULL COMMENT 'student or staff',
    `fcm_token`   VARCHAR(255)  NOT NULL,
    `platform`    VARCHAR(20)   DEFAULT 'android' COMMENT 'android or ios',
    `created_at`  DATETIME      DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_fcm_token` (`fcm_token`),
    INDEX `idx_user` (`user_id`, `user_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 2. If you don't already have a personal_access_tokens table
--    (Laravel Sanctum-style), create one for Bearer token auth.
--    Used by: init.php token lookup
-- ============================================================
CREATE TABLE IF NOT EXISTS `personal_access_tokens` (
    `id`             BIGINT        AUTO_INCREMENT PRIMARY KEY,
    `tokenable_type` VARCHAR(255)  NOT NULL,
    `tokenable_id`   BIGINT        NOT NULL,
    `name`           VARCHAR(255)  NOT NULL DEFAULT 'auth_token',
    `token`          VARCHAR(64)   NOT NULL UNIQUE,
    `abilities`      TEXT          NULL,
    `expires_at`     DATETIME      NULL,
    `created_at`     DATETIME      DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_tokenable` (`tokenable_type`, `tokenable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 3. Ensure your users tables have a `password` column with bcrypt hash
--    Used by: POST /api/change-password
--
--    If your students table doesn't have a password column:
--    ALTER TABLE students ADD COLUMN password VARCHAR(255) NOT NULL AFTER email;
--
--    If your staff table doesn't have a password column:
--    ALTER TABLE staff ADD COLUMN password VARCHAR(255) NOT NULL AFTER email;
