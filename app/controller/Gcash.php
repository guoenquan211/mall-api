<?php
namespace app\controller;

use app\BaseController;
use app\model\Order as OrderModel;
use app\model\WithdrawalRequest;
use app\model\User as UserModel;
use app\service\AffiliateService;
use app\service\GcashService;
use app\support\ApiLocale;
use think\facade\Request;

/** 前台 GCash 收款与提现 */
class Gcash extends BaseController
{
    public function publicAccounts()
    {
        return $this->success(GcashService::publicAccountsPayload());
    }

    public function walletSummary()
    {
        $userId = (int) Request::param('user_id', 0);
        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }
        $user = UserModel::find($userId);
        if (!$user) {
            return $this->error(ApiLocale::t('user.not_found'));
        }

        $currency = (string) (AffiliateService::getConfigRow()->currency_suffix ?? 'P');

        return $this->success([
            'commission_available' => GcashService::commissionAvailable($userId),
            'withdrawal_locked'    => GcashService::withdrawalLocked($userId),
            'withdrawable'         => GcashService::withdrawableBalance($userId),
            'currency_suffix'      => $currency,
            'gcash_number'         => (string) ($user->gcash_number ?? ''),
            'gcash_name'           => (string) ($user->gcash_name ?? ''),
        ]);
    }

    public function bindGcash()
    {
        $userId = (int) Request::param('user_id', 0);
        $number = trim((string) Request::param('gcash_number', ''));
        $name   = trim((string) Request::param('gcash_name', ''));

        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }
        if ($number === '' || $name === '') {
            return $this->error(ApiLocale::t('gcash.bind_fields_required'));
        }

        $user = UserModel::find($userId);
        if (!$user) {
            return $this->error(ApiLocale::t('user.not_found'));
        }

        $user->gcash_number = $number;
        $user->gcash_name   = $name;
        $user->save();

        return $this->success([
            'gcash_number' => $number,
            'gcash_name'   => $name,
        ], ApiLocale::t('gcash.bind_ok'));
    }

    public function markOrderPaid()
    {
        $orderId = (int) Request::param('order_id', 0);
        $userId  = (int) Request::param('user_id', 0);
        $slot    = (int) Request::param('account_slot', 0);
        $remark  = trim((string) Request::param('remark', ''));
        $proof   = trim((string) Request::param('payment_proof', ''));

        if ($orderId <= 0 || $userId <= 0) {
            return $this->error(ApiLocale::t('order.params_incomplete'));
        }

        try {
            $order = GcashService::userMarkOrderPaid($orderId, $userId, $slot, $remark, $proof);
            return $this->success($order, ApiLocale::t('gcash.mark_paid_ok'));
        } catch (\RuntimeException $e) {
            $key = $e->getMessage();
            $msg = str_starts_with($key, 'order.') || str_starts_with($key, 'gcash.')
                ? ApiLocale::t($key)
                : $key;
            return $this->error($msg);
        }
    }

    public function createWithdrawal()
    {
        $userId = (int) Request::param('user_id', 0);
        $amount = (float) Request::param('amount', 0);

        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }

        try {
            $row = GcashService::createWithdrawal($userId, $amount);
            return $this->success($row, ApiLocale::t('withdrawal.created'));
        } catch (\RuntimeException $e) {
            $key = $e->getMessage();
            $msg = str_starts_with($key, 'withdrawal.') || str_starts_with($key, 'gcash.')
                ? ApiLocale::t($key)
                : $key;
            return $this->error($msg);
        }
    }

    public function myWithdrawals()
    {
        $userId = (int) Request::param('user_id', 0);
        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }

        $list = WithdrawalRequest::where('user_id', $userId)
            ->order('id', 'desc')
            ->limit(50)
            ->select();

        return $this->success($list);
    }

    public function orderPaymentInfo($id)
    {
        $userId = (int) Request::param('user_id', 0);
        $order = OrderModel::with(['items'])->find($id);
        if (!$order) {
            return $this->error(ApiLocale::t('order.not_found'));
        }
        if ($userId > 0 && (int) $order->user_id !== $userId) {
            return $this->error(ApiLocale::t('order.forbidden'));
        }

        return $this->success([
            'order'    => $order,
            'accounts' => GcashService::publicAccountsPayload(),
        ]);
    }
}
