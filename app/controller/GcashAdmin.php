<?php
namespace app\controller;

use app\BaseController;
use app\model\GcashPlatformAccount;
use app\model\Order as OrderModel;
use app\model\WithdrawalRequest;
use app\service\GcashService;
use app\support\ApiLocale;
use app\support\MediaUrl;
use think\facade\Request;

class GcashAdmin extends BaseController
{
    public function accounts()
    {
        $list = GcashPlatformAccount::order('sort_order', 'asc')->order('slot', 'asc')->select();
        foreach ($list as $row) {
            if (!empty($row->qr_image)) {
                $row->qr_image = MediaUrl::toAbsolute((string) $row->qr_image);
            }
        }
        return $this->success($list);
    }

    public function saveAccount()
    {
        $data = Request::only(['id', 'slot', 'label', 'account_name', 'mobile', 'qr_image', 'is_active', 'sort_order']);
        $slot = (int) ($data['slot'] ?? 1);
        if ($slot < 1 || $slot > 2) {
            return $this->error(ApiLocale::t('gcash.slot_invalid'));
        }

        if (!empty($data['id'])) {
            $row = GcashPlatformAccount::find($data['id']);
            if (!$row) {
                return $this->error(ApiLocale::t('gcash.account_not_found'));
            }
        } else {
            $row = GcashPlatformAccount::where('slot', $slot)->find();
            if (!$row) {
                $row = new GcashPlatformAccount();
                $row->slot = $slot;
            }
        }

        $row->label        = (string) ($data['label'] ?? ('GCash 账号 ' . $slot));
        $row->account_name = $data['account_name'] ?? $row->account_name;
        $row->mobile       = $data['mobile'] ?? $row->mobile;
        if (array_key_exists('qr_image', $data)) {
            $row->qr_image = (string) $data['qr_image'];
        }
        $row->is_active    = isset($data['is_active']) ? (int) $data['is_active'] : 1;
        $row->sort_order   = (int) ($data['sort_order'] ?? $slot);
        $row->save();

        if (!empty($row->qr_image)) {
            $row->qr_image = MediaUrl::toAbsolute((string) $row->qr_image);
        }

        $this->log('更新', 'GCash收款', "配置账号 slot {$slot}");
        return $this->success($row);
    }

    /** 待审核付款（用户已点已付款） */
    public function paymentReviews()
    {
        $limit = (int) Request::param('limit', 20);
        $list = OrderModel::with(['items', 'user'])
            ->where('payment_status', 'user_confirmed')
            ->order('user_paid_at', 'desc')
            ->paginate($limit);

        $list->each(function ($item) {
            $item->user_name = $item->user ? ($item->user->nickname ?: $item->user->username) : '';
            $item->created_at_text = self::formatOrderTime($item->created_at ?? null);
            $item->user_paid_at_text = self::formatOrderTime($item->user_paid_at ?? null);
            $item->payment_proof_image_url = !empty($item->payment_proof_image)
                ? MediaUrl::toAbsolute((string) $item->payment_proof_image)
                : '';
        });

        return $this->success($list);
    }

    private static function formatOrderTime($value): string
    {
        if ($value === null || $value === '') {
            return '';
        }
        if (is_numeric($value)) {
            $ts = (int) $value;
            return $ts > 0 ? date('Y-m-d H:i:s', $ts) : '';
        }
        return (string) $value;
    }

    public function approvePayment()
    {
        $id = (int) Request::param('order_id', 0);
        $note = trim((string) Request::param('admin_note', ''));
        try {
            $order = GcashService::approveOrderPayment($id, $note);
            $this->log('审核通过', '订单付款', "订单 {$order->order_no}");
            return $this->success($order, ApiLocale::t('gcash.payment_approved'));
        } catch (\RuntimeException $e) {
            return $this->error(ApiLocale::t($e->getMessage()));
        }
    }

    public function rejectPayment()
    {
        $id = (int) Request::param('order_id', 0);
        $note = trim((string) Request::param('admin_note', ''));
        if ($note === '') {
            return $this->error(ApiLocale::t('order.reject_reason_required'));
        }
        try {
            $order = GcashService::rejectOrderPayment($id, $note);
            $this->log('驳回', '订单付款', "订单 {$order->order_no}");
            return $this->success($order, ApiLocale::t('gcash.payment_rejected'));
        } catch (\RuntimeException $e) {
            return $this->error(ApiLocale::t($e->getMessage()));
        }
    }

    public function withdrawals()
    {
        $status = Request::param('status', '');
        $limit  = (int) Request::param('limit', 20);
        $q = WithdrawalRequest::with('user')->order('id', 'desc');
        if ($status !== '' && $status !== 'all') {
            $q->where('status', $status);
        }
        $list = $q->paginate($limit);
        $list->each(function ($item) {
            $u = $item->user;
            $item->user_name = $u ? ($u->nickname ?: $u->username) : '';
        });
        return $this->success($list);
    }

    public function approveWithdrawal()
    {
        $id = (int) Request::param('id', 0);
        $ref = trim((string) Request::param('payout_ref', ''));
        $note = trim((string) Request::param('admin_note', ''));
        try {
            $row = GcashService::approveWithdrawal($id, $ref, $note);
            $this->log('通过', '佣金提现', "提现 #{$id} ¥{$row->amount}");
            return $this->success($row, ApiLocale::t('withdrawal.approved'));
        } catch (\RuntimeException $e) {
            return $this->error(ApiLocale::t($e->getMessage()));
        }
    }

    public function rejectWithdrawal()
    {
        $id = (int) Request::param('id', 0);
        $note = trim((string) Request::param('admin_note', ''));
        try {
            $row = GcashService::rejectWithdrawal($id, $note);
            $this->log('拒绝', '佣金提现', "提现 #{$id}");
            return $this->success($row, ApiLocale::t('withdrawal.rejected'));
        } catch (\RuntimeException $e) {
            return $this->error(ApiLocale::t($e->getMessage()));
        }
    }
}
