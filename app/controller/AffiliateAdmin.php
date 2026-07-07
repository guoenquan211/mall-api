<?php
namespace app\controller;

use app\BaseController;
use app\model\AffiliateProgramConfig;
use app\service\AffiliateService;
use think\facade\Request;
use app\support\ApiLocale;

class AffiliateAdmin extends BaseController
{
    public function getConfig()
    {
        $row = AffiliateService::getConfigRow();

        return json(['code' => 0, 'data' => $row->toArray()]);
    }

    public function saveConfig()
    {
        $patch = Request::only([
            'currency_suffix', 'level1_name', 'level1_name_en', 'level2_name', 'level2_name_en',
            'level3_name', 'level3_name_en',
            'level1_spend_threshold', 'level1_any_order', 'level2_direct_l1_min', 'level2_team_pv',
            'level3_direct_l2_min', 'level3_team_pv', 'commission_rate_1', 'commission_rate_2', 'commission_rate_3',
            'settlement_day', 'after_sale_days',
            'reward_rules_text', 'reward_rules_text_en',
            'public_slogans_text', 'public_slogans_text_en',
            'compliance_rules_text', 'compliance_rules_text_en',
        ]);
        foreach ($patch as $k => $v) {
            if ($v === null) {
                unset($patch[$k]);
            }
        }
        $row   = AffiliateProgramConfig::find(1);
        if (!$row) {
            AffiliateService::seedDefaultConfig();
            $row = AffiliateProgramConfig::find(1);
        }
        $patch['updated_at'] = time();
        $row->save($patch);
        $this->log('更新', '分销配置', '更新 affiliate_program_config');

        return json(['code' => 0, 'msg' => ApiLocale::t('common.save_ok')]);
    }

    /** 将已到解锁时间的 pending 佣金置为 available */
    public function unlockCommissions()
    {
        $n = AffiliateService::unlockDueCommissions();
        $this->log('执行', '分销', "解锁佣金记录 {$n} 条");

        return json(['code' => 0, 'data' => ['updated' => $n]]);
    }

    /**
     * 结算佣金：默认按上一自然月 unlock_at 范围结算 available（与定时任务一致）
     * period=2026-04；all=1 时结算全部 available（仅演示）
     */
    public function settleCommissions()
    {
        $period = trim((string) Request::param('period', date('Y-m', strtotime('first day of last month'))));
        $all    = (int) Request::param('all', 0) === 1;
        $n      = $all
            ? AffiliateService::settleAvailableBatch($period)
            : AffiliateService::settlePreviousMonthAvailable($period);
        $mode = $all ? '全部available' : '上月解锁范围';
        $this->log('结算', '分销', "批次 {$period} ({$mode}) 结算 {$n} 条");

        return json(['code' => 0, 'data' => ['settled' => $n, 'period' => $period, 'mode' => $all ? 'all' : 'monthly']]);
    }

    /** 执行与 crontab 相同的定时逻辑（解锁 + 若今日为结算日则结算上月） */
    public function runCron()
    {
        $force  = (int) Request::param('force_settle', 0) === 1;
        $result = AffiliateService::runScheduledJobs($force);
        $this->log('执行', '分销定时', json_encode($result, JSON_UNESCAPED_UNICODE));

        return json(['code' => 0, 'data' => $result]);
    }
}
