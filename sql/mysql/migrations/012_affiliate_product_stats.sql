-- 商品推广链接统计（点击 / 成交 / 佣金）
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `affiliate_product_stats` (
  `user_id` int(11) NOT NULL COMMENT '推广人用户ID',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '商品ID，0=首页推广',
  `click_count` int(11) NOT NULL DEFAULT 0 COMMENT '链接点击次数',
  `order_count` int(11) NOT NULL DEFAULT 0 COMMENT '含该商品的成交订单数',
  `commission_total` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '累计佣金(按比例分摊)',
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`, `product_id`),
  KEY `idx_aps_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='推广链接按商品统计';
