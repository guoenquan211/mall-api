<?php
declare(strict_types=1);

namespace app\service;

use app\model\AffiliateProgramConfig;
use app\model\AffiliateProductStat;
use app\model\CommissionRecord;
use app\model\Order as OrderModel;
use app\model\Product as ProductModel;
use app\model\User as UserModel;
use app\model\UserAffiliateStat;
use think\facade\Db;

class AffiliateService
{
    public static function defaultComplianceRulesText(): string
    {
        return "Program rules (compliance)\n"
            . "• Legitimate 3-tier referral rewards only — no deeper levels\n"
            . "• Commissions apply to real product orders only, not recruitment fees\n"
            . "• No joining fee, no forced inventory, free to join as an affiliate";
    }

    public static function defaultComplianceRulesTextZh(): string
    {
        return "合規說明\n"
            . "• 合法三級推薦獎勵，不超過三級\n"
            . "• 佣金僅基於真實商品訂單，不含招商費用\n"
            . "• 無加盟費、無囤貨要求，免費加入推廣";
    }

    public static function defaultRewardRulesTextZh(): string
    {
        return "自用省錢，分享賺錢\n"
            . "• 你推薦朋友買 → 你拿一級佣金\n"
            . "• 朋友再推薦別人買 → 你拿二級佣金\n"
            . "• 朋友的下級再推薦買 → 你拿三級佣金";
    }

    public static function defaultRewardRulesTextEn(): string
    {
        return "Save when you shop, earn when you share\n"
            . "• You refer a friend → Tier 1 commission\n"
            . "• Your friend refers someone → Tier 2 commission\n"
            . "• Their referral buys → Tier 3 commission";
    }

    public static function defaultPublicSlogansTextZh(): string
    {
        return "美妝自用省錢，分享賺錢\n"
            . "三級分銷，真實賣貨拿佣金\n"
            . "無加盟費、無囤貨、無壓力\n"
            . "賣產品都能賺，分享就能變現";
    }

    public static function defaultPublicSlogansTextEn(): string
    {
        return "Shop beauty, share to earn\n"
            . "3-tier referral on real product sales\n"
            . "No joining fee, no inventory, no pressure";
    }

    public static function getConfigRow(): AffiliateProgramConfig
    {
        $row = AffiliateProgramConfig::find(1);
        if (!$row) {
            self::seedDefaultConfig();
            $row = AffiliateProgramConfig::find(1);
        }

        return $row;
    }

    public static function seedDefaultConfig(): void
    {
        AffiliateProgramConfig::create([
            'id'                   => 1,
            'currency_suffix'      => 'P',
            'level1_name'          => '美妆分享官',
            'level1_name_en'       => 'Beauty Ambassador',
            'level2_name'          => '美妆达人',
            'level2_name_en'       => 'Beauty Expert',
            'level3_name'          => '美妆合伙人',
            'level3_name_en'       => 'Beauty Partner',
            'level1_spend_threshold' => 1000,
            'level1_any_order'     => 1,
            'level2_direct_l1_min' => 5,
            'level2_team_pv'       => 5000,
            'level3_direct_l2_min' => 3,
            'level3_team_pv'       => 20000,
            'commission_rate_1'    => 0.2,
            'commission_rate_2'    => 0.1,
            'commission_rate_3'    => 0.04,
            'settlement_day'       => 10,
            'after_sale_days'      => 7,
            'reward_rules_text'    => self::defaultRewardRulesTextZh(),
            'reward_rules_text_en' => self::defaultRewardRulesTextEn(),
            'public_slogans_text'  => self::defaultPublicSlogansTextZh(),
            'public_slogans_text_en' => self::defaultPublicSlogansTextEn(),
            'compliance_rules_text' => self::defaultComplianceRulesTextZh(),
            'compliance_rules_text_en' => self::defaultComplianceRulesText(),
            'updated_at'           => time(),
        ]);
    }

