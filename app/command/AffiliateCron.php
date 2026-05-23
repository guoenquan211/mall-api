<?php
declare(strict_types=1);

namespace app\command;

use app\service\AffiliateService;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;

/**
 * 分销定时任务：每日解锁 pending；每月 settlement_day（默认10号）结算上月佣金
 *
 * 建议 crontab（Linux）每日 02:00：
 *   0 2 * * * cd /path/to/backend && php think affiliate:cron
 *
 * Windows 任务计划程序：每日执行 backend/scripts/affiliate-cron.ps1
 */
class AffiliateCron extends Command
{
    protected function configure(): void
    {
        $this->setName('affiliate:cron')
            ->setDescription('Unlock due commissions; settle last month on settlement day')
            ->addOption('force-settle', null, Option::VALUE_NONE, 'Force monthly settlement even if not settlement day');
    }

    protected function execute(Input $input, Output $output): int
    {
        $force  = (bool) $input->getOption('force-settle');
        $result = AffiliateService::runScheduledJobs($force);

        $output->writeln(sprintf('Unlocked pending → available: %d', $result['unlocked']));
        if ($result['settlement_ran']) {
            $output->writeln(sprintf(
                'Settled available (period %s): %d',
                $result['period'] ?? '-',
                $result['settled']
            ));
        } else {
            $cfg = AffiliateService::getConfigRow();
            $output->writeln(sprintf(
                'Monthly settlement skipped (today is not day %d; use --force-settle to override)',
                (int) $cfg->settlement_day
            ));
        }

        return 0;
    }
}
