<?php
declare(strict_types=1);

namespace app\service;

use app\model\CommissionRecord;
use app\model\Order as OrderModel;
use app\model\User as UserModel;
use app\model\WithdrawalRequest;

class WalletFlowService
{
    /**
     * @return array{list: array<int, array<string, mixed>>, total: int, page: int, limit: int, summary: array<string, mixed>}
     */
    public static function listFlows(array $params): array
    {
        $userId  = (int) ($params['user_id'] ?? 0);
        $type    = (string) ($params['type'] ?? 'all');
        $status  = (string) ($params['status'] ?? '');
        $keyword = trim((string) ($params['keyword'] ?? ''));
        $page    = max(1, (int) ($params['page'] ?? 1));
        $limit   = min(100, max(1, (int) ($params['limit'] ?? 20)));

        $currency = (string) (AffiliateService::getConfigRow()->currency_suffix ?? 'P');
        $rows     = [];

        if ($type === 'all' || $type === 'commission') {
            $q = CommissionRecord::alias('cr')
                ->leftJoin('orders o', 'cr.order_id = o.id')
                ->field('cr.*, o.order_no, o.user_id as buyer_id');
            if ($userId > 0) {
                $q->where('cr.user_id', $userId);
            }
            if ($status !== '') {
                $q->where('cr.status', $status);
            }
            if ($keyword !== '') {
                $q->where('o.order_no', 'like', "%{$keyword}%");
            }
            foreach ($q->select() as $cr) {
                $rows[] = self::mapCommissionRow($cr->toArray(), $currency);
            }
        }

        if ($type === 'all' || $type === 'withdrawal') {
            $q = WithdrawalRequest::query();
            if ($userId > 0) {
                $q->where('user_id', $userId);
            }
            if ($status !== '') {
                $q->where('status', $status);
            }
            foreach ($q->select() as $w) {
                $rows[] = self::mapWithdrawalRow($w->toArray(), $currency);
            }
        }

        if ($type === 'all' || $type === 'order') {
            $q = OrderModel::where('status', '>=', 1);
            if ($userId > 0) {
                $q->where('user_id', $userId);
            }
            if ($keyword !== '') {
                $q->where('order_no', 'like', "%{$keyword}%");
            }
            foreach ($q->select() as $ord) {
                $rows[] = self::mapOrderRow($ord->toArray(), $currency);
            }
        }

        usort($rows, static fn (array $a, array $b): int => ($b['occurred_at'] ?? 0) <=> ($a['occurred_at'] ?? 0));

        $total  = count($rows);
        $offset = ($page - 1) * $limit;
        $list   = array_slice($rows, $offset, $limit);

        if ($userId > 0) {
            self::attachUserMeta($list, $userId);
        } elseif (!empty($list)) {
            self::attachUsersForAdmin($list);
        }

        return [
            'list'    => $list,
            'total'   => $total,
            'page'    => $page,
            'limit'   => $limit,
            'summary' => self::buildSummary($userId, $currency),
        ];
    }

    /**
     * @param array<string, mixed> $cr
     * @return array<string, mixed>
     */
    private static function mapCommissionRow(array $cr, string $currency): array
    {
        $tier   = (int) ($cr['tier'] ?? 0);
        $amt    = round((float) ($cr['amount'] ?? 0), 2);
        $st     = (string) ($cr['status'] ?? 'pending');
        $ts     = (int) ($cr['created_at'] ?? 0);
        $unlock = (int) ($cr['unlock_at'] ?? 0);
        if ($st === 'available' && $unlock > 0) {
            $ts = $unlock;
        }
        $orderNo = (string) ($cr['order_no'] ?? '');
        $orderId = (int) ($cr['order_id'] ?? 0);
        $adminNote = trim((string) ($cr['settled_period'] ?? ''));
        if ($tier === WalletAdjustService::TIER_ADMIN || $orderId === 0) {
            $flowRemark = $adminNote !== '' ? $adminNote : '后台调账';
        } else {
            $flowRemark = $orderNo !== '' ? '订单 ' . $orderNo : '';
        }
        $direction = $amt >= 0 ? 'in' : 'out';
        $signedAmt = $amt;

        return [
            'flow_id'         => 'cr_' . (int) ($cr['id'] ?? 0),
            'category'        => 'commission',
            'direction'       => $direction,
            'amount'          => abs($amt),
            'signed_amount'   => $signedAmt,
            'currency_suffix' => $currency,
            'status'          => $st,
            'tier'            => $tier,
            'title'           => self::commissionTitle($tier),
            'remark'          => $flowRemark,
            'order_id'        => (int) ($cr['order_id'] ?? 0),
            'order_no'        => $orderNo,
            'buyer_id'        => (int) ($cr['buyer_id'] ?? 0),
            'user_id'         => (int) ($cr['user_id'] ?? 0),
            'goods_base'      => (float) ($cr['goods_base'] ?? 0),
            'rate'            => (float) ($cr['rate'] ?? 0),
            'settled_period'  => (string) ($cr['settled_period'] ?? ''),
            'occurred_at'     => $ts,
            'unlock_at'       => $unlock,
            'created_at'      => (int) ($cr['created_at'] ?? 0),
        ];
    }

