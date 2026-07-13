<?php
declare(strict_types=1);

namespace app\service;

use app\model\CommissionRecord;
use app\model\GcashPlatformAccount;
use app\model\Order as OrderModel;
use app\model\User as UserModel;
use app\model\WithdrawalRequest;
use app\support\MediaUrl;
use think\facade\Db;

class GcashService
{
    public static function activePlatformAccounts(): array
    {
        return GcashPlatformAccount::where('is_active', 1)
            ->order('sort_order', 'asc')
            ->order('slot', 'asc')
            ->select()
            ->toArray();
    }

    public static function publicAccountsPayload(): array
    {
        $list = [];
        foreach (self::activePlatformAccounts() as $row) {
            $list[] = [
                'slot'         => (int) $row['slot'],
                'label'        => (string) $row['label'],
                'account_name' => (string) ($row['account_name'] ?? ''),
                'mobile'       => (string) ($row['mobile'] ?? ''),
                'qr_image'     => MediaUrl::toAbsolute((string) ($row['qr_image'] ?? '')),
            ];
        }
        return $list;
    }

    public static function commissionAvailable(int $userId): float
    {
        return (float) CommissionRecord::where('user_id', $userId)
            ->where('status', 'available')
            ->sum('amount');
    }

    public static function withdrawalLocked(int $userId): float
    {
        return (float) WithdrawalRequest::where('user_id', $userId)
            ->whereIn('status', ['pending', 'approved'])
            ->sum('amount');
    }

    public static function withdrawableBalance(int $userId): float
    {
        return max(0, round(self::commissionAvailable($userId) - self::withdrawalLocked($userId), 2));
    }

    /**
     * 用户标记已付款
     */
    public static function userMarkOrderPaid(int $orderId, int $userId, int $accountSlot = 0, string $remark = '', string $proofImage = ''): OrderModel
    {
        $order = OrderModel::find($orderId);
        if (!$order) {
            throw new \RuntimeException('order.not_found');
        }
        if ((int) $order->user_id !== $userId) {
            throw new \RuntimeException('order.forbidden');
        }
        if ((int) $order->status !== 0) {
            throw new \RuntimeException('order.not_pending_payment');
        }
        $ps = (string) ($order->payment_status ?? 'pending');
        if (!in_array($ps, ['pending', 'rejected'], true)) {
            throw new \RuntimeException('order.payment_already_submitted');
        }

        $proofImage = trim($proofImage);
        if ($proofImage === '') {
            throw new \RuntimeException('order.payment_proof_required');
        }

        $order->payment_method = 'gcash';
        $order->payment_status = 'user_confirmed';
        $order->user_paid_at = time();
        $order->payment_proof_image = $proofImage;
        $order->payment_reject_reason = null;
        if ($accountSlot > 0) {
            $order->payment_account_slot = $accountSlot;
        }
        if ($remark !== '') {
            $order->payment_remark = $remark;
        }
        $order->save();

        return $order;
    }

    /**
     * 后台确认收款 → 待发货
     */
    public static function approveOrderPayment(int $orderId, string $adminNote = ''): OrderModel
    {
        $order = OrderModel::find($orderId);
        if (!$order) {
            throw new \RuntimeException('order.not_found');
        }
        if ((string) $order->payment_status !== 'user_confirmed') {
            throw new \RuntimeException('order.payment_not_reviewable');
        }

        Db::startTrans();
        try {
            $order->payment_status = 'approved';
            $order->status = 1;
            $order->paid_at = time();
            if ($adminNote !== '') {
                $order->payment_remark = trim($order->payment_remark . "\n[审核] " . $adminNote);
            }
            $order->save();

            Db::commit();

            // 付款通过即分销入账（累计消费 / pending 佣金）
            try {
                AffiliateService::onOrderPaid(OrderModel::find($order->id) ?: $order);
            } catch (\Throwable $e) {
                // 分销失败不影响付款审核结果
            }

            return $order;
        } catch (\Throwable $e) {
            Db::rollback();
            throw $e;
        }
    }