    public static function ensureInviteCode(UserModel $user): string
    {
        if (!empty($user->invite_code)) {
            return (string) $user->invite_code;
        }
        for ($i = 0; $i < 20; $i++) {
            $code = strtoupper(substr(bin2hex(random_bytes(6)), 0, 10));
            if (!UserModel::where('invite_code', $code)->find()) {
                $user->invite_code = $code;
                $user->save();

                return $code;
            }
        }
        $code = 'U' . $user->id . strtoupper(substr(bin2hex(random_bytes(3)), 0, 4));
        $user->invite_code = $code;
        $user->save();

        return $code;
    }

    /**
     * @return array{0:?int,1:?int,2:?int}
     */
    public static function snapshotBeneficiaries(int $buyerId): array
    {
        $b = [null, null, null];
        $buyer = UserModel::find($buyerId);
        if (!$buyer || !$buyer->parent_id) {
            return $b;
        }
        $p = UserModel::find((int) $buyer->parent_id);
        if (!$p) {
            return $b;
        }
        $b[0] = (int) $p->id;
        if ($p->parent_id) {
            $p2 = UserModel::find((int) $p->parent_id);
            if ($p2) {
                $b[1] = (int) $p2->id;
                if ($p2->parent_id) {
                    $p3 = UserModel::find((int) $p2->parent_id);
                    if ($p3) {
                        $b[2] = (int) $p3->id;
                    }
                }
            }
        }

        return $b;
    }

    public static function completedOrderCount(int $userId): int
    {
        return (int) OrderModel::where('user_id', $userId)->where('status', 3)->count();
    }

    public static function directCountByMinLevel(int $parentId, int $minLevel): int
    {
        return (int) UserModel::where('parent_id', $parentId)
            ->where('affiliate_level', '>=', $minLevel)
            ->count();
    }

    public static function directCount(int $parentId): int
    {
        return (int) UserModel::where('parent_id', $parentId)->count();
    }

    /**
     * @return list<array<string, mixed>>
     */
    public static function directDownlineList(int $userId): array
    {
        $rows = UserModel::where('parent_id', $userId)
            ->field('id,username,nickname,affiliate_level,total_paid_goods,created_at,status')
            ->order('id', 'desc')
            ->select();

        $list = [];
        foreach ($rows as $row) {
            $list[] = [
                'id'               => (int) $row->id,
                'username'         => (string) $row->username,
                'nickname'         => (string) ($row->nickname ?: $row->username),
                'affiliate_level'  => (int) $row->affiliate_level,
                'total_paid_goods' => (float) $row->total_paid_goods,
                'created_at'       => $row->created_at ? (int) $row->created_at : null,
                'is_valid'         => (int) $row->affiliate_level >= 1,
                'status'           => (int) $row->status,
            ];
        }

        return $list;
    }

    public static function getOrCreateStats(int $userId): UserAffiliateStat
    {
        $s = UserAffiliateStat::find($userId);
        if ($s) {
            return $s;
        }
        $s = UserAffiliateStat::create([
            'user_id'           => $userId,
            'downline_pv_total' => 0,
            'updated_at'        => time(),
        ]);

        return $s;
    }

    public static function addDownlinePvToAncestors(int $buyerId, string $goodsAmount): void
    {
        $amt = (float) $goodsAmount;
        if ($amt <= 0) {
            return;
        }
        $cur = UserModel::find($buyerId);
        while ($cur && $cur->parent_id) {
            $pid = (int) $cur->parent_id;
            $st  = self::getOrCreateStats($pid);
            $st->downline_pv_total = (float) $st->downline_pv_total + $amt;
            $st->updated_at = time();
            $st->save();
            $cur = UserModel::find($pid);
        }
    }

