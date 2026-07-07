<?php
namespace app\controller;

use app\BaseController;
use app\model\Order as OrderModel;
use app\model\OrderItem;
use app\model\Product;
use app\model\UserLog;
use app\model\AdminLog;
use app\service\AffiliateService;
use think\facade\Request;
use think\facade\Db;
use app\support\ApiLocale;
use app\support\MediaUrl;

class Order extends BaseController
{
    private function enrichOrderListItem($item): void
    {
        $item->user_name = $item->user ? ($item->user->nickname ?: $item->user->username) : 'Unknown';
        $item->created_at_text = self::formatTimestamp($item->created_at ?? null);
        $item->user_paid_at_text = self::formatTimestamp($item->user_paid_at ?? null);
        if (!empty($item->payment_proof_image)) {
            $item->payment_proof_image_url = MediaUrl::toAbsolute((string) $item->payment_proof_image);
        } else {
            $item->payment_proof_image_url = '';
        }
        $item->address_text = self::formatAddressSnapshot($item->address_snapshot ?? null);
    }

    private static function formatAddressSnapshot($snapshot): string
    {
        if ($snapshot === null || $snapshot === '') {
            return '';
        }
        $snap = is_string($snapshot) ? json_decode($snapshot, true) : $snapshot;
        if (!is_array($snap)) {
            return (string) $snapshot;
        }
        $region = trim(implode(' ', array_filter([
            $snap['province'] ?? '',
            $snap['city'] ?? '',
            $snap['district'] ?? '',
            $snap['detail'] ?? '',
        ])));
        $parts = array_filter([$snap['name'] ?? '', $snap['phone'] ?? '', $region]);
        return implode(' · ', $parts);
    }

    private static function formatTimestamp($value): string
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

    public function create()
    {
        $data = Request::only(['user_id', 'items', 'address', 'total_amount', 'remark']);
        
        if (empty($data['user_id']) || empty($data['items'])) {
            return $this->error(ApiLocale::t('order.params_incomplete'));
        }

        // Start transaction
        Db::startTrans();
        try {
            $goodsAmount = 0;
            foreach ($data['items'] as $item) {
                $goodsAmount += (float) $item['price'] * (int) ($item['quantity'] ?? 1);
            }
            $buyerId = (int) $data['user_id'];
            [$b1, $b2, $b3] = AffiliateService::snapshotBeneficiaries($buyerId);

            $now = time();
            $order = OrderModel::create([
                'order_no'      => 'ORD' . date('YmdHis') . rand(1000, 9999),
                'user_id'       => $buyerId,
                'total_amount'  => $data['total_amount'],
                'goods_amount'  => $goodsAmount > 0 ? $goodsAmount : $data['total_amount'],
                'status'        => 0,
                'payment_method'   => 'gcash',
                'payment_status'   => 'pending',
                'paid_at'       => null,
                'remark'        => $data['remark'] ?? '',
                'address_snapshot' => isset($data['address']) ? json_encode($data['address']) : '',
                'b1_user_id'    => $b1,
                'b2_user_id'    => $b2,
                'b3_user_id'    => $b3,
                'created_at'    => $now,
                'updated_at'    => $now,
            ]);
            
            foreach ($data['items'] as $item) {
                // Check stock
                $product = Product::find($item['id']);
                if (!$product) {
                    throw new \Exception(ApiLocale::t('order.product_not_found', null, ['name' => $item['name']]));
                }
                if ($product->stock < ($item['quantity'] ?? 1)) {
                    throw new \Exception(ApiLocale::t('order.stock_insufficient', null, ['name' => $item['name']]));
                }

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['id'], 
                    'product_name' => $item['name'],
                    'product_image' => $item['image'],
                    'price' => $item['price'],
                    'quantity' => $item['quantity'] ?? 1,
                    'variant_name' => $item['variant_name'] ?? ''
                ]);
                
                // Decrease stock
                $product->dec('stock', $item['quantity'] ?? 1)->save();
            }

            // Log User Action
            UserLog::create([
                'user_id' => $data['user_id'],
                'action' => 'create_order',
                'ip' => Request::ip(),
                'detail' => "创建订单 {$order->order_no}"
            ]);