    public static function rejectOrderPayment(int $orderId, string $adminNote = ''): OrderModel
    {
        $order = OrderModel::find($orderId);
        if (!$order) {
            throw new \RuntimeException('order.not_found');
        }
        if ((string) $order->payment_status !== 'user_confirmed') {
            throw new \RuntimeException('order.payment_not_reviewable');
        }

        $adminNote = trim($adminNote);
        if ($adminNote === '') {
            throw new \RuntimeException('order.reject_reason_required');
        }

        Db::startTrans();
        try {
            $order->payment_status = 'rejected';
            $order->status = 0;
            $order->payment_reject_reason = $adminNote;
            if ($adminNote !== '') {
                $order->payment_remark = trim(($order->payment_remark ?? '') . "\n[驳回] " . $adminNote);
            }
            $order->save();

            Db::commit();
            return $order;
        } catch (\Throwable $e) {
            Db::rollback();
            throw $e;
        }
    }

    public static function createWithdrawal(int $userId, float $amount): WithdrawalRequest
    {
        $user = UserModel::find($userId);
        if (!$user) {
            throw new \RuntimeException('user.not_found');
        }
        $gcashNumber = trim((string) ($user->gcash_number ?? ''));
        $gcashName = trim((string) ($user->gcash_name ?? ''));
        if ($gcashNumber === '' || $gcashName === '') {
            throw new \RuntimeException('gcash.bind_required');
        }
        if ($amount <= 0) {
            throw new \RuntimeException('withdrawal.amount_invalid');
        }

        $available = self::withdrawableBalance($userId);
        if ($amount > $available + 0.001) {
            throw new \RuntimeException('withdrawal.insufficient');
        }

        $pending = WithdrawalRequest::where('user_id', $userId)->where('status', 'pending')->find();
        if ($pending) {
            throw new \RuntimeException('withdrawal.pending_exists');
        }

        return WithdrawalRequest::create([
            'user_id'       => $userId,
            'amount'        => round($amount, 2),
            'gcash_number'  => $gcashNumber,
            'gcash_name'    => $gcashName,
            'status'        => 'pending',
        ]);
    }

    public static function approveWithdrawal(int $id, string $payoutRef = '', string $adminNote = ''): WithdrawalRequest
    {
        $row = WithdrawalRequest::find($id);
        if (!$row) {
            throw new \RuntimeException('withdrawal.not_found');
        }
        if ((string) $row->status !== 'pending') {
            throw new \RuntimeException('withdrawal.not_pending');
        }

        $available = self::withdrawableBalance((int) $row->user_id);
        if ((float) $row->amount > $available + 0.001) {
            throw new \RuntimeException('withdrawal.insufficient');
        }

        // 将对应金额从 available 佣金标记为 settled（简化：按时间顺序扣减）
        self::settleCommissionForWithdrawal((int) $row->user_id, (float) $row->amount);

        $row->status = 'approved';
        $row->payout_ref = $payoutRef;
        $row->admin_note = $adminNote;
        $row->processed_at = time();
        $row->save();

        return $row;
    }

    public static function rejectWithdrawal(int $id, string $adminNote = ''): WithdrawalRequest
    {
        $row = WithdrawalRequest::find($id);
        if (!$row) {
            throw new \RuntimeException('withdrawal.not_found');
        }
        if ((string) $row->status !== 'pending') {
            throw new \RuntimeException('withdrawal.not_pending');
        }

        $row->status = 'rejected';
        $row->admin_note = $adminNote;
        $row->processed_at = time();
        $row->save();

        return $row;
    }

    /**
     * 按 FIFO 将 available 佣金扣减并标记 settled（提现出账）
     */
    private static function settleCommissionForWithdrawal(int $userId, float $amount): void
    {
        $left = $amount;
        $records = CommissionRecord::where('user_id', $userId)
            ->where('status', 'available')
            ->order('unlock_at', 'asc')
            ->order('id', 'asc')
            ->select();

        foreach ($records as $rec) {
            if ($left <= 0.001) {
                break;
            }
            $amt = (float) $rec->amount;
            if ($amt <= $left + 0.001) {
                $rec->status = 'settled';
                $rec->settled_period = 'withdrawal:' . date('Y-m');
                $rec->save();
                $left -= $amt;
            }
        }

        if ($left > 0.01) {
            throw new \RuntimeException('withdrawal.insufficient');
        }
    }
}
