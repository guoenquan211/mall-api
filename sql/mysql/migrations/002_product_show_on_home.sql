-- MySQL / MariaDB：首页「本季主推」仅展示 show_on_home=1 的商品
ALTER TABLE `products`
  ADD COLUMN `show_on_home` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1=在首页本季主推展示' AFTER `status`;