    public static function evaluateAffiliateLevel(int $userId): void
    {
        $user = UserModel::find($userId);
        if (!$user) {
            return;
        }
        $cfg = self::getConfigRow();
        $lvl = (int) $user->affiliate_level;

        $stats = self::getOrCreateStats($userId);
        $teamPv = (float) $stats->downline_pv_total;
        $spent  = (float) $user->total_paid_goods;
        $orders = self::completedOrderCount($userId);

        $l1Ok = $spent >= (float) $cfg->level1_spend_threshold
            || ($cfg->level1_any_order && $orders >= 1);

        $l2Ok = self::directCountByMinLevel($userId, 1) >= (int) $cfg->level2_direct_l1_min
            && $teamPv >= (float) $cfg->level2_team_pv;

        $l3Ok = self::directCountByMinLevel($userId, 2) >= (int) $cfg->level3_direct_l2_min
            && $teamPv >= (float) $cfg->level3_team_pv;

        $new = $lvl;
        if ($l3Ok) {
            $new = 3;
        } elseif ($l2Ok) {
            $new = max($lvl, 2);
        } elseif ($l1Ok) {
            $new = max($lvl, 1);
        }
        if ($new > $lvl) {
            $user->affiliate_level = $new;
            $user->save();
        }
    }

    public static function bubbleEvaluate(int $buyerId): void
    {
        $ids = [$buyerId];
        $u   = UserModel::find($buyerId);
        $cur = $u;
        while ($cur && $cur->parent_id) {
            $ids[] = (int) $cur->parent_id;
            $cur = UserModel::find((int) $cur->parent_id);
        }
        foreach (array_unique($ids) as $id) {
            self::evaluateAffiliateLevel((int) $id);
        }
    }

    public static function onOrderCompleted(OrderModel $order): void
    {
        if ((int) $order->status !== 3) {
            return;
        }
        $buyerId = (int) $order->user_id;
        $goods   = (string) $order->goods_amount;
        if ($goods === '' || (float) $goods <= 0) {
            $goods = (string) $order->total_amount;
        }

        $buyer = UserModel::find($buyerId);
        if ($buyer) {
            $buyer->total_paid_goods = (float) $buyer->total_paid_goods + (float) $goods;
            $buyer->save();
        }

        self::addDownlinePvToAncestors($buyerId, $goods);
        self::bubbleEvaluate($buyerId);

        if (CommissionRecord::where('order_id', $order->id)->count() > 0) {
            return;
        }

        $cfg        = self::getConfigRow();
        $base       = (float) $goods;
        $confirm    = (int) ($order->confirmed_at ?? time());
        $afterDays  = max(1, (int) $cfg->after_sale_days);
        $unlockAt   = $confirm + $afterDays * 86400;
        $rates      = [
            1 => (float) $cfg->commission_rate_1,
            2 => (float) $cfg->commission_rate_2,
            3 => (float) $cfg->commission_rate_3,
        ];
        $benefMap = [
            1 => $order->b1_user_id ? (int) $order->b1_user_id : null,
            2 => $order->b2_user_id ? (int) $order->b2_user_id : null,
            3 => $order->b3_user_id ? (int) $order->b3_user_id : null,
        ];

        $beneficiaryAmounts = [];
        foreach ([1, 2, 3] as $tier) {
            $bid = $benefMap[$tier];
            if (!$bid) {
                continue;
            }
            $ben = UserModel::find($bid);
            if (!$ben) {
                continue;
            }
            if ((int) $ben->affiliate_level < $tier) {
                continue;
            }
            $rate   = $rates[$tier];
            $amount = round($base * $rate, 2);
            if ($amount <= 0) {
                continue;
            }
            CommissionRecord::create([
                'order_id'   => $order->id,
                'user_id'    => $bid,
                'tier'       => $tier,
                'goods_base' => $base,
                'rate'       => $rate,
                'amount'     => $amount,
                'status'     => 'pending',
                'unlock_at'  => $unlockAt,
                'created_at' => time(),
            ]);
            $beneficiaryAmounts[$bid] = ($beneficiaryAmounts[$bid] ?? 0) + $amount;
        }

        if ($beneficiaryAmounts !== []) {
            self::recordProductStatsFromOrder($order, $beneficiaryAmounts);
        }
    }

