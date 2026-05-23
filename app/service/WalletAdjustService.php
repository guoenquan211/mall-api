<?php
declare(strict_types=1);

namespace app\service;

use app\model\CommissionRecord;
use app\model\User as UserModel;
use think\facade\Db;

/** 后台人工调账（赠送/扣减佣金或积分） */
class WalletAdjustService
{
    public const TIER_ADMIN = 99;

    /**
     * @return array<string, mixed>
     */
    public static function userWalletOverview(int $userId): array
    {
        $user = UserModel::find($userId);
        if (!$user) {
            throw new \RuntimeException('user.not_found');
        }

        $currency = (string) (AffiliateService::getConfigRow()->currency_suffix ?? 'P');
        $sum = static function (string $st) use ($userId): float {
            return round((float) CommissionRecord::where('user_id', $userId)->where('status', $st)->sum('amount'), 2);
        };

        return [
            'user_id'              => $userId,
            'username'             => (string) $user->username,
            'nickname'             => (string) ($user->nickname ?? ''),
            'points'               => (int) ($user->points ?? 0),
            'currency_suffix'      => $currency,
            'commission_pending'   => $sum('pending'),
            'commission_available' => $sum('available'),
            'commission_settled'   => $sum('settled'),
            'withdrawal_locked'    => GcashService::withdrawalLocked($userId),
            'withdrawable'         => GcashService::withdrawableBalance($userId),
        ];
    }

    /**
     * @param array{user_id:int, type:string, direction:string, amount:float, remark?:string, commission_status?:string} $params
     * @return array<string, mixed>
     */
    public static function adjust(array $params): array
    {
        $userId = (int) ($params['user_id'] ?? 0);
        $type   = (string) ($params['type'] ?? 'commission');
        $dir    = (string) ($params['direction'] ?? 'credit');
        $amount = round(abs((float) ($params['amount'] ?? 0)), 2);
        $remark = trim((string) ($params['remark'] ?? ''));

        if ($userId <= 0) {
            throw new \RuntimeException('user.id_required');
        }
        if ($amount <= 0) {
            throw new \RuntimeException('wallet.adjust_amount_invalid');
        }

        $user = UserModel::find($userId);
        if (!$user) {
            throw new \RuntimeException('user.not_found');
        }

        if ($type === 'points') {
            return self::adjustPoints($user, $dir, $amount, $remark);
        }

        if ($type !== 'commission') {
            throw new \RuntimeException('wallet.adjust_type_invalid');
        }

        $status = (string) ($params['commission_status'] ?? 'available');
        if (!in_array($status, ['pending', 'available', 'settled'], true)) {
            $status = 'available';
        }

        return self::adjustCommission($user, $dir, $amount, $status, $remark);
    }

    /**
     * @return array<string, mixed>
     */
    private static function adjustPoints(UserModel $user, string $dir, float $amount, string $remark): array
    {
        $current = (int) ($user->points ?? 0);
        if ($dir === 'debit') {
            if ($current < $amount) {
                throw new \RuntimeException('wallet.points_insufficient');
            }
            $user->points = $current - (int) round($amount);
        } else {
            $user->points = $current + (int) round($amount);
        }
        $user->save();

        return [
            'type'     => 'points',
            'points'   => (int) $user->points,
            'amount'   => $dir === 'debit' ? -$amount : $amount,
            'remark'   => $remark,
            'overview' => self::userWalletOverview((int) $user->id),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private static function adjustCommission(UserModel $user, string $dir, float $amount, string $status, string $remark): array
    {
        $userId = (int) $user->id;

        if ($dir === 'debit') {
            $available = GcashService::commissionAvailable($userId);
            if ($available < $amount) {
                throw new \RuntimeException('wallet.commission_insufficient');
            }
            $signed = -$amount;
        } else {
            $signed = $amount;
        }

        $now = time();
        $unlockAt = $status === 'available' ? $now : 0;

        Db::startTrans();
        try {
            $row = CommissionRecord::create([
                'order_id'       => 0,
                'user_id'        => $userId,
                'tier'           => self::TIER_ADMIN,
                'goods_base'     => 0,
                'rate'           => 0,
                'amount'         => $signed,
                'status'         => $status,
                'unlock_at'      => $unlockAt,
                'settled_period' => $remark !== '' ? $remark : null,
                'created_at'     => $now,
            ]);
            Db::commit();
        } catch (\Throwable $e) {
            Db::rollback();
            throw $e;
        }

        return [
            'type'                 => 'commission',
            'commission_record_id' => (int) $row->id,
            'amount'               => $signed,
            'status'               => $status,
            'remark'               => $remark,
            'overview'             => self::userWalletOverview($userId),
        ];
    }
}
