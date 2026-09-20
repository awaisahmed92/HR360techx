-- Company-wide dashboard status / holiday / announcement feed
USE hr360_demo;

CREATE TABLE IF NOT EXISTS status_posts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id INT UNSIGNED NOT NULL DEFAULT 0,
  author VARCHAR(190) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(40) NOT NULL DEFAULT 'status',
  likes_json TEXT NULL,
  comments_json TEXT NULL,
  created_at DATETIME NULL,
  KEY idx_type_created (type, created_at),
  KEY idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
