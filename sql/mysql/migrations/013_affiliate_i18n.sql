-- 分销配置多语言字段（繁中 + English）
SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS `mall_add_column`;
DELIMITER $$
CREATE PROCEDURE `mall_add_column`(
    IN p_table VARCHAR(64),
    IN p_col VARCHAR(64),
    IN p_def TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = p_table
          AND COLUMN_NAME = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

CALL mall_add_column('affiliate_program_config', 'level1_name_en', "varchar(64) DEFAULT NULL COMMENT '一级等级名(英文)' AFTER `level1_name`");
CALL mall_add_column('affiliate_program_config', 'level2_name_en', "varchar(64) DEFAULT NULL COMMENT '二级等级名(英文)' AFTER `level2_name`");
CALL mall_add_column('affiliate_program_config', 'level3_name_en', "varchar(64) DEFAULT NULL COMMENT '三级等级名(英文)' AFTER `level3_name`");
CALL mall_add_column('affiliate_program_config', 'reward_rules_text_en', "text COMMENT '奖励说明(英文)' AFTER `reward_rules_text`");
CALL mall_add_column('affiliate_program_config', 'public_slogans_text_en', "text COMMENT '对外宣传(英文)' AFTER `public_slogans_text`");
CALL mall_add_column('affiliate_program_config', 'compliance_rules_text', "text COMMENT '合规说明(繁中)' AFTER `public_slogans_text_en`");
CALL mall_add_column('affiliate_program_config', 'compliance_rules_text_en', "text COMMENT '合规说明(英文)' AFTER `compliance_rules_text`");

DROP PROCEDURE IF EXISTS `mall_add_column`;

UPDATE `affiliate_program_config` SET
  `level1_name_en` = COALESCE(NULLIF(TRIM(`level1_name_en`), ''), 'Beauty Ambassador'),
  `level2_name_en` = COALESCE(NULLIF(TRIM(`level2_name_en`), ''), 'Beauty Expert'),
  `level3_name_en` = COALESCE(NULLIF(TRIM(`level3_name_en`), ''), 'Beauty Partner'),
  `reward_rules_text_en` = COALESCE(NULLIF(TRIM(`reward_rules_text_en`), ''),
    'Save when you shop, earn when you share\n• You refer a friend → Tier 1 commission\n• Your friend refers someone → Tier 2 commission\n• Their referral buys → Tier 3 commission'),
  `public_slogans_text_en` = COALESCE(NULLIF(TRIM(`public_slogans_text_en`), ''),
    'Shop beauty, share to earn\n3-tier referral on real product sales\nNo joining fee, no inventory, no pressure'),
  `compliance_rules_text` = COALESCE(NULLIF(TRIM(`compliance_rules_text`), ''),
    '合規說明\n• 合法三級推薦獎勵，不超過三級\n• 佣金僅基於真實商品訂單，不含招商費用\n• 無加盟費、無囤貨要求，免費加入推廣'),
  `compliance_rules_text_en` = COALESCE(NULLIF(TRIM(`compliance_rules_text_en`), ''),
    'Program rules (compliance)\n• Legitimate 3-tier referral rewards only — no deeper levels\n• Commissions apply to real product orders only, not recruitment fees\n• No joining fee, no forced inventory, free to join as an affiliate')
WHERE `id` = 1;
