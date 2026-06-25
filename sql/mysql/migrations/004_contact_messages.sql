-- MySQL: 前台聯絡留言表（既有庫請執行本檔一次）
CREATE TABLE IF NOT EXISTS `contact_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `visitor_name` varchar(100) NOT NULL COMMENT '稱呼',
  `contact` varchar(255) DEFAULT NULL COMMENT '郵箱或電話',
  `content` text NOT NULL COMMENT '留言內容',
  `locale` varchar(16) NOT NULL DEFAULT 'zh-TW' COMMENT '介面語系',
  `ip` varchar(50) DEFAULT NULL COMMENT '來源IP',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0未讀 1已讀(預留)',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cm_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='前台聯絡留言';