    /**
     * @param array<string, mixed> $ord
     * @return array<string, mixed>
     */
    private static function mapOrderRow(array $ord, string $currency): array
    {
        $goods = (float) ($ord['goods_amount'] ?? 0);
        $amt   = $goods > 0 ? $goods : (float) ($ord['total_amount'] ?? 0);
        $amt   = round($amt, 2);
        $ts    = (int) ($ord['paid_at'] ?? $ord['created_at'] ?? 0);
        $st    = (int) ($ord['status'] ?? 0);

        return [
            'flow_id'         => 'ord_' . (int) ($ord['id'] ?? 0),
            'category'        => 'order',
            'direction'       => 'out',
            'amount'          => $amt,
            'signed_amount'   => -$amt,
            'currency_suffix' => $currency,
            'status'          => self::orderStatusKey($st),
            'tier'            => 0,
            'title'           => '订单支付',
            'remark'          => (string) ($ord['order_no'] ?? ''),
            'order_id'        => (int) ($ord['id'] ?? 0),
            'order_no'        => (string) ($ord['order_no'] ?? ''),
            'buyer_id'        => (int) ($ord['user_id'] ?? 0),
            'user_id'         => (int) ($ord['user_id'] ?? 0),
            'goods_base'      => $goods,
            'rate'            => 0,
            'settled_period'  => '',
            'occurred_at'     => $ts,
            'unlock_at'       => 0,
            'created_at'      => (int) ($ord['created_at'] ?? 0),
        ];
    }

    /**
     * @param array<string, mixed> $w
     * @return array<string, mixed>
     */
    private static function mapWithdrawalRow(array $w, string $currency): array
    {
        $amt = round((float) ($w['amount'] ?? 0), 2);
        $ts  = (int) ($w['processed_at'] ?? $w['created_at'] ?? 0);

        return [
            'flow_id'         => 'wd_' . (int) ($w['id'] ?? 0),
            'category'        => 'withdrawal',
            'direction'       => 'out',
            'amount'          => $amt,
            'signed_amount'   => -$amt,
            'currency_suffix' => $currency,
            'status'          => (string) ($w['status'] ?? 'pending'),
            'tier'            => 0,
            'title'           => '佣金提现',
            'remark'          => (string) ($w['gcash_number'] ?? '') . ' ' . (string) ($w['gcash_name'] ?? ''),
            'order_id'        => 0,
            'order_no'        => '',
            'buyer_id'        => 0,
            'user_id'         => (int) ($w['user_id'] ?? 0),
            'goods_base'      => 0,
            'rate'            => 0,
            'settled_period'  => '',
            'occurred_at'     => $ts,
            'unlock_at'       => 0,
            'created_at'      => (int) ($w['created_at'] ?? 0),
        ];
    }

    private static function commissionTitle(int $tier): string
    {
        return match ($tier) {
            WalletAdjustService::TIER_ADMIN => '后台调账',
            1                             => '一级直推佣金',
            2                             => '二级间推佣金',
            3                             => '三级团队佣金',
            default                       => '推广佣金',
        };
    }

    private static function orderStatusKey(int $status): string
    {
        return match ($status) {
            0       => 'unpaid',
            1       => 'paid',
            2       => 'shipped',
            3       => 'completed',
            4       => 'cancelled',
            default => 'unknown',
        };
    }

    /**
     * @param array<int, array<string, mixed>> $list
     */
    private static function attachUserMeta(array &$list, int $userId): void
    {
        $u = UserModel::find($userId);
        $name = $u ? ($u->nickname ?: $u->username) : '';
        foreach ($list as &$row) {
            $row['user_name'] = $name;
        }
    }

    /**
     * @param array<int, array<string, mixed>> $list
     */
    private static function attachUsersForAdmin(array &$list): void
    {
        $ids = array_unique(array_filter(array_map(
            static fn (array $r): int => (int) ($r['user_id'] ?? 0),
            $list
        )));
        if ($ids === []) {
            return;
        }
        $map = [];
        foreach (UserModel::whereIn('id', $ids)->select() as $u) {
            $map[(int) $u->id] = $u->nickname ?: $u->username;
        }
        foreach ($list as &$row) {
            $uid = (int) ($row['user_id'] ?? 0);
            $row['user_name'] = $map[$uid] ?? '';
        }
    }

    /**
     * @return array<string, mixed>
     */
    private static function buildSummary(int $userId, string $currency): array
    {
        $sumCr = static function (string $st) use ($userId): float {
            $q = CommissionRecord::where('status', $st);
            if ($userId > 0) {
                $q->where('user_id', $userId);
            }

            return (float) $q->sum('amount');
        };

        $orderQ = OrderModel::where('status', '>=', 1);
        if ($userId > 0) {
            $orderQ->where('user_id', $userId);
        }
        $spent = 0.0;
        foreach ($orderQ->select() as $o) {
            $g = (float) $o->goods_amount;
            $spent += $g > 0 ? $g : (float) $o->total_amount;
        }

        $inPending   = $sumCr('pending');
        $inAvailable = $sumCr('available');
        $inSettled   = $sumCr('settled');

        $withdrawable = $userId > 0
            ? GcashService::withdrawableBalance($userId)
            : 0.0;

        return [
            'currency_suffix'    => $currency,
            'total_income'       => round($inPending + $inAvailable + $inSettled, 2),
            'commission_pending' => round($inPending, 2),
            'commission_available' => round($inAvailable, 2),
            'commission_settled' => round($inSettled, 2),
            'withdrawable'       => round($withdrawable, 2),
            'total_spent'        => round($spent, 2),
            'net_commission'     => round($inPending + $inAvailable + $inSettled - $spent, 2),
        ];
    }
}