    public static function unlockDueCommissions(): int
    {
        $now = time();

        return CommissionRecord::where('status', 'pending')
            ->where('unlock_at', '<=', $now)
            ->update(['status' => 'available']);
    }

    /** 演示/手工：将全部 available 标为已结算 */
    public static function settleAvailableBatch(string $periodLabel): int
    {
        return CommissionRecord::where('status', 'available')
            ->update([
                'status'         => 'settled',
                'settled_period' => $periodLabel,
            ]);
    }

    /**
     * 结算上一自然月内解锁的 available 佣金（每月 settlement_day 执行）
     */
    public static function settlePreviousMonthAvailable(?string $periodLabel = null): int
    {
        if ($periodLabel === null || $periodLabel === '') {
            $periodLabel = date('Y-m', strtotime('first day of last month'));
        }
        if (!preg_match('/^\d{4}-\d{2}$/', $periodLabel)) {
            return 0;
        }
        $start = strtotime($periodLabel . '-01 00:00:00');
        $end   = strtotime('+1 month', $start) - 1;

        return CommissionRecord::where('status', 'available')
            ->whereBetween('unlock_at', [$start, $end])
            ->update([
                'status'         => 'settled',
                'settled_period' => $periodLabel,
            ]);
    }

    /**
     * 定时任务入口：每日解锁到期 pending；每月 settlement_day 结算上月佣金
     *
     * @return array{unlocked:int,settled:int,period:?string,settlement_ran:bool}
     */
    public static function runScheduledJobs(bool $forceSettle = false): array
    {
        $unlocked = self::unlockDueCommissions();
        $cfg      = self::getConfigRow();
        $today    = (int) date('j');
        $setDay   = max(1, min(28, (int) $cfg->settlement_day));
        $ran      = $forceSettle || $today === $setDay;
        $period   = null;
        $settled  = 0;
        if ($ran) {
            $period  = date('Y-m', strtotime('first day of last month'));
            $settled = self::settlePreviousMonthAvailable($period);
        }

        return [
            'unlocked'       => $unlocked,
            'settled'        => $settled,
            'period'         => $period,
            'settlement_ran' => $ran,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function userAffiliateProgress(int $userId): array
    {
        $cfg   = self::getConfigRow();
        $user  = UserModel::find($userId);
        $stats = self::getOrCreateStats($userId);
        $lvl   = $user ? (int) $user->affiliate_level : 0;
        $spent = $user ? (float) $user->total_paid_goods : 0;
        $team  = (float) $stats->downline_pv_total;
        $l1Cnt = self::directCountByMinLevel($userId, 1);
        $l2Cnt = self::directCountByMinLevel($userId, 2);
        $directCnt = self::directCount($userId);
        $ords  = self::completedOrderCount($userId);

        return [
            'affiliate_level'     => $lvl,
            'total_paid_goods'    => $spent,
            'team_pv'             => $team,
            'direct_count'        => $directCnt,
            'direct_l1_count'     => $l1Cnt,
            'direct_l2_count'     => $l2Cnt,
            'completed_orders'    => $ords,
            'level1_spend_need'   => max(0, (float) $cfg->level1_spend_threshold - $spent),
            'level2_direct_l1_need' => max(0, (int) $cfg->level2_direct_l1_min - $l1Cnt),
            'level2_team_pv_need' => max(0, (float) $cfg->level2_team_pv - $team),
            'level3_direct_l2_need' => max(0, (int) $cfg->level3_direct_l2_min - $l2Cnt),
            'level3_team_pv_need' => max(0, (float) $cfg->level3_team_pv - $team),
        ];
    }

    public static function publicConfigPayload(): array
    {
        $c = self::getConfigRow();

        return [
            'currency_suffix'     => $c->currency_suffix,
            'level1_name'         => $c->level1_name,
            'level1_name_en'      => (string) ($c->level1_name_en ?? ''),
            'level2_name'         => $c->level2_name,
            'level2_name_en'      => (string) ($c->level2_name_en ?? ''),
            'level3_name'         => $c->level3_name,
            'level3_name_en'      => (string) ($c->level3_name_en ?? ''),
            'level1_spend'        => (float) $c->level1_spend_threshold,
            'level1_any_order'    => (int) $c->level1_any_order,
            'level2_direct_l1'    => (int) $c->level2_direct_l1_min,
            'level2_team_pv'      => (float) $c->level2_team_pv,
            'level3_direct_l2'    => (int) $c->level3_direct_l2_min,
            'level3_team_pv'      => (float) $c->level3_team_pv,
            'commission_rate_1'   => (float) $c->commission_rate_1,
            'commission_rate_2'   => (float) $c->commission_rate_2,
            'commission_rate_3'   => (float) $c->commission_rate_3,
            'settlement_day'      => (int) $c->settlement_day,
            'after_sale_days'     => (int) $c->after_sale_days,
            'reward_rules_text'      => (string) ($c->reward_rules_text ?? self::defaultRewardRulesTextZh()),
            'reward_rules_text_en'   => (string) ($c->reward_rules_text_en ?? self::defaultRewardRulesTextEn()),
            'public_slogans_text'    => (string) ($c->public_slogans_text ?? self::defaultPublicSlogansTextZh()),
            'public_slogans_text_en' => (string) ($c->public_slogans_text_en ?? self::defaultPublicSlogansTextEn()),
            'compliance_rules_text'    => (string) ($c->compliance_rules_text ?? self::defaultComplianceRulesTextZh()),
            'compliance_rules_text_en' => (string) ($c->compliance_rules_text_en ?? self::defaultComplianceRulesText()),
            'max_tier'               => 3,
        ];
    }

    /** 记录推广链接点击（ref 邀请码 + 可选商品 ID，0=首页） */
    public static function trackLinkClick(string $inviteCode, int $productId = 0): bool
    {
        $code = strtoupper(trim($inviteCode));
        if ($code === '') {
            return false;
        }
        $u = UserModel::where('invite_code', $code)->find();
        if (!$u) {
            return false;
        }
        if ($productId > 0 && !ProductModel::where('id', $productId)->where('status', 1)->find()) {
            return false;
        }

        return self::incrementClick((int) $u->id, max(0, $productId));
    }

    /**
     * @return array{shop_link: array<string, mixed>, product_links: list<array<string, mixed>>}
     */
    public static function promotionLinksPayload(int $userId, string $inviteCode): array
    {
        $statsMap = [];
        try {
            $rows = AffiliateProductStat::where('user_id', $userId)->select();
            foreach ($rows as $row) {
                $statsMap[(int) $row->product_id] = [
                    'click_count'      => (int) $row->click_count,
                    'order_count'      => (int) $row->order_count,
                    'commission_total' => (float) $row->commission_total,
                ];
            }
        } catch (\Throwable) {
            // 表未迁移时仍返回链接列表
        }

        $emptyStat = static fn (): array => [
            'click_count'      => 0,
            'order_count'      => 0,
            'commission_total' => 0.0,
        ];

        $shopStat = $statsMap[0] ?? $emptyStat();
        $shopLink = [
            'product_id'       => 0,
            'name'             => '首页',
            'name_en'          => 'Home',
            'image'            => null,
            'path'             => '/',
            'click_count'      => $shopStat['click_count'],
            'order_count'      => $shopStat['order_count'],
            'commission_total' => $shopStat['commission_total'],
        ];

        $products = ProductModel::where('status', 1)
            ->order('id', 'asc')
            ->field('id,name,name_en,image,price')
            ->select();

        $productLinks = [];
        foreach ($products as $p) {
            $pid  = (int) $p->id;
            $stat = $statsMap[$pid] ?? $emptyStat();
            $productLinks[] = [
                'product_id'       => $pid,
                'name'             => (string) $p->name,
                'name_en'          => $p->name_en ? (string) $p->name_en : null,
                'image'            => $p->image ? (string) $p->image : null,
                'price'            => (float) $p->price,
                'path'             => '/product/' . $pid,
                'click_count'      => $stat['click_count'],
                'order_count'      => $stat['order_count'],
                'commission_total' => $stat['commission_total'],
            ];
        }

        return [
            'invite_code'    => $inviteCode,
            'shop_link'      => $shopLink,
            'product_links'  => $productLinks,
        ];
    }

    /**
     * @param array<int, float> $beneficiaryAmounts user_id => commission for this order
     */
    private static function recordProductStatsFromOrder(OrderModel $order, array $beneficiaryAmounts): void
    {
        try {
            $items = Db::name('order_items')->where('order_id', (int) $order->id)->select()->toArray();
            if ($items === []) {
                return;
            }

            $lineTotals = [];
            $goodsSum   = 0.0;
            foreach ($items as $it) {
                $pid = (int) $it['product_id'];
                $amt = (float) $it['price'] * (int) $it['quantity'];
                $lineTotals[$pid] = ($lineTotals[$pid] ?? 0) + $amt;
                $goodsSum += $amt;
            }
            if ($goodsSum <= 0) {
                $goodsSum = (float) $order->goods_amount;
            }
            if ($goodsSum <= 0) {
                $goodsSum = (float) $order->total_amount;
            }
            if ($goodsSum <= 0) {
                return;
            }

            foreach ($beneficiaryAmounts as $uid => $commTotal) {
                $uid = (int) $uid;
                $commTotal = (float) $commTotal;
                if ($uid <= 0 || $commTotal <= 0) {
                    continue;
                }
                foreach ($lineTotals as $pid => $lineAmt) {
                    $share = round($commTotal * ($lineAmt / $goodsSum), 2);
                    if ($share > 0) {
                        self::incrementOrderStat($uid, (int) $pid, $share);
                    }
                }
            }
        } catch (\Throwable) {
            // 统计表未就绪时不影响订单流程
        }
    }

    private static function incrementClick(int $userId, int $productId): bool
    {
        try {
            $now = time();
            $exists = Db::name('affiliate_product_stats')
                ->where('user_id', $userId)
                ->where('product_id', $productId)
                ->find();
            if ($exists) {
                Db::name('affiliate_product_stats')
                    ->where('user_id', $userId)
                    ->where('product_id', $productId)
                    ->inc('click_count')
                    ->update(['updated_at' => $now]);
            } else {
                Db::name('affiliate_product_stats')->insert([
                    'user_id'          => $userId,
                    'product_id'       => $productId,
                    'click_count'      => 1,
                    'order_count'      => 0,
                    'commission_total' => 0,
                    'updated_at'       => $now,
                ]);
            }

            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    private static function incrementOrderStat(int $userId, int $productId, float $commissionShare): void
    {
        $now = time();
        $exists = Db::name('affiliate_product_stats')
            ->where('user_id', $userId)
            ->where('product_id', $productId)
            ->find();
        if ($exists) {
            Db::name('affiliate_product_stats')
                ->where('user_id', $userId)
                ->where('product_id', $productId)
                ->inc('order_count')
                ->inc('commission_total', $commissionShare)
                ->update(['updated_at' => $now]);
        } else {
            Db::name('affiliate_product_stats')->insert([
                'user_id'          => $userId,
                'product_id'       => $productId,
                'click_count'      => 0,
                'order_count'      => 1,
                'commission_total' => $commissionShare,
                'updated_at'       => $now,
            ]);
        }
    }
}
