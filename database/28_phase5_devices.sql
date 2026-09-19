-- Phase 5: ensure biometric device tables exist (idempotent).
-- ZKTeco ingest remains server-side; Flutter only reads/configures these.

CREATE TABLE IF NOT EXISTS `biometric_devices` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `device_type` varchar(100) DEFAULT NULL,
  `serial_number` varchar(100) NOT NULL,
  `ip_address` varchar(50) NOT NULL,
  `port` int NOT NULL DEFAULT 80,
  `protocol` varchar(50) NOT NULL DEFAULT 'http',
  `protocol_config` text,
  `endpoint_url` varchar(255) DEFAULT NULL,
  `employee_identifier` varchar(50) NOT NULL DEFAULT 'employee_id',
  `timezone` varchar(50) NOT NULL DEFAULT 'Asia/Karachi',
  `status` enum('active','inactive','testing','error') NOT NULL DEFAULT 'inactive',
  `last_sync` datetime DEFAULT NULL,
  `last_error` text,
  `test_result` text,
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `serial_number` (`serial_number`),
  KEY `ip_address` (`ip_address`),
  KEY `is_active` (`is_active`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `device_attendance` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` varchar(100) DEFAULT NULL,
  `employee_code` varchar(50) NOT NULL,
  `employee_id` int UNSIGNED DEFAULT NULL,
  `punch_time` datetime NOT NULL,
  `punch_type` enum('in','out','break_in','break_out') NOT NULL DEFAULT 'in',
  `verify_mode` varchar(50) DEFAULT NULL,
  `device_name` varchar(100) DEFAULT NULL,
  `raw_data` text,
  `processed` tinyint(1) NOT NULL DEFAULT 0,
  `processed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_employee_code` (`employee_code`),
  KEY `idx_employee_id` (`employee_id`),
  KEY `idx_punch_time` (`punch_time`),
  KEY `idx_processed` (`processed`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