            Db::commit();
            return $this->success($order);
        } catch (\Throwable $e) {
            Db::rollback();
            return $this->error(ApiLocale::t('order.create_failed') . ': ' . $e->getMessage());
        }
    }

    public function index()
    {
        $limit = (int) Request::param('limit', 50);
        $status = Request::param('status');
        $paymentStatus = Request::param('payment_status');
        $keyword = Request::param('keyword'); // Replaces order_no specific param
        $user_id = Request::param('user_id');

        $query = OrderModel::with(['items', 'user'])->order('created_at', 'desc');
        
        if ($user_id) {
            $query->where('user_id', $user_id);
        }
        
        if (!is_null($status) && $status !== '' && $status !== 'all') {
            $query->where('status', $status);
        }

        if (!is_null($paymentStatus) && $paymentStatus !== '' && $paymentStatus !== 'all') {
            $query->where('payment_status', $paymentStatus);
        }
        
        if ($keyword) {
            $query->where(function ($q) use ($keyword) {
                $q->where('order_no', 'like', "%{$keyword}%")
                  ->orWhereHas('user', function ($uq) use ($keyword) {
                      $uq->where('username', 'like', "%{$keyword}%")
                         ->orWhere('nickname', 'like', "%{$keyword}%");
                  });
            });
        }

        $list = $query->paginate($limit);
        
        $list->each(function ($item) {
            $this->enrichOrderListItem($item);
        });

        return $this->success($list);
    }

    public function read($id)
    {
        $order = OrderModel::with(['items', 'user'])->find($id);
        if (!$order) return $this->error(ApiLocale::t('order.not_found'));
        
        $this->enrichOrderListItem($order);
        
        return $this->success($order);
    }

    public function save()
    {
        $data = Request::only(['id', 'status', 'express_company', 'express_no', 'remark']);

        if (empty($data['id'])) {
            return $this->error(ApiLocale::t('order.id_required'));
        }

        $order = OrderModel::find($data['id']);
        if (!$order) {
            return $this->error(ApiLocale::t('order.not_found'));
        }

        $oldStatus = (int) $order->status;
        $update = [];
        if (array_key_exists('status', $data) && $data['status'] !== null && $data['status'] !== '') {
            $update['status'] = (int) $data['status'];
        }
        if (array_key_exists('express_company', $data)) {
            $update['express_company'] = (string) $data['express_company'];
        }
        if (array_key_exists('express_no', $data)) {
            $update['express_no'] = (string) $data['express_no'];
        }
        if (array_key_exists('remark', $data)) {
            $update['remark'] = (string) $data['remark'];
        }

        if ($update === []) {
            return $this->error(ApiLocale::t('order.params_incomplete'));
        }

        $order->save($update);

        $order = OrderModel::find($data['id']);
        $newStatus = (int) $order->status;

        if ($newStatus === 3 && $oldStatus !== 3) {
            if (empty($order->confirmed_at)) {
                $order->confirmed_at = time();
                $order->save();
            }
            $order = OrderModel::find($data['id']);
            AffiliateService::onOrderCompleted($order);
        }

        $detail = "订单 {$order->order_no} 状态 {$oldStatus}→{$newStatus}";
        if (!empty($update['express_company']) || !empty($update['express_no'])) {
            $detail .= " 物流 {$order->express_company}:{$order->express_no}";
        }
        $this->log('更新', '订单', $detail);

        $this->enrichOrderListItem($order);

        return $this->success($order);
    }
    
    public function ship()
    {
        $id = Request::param('id');
        $company = Request::param('express_company');
        $no = Request::param('express_no');
        
        $order = OrderModel::find($id);
        if (!$order) return $this->error(ApiLocale::t('order.not_found'));
        
        $order->status = 2; // Shipped
        $order->express_company = $company;
        $order->express_no = $no;
        $order->save();
        
        // Log Admin Action
        $this->log('发货', '订单', "订单发货 {$order->order_no} ({$company}: {$no})");
        
        return $this->success($order);
    }
    
    public function delete($id)
    {
        $order = OrderModel::find($id);
        if ($order) {
            $order->delete();
            $this->log('删除', '订单', "删除订单: {$order->order_no}");
        }
        return $this->success(null, ApiLocale::t('common.delete_ok'));
    }

    /** 会员删除自己的订单（待付款/已取消） */
    public function userDelete()
    {
        $userId  = (int) Request::param('user_id', 0);
        $orderId = (int) Request::param('order_id', 0);
        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }
        if ($orderId <= 0) {
            return $this->error(ApiLocale::t('order.id_required'));
        }

        $order = OrderModel::with(['items'])->find($orderId);
        if (!$order) {
            return $this->error(ApiLocale::t('order.not_found'));
        }
        if ((int) $order->user_id !== $userId) {
            return $this->error(ApiLocale::t('order.forbidden'));
        }
        if (!$this->canUserDeleteOrder($order)) {
            return $this->error(ApiLocale::t('order.cannot_delete'));
        }

        Db::startTrans();
        try {
            $this->restoreOrderStock($order);
            $orderNo = (string) $order->order_no;
            $order->delete();

            UserLog::create([
                'user_id' => $userId,
                'action'  => 'delete_order',
                'ip'      => Request::ip(),
                'detail'  => "删除订单 {$orderNo}",
            ]);

            Db::commit();

            return $this->success(null, ApiLocale::t('order.delete_ok'));
        } catch (\Throwable $e) {
            Db::rollback();

            return $this->error(ApiLocale::t('order.delete_failed') . ': ' . $e->getMessage());
        }
    }

    private function canUserDeleteOrder(OrderModel $order): bool
    {
        $status = (int) $order->status;
        $ps     = (string) ($order->payment_status ?? 'pending');

        if ($status === 4) {
            return true;
        }

        return $status === 0 && in_array($ps, ['pending', 'rejected'], true);
    }

    private function restoreOrderStock(OrderModel $order): void
    {
        foreach ($order->items as $item) {
            $pid = (int) $item->product_id;
            $qty = (int) $item->quantity;
            if ($pid > 0 && $qty > 0) {
                Product::where('id', $pid)->inc('stock', $qty)->update();
            }
        }
    }
}
