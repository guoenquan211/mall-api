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

class Order extends BaseController
{
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

            $order = OrderModel::create([
                'order_no'      => 'ORD' . date('YmdHis') . rand(1000, 9999),
                'user_id'       => $buyerId,
                'total_amount'  => $data['total_amount'],
                'goods_amount'  => $goodsAmount > 0 ? $goodsAmount : $data['total_amount'],
                'status'        => 1,
                'paid_at'       => time(),
                'remark'        => $data['remark'] ?? '',
                'address_snapshot' => isset($data['address']) ? json_encode($data['address']) : '',
                'b1_user_id'    => $b1,
                'b2_user_id'    => $b2,
                'b3_user_id'    => $b3,
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
        } catch (\Exception $e) {
            Db::rollback();
            return $this->error(ApiLocale::t('order.create_failed') . ': ' . $e->getMessage());
        }
    }

    public function index()
    {
        $limit = Request::param('limit', 10);
        $status = Request::param('status');
        $keyword = Request::param('keyword'); // Replaces order_no specific param
        $user_id = Request::param('user_id');

        $query = OrderModel::with(['items', 'user'])->order('created_at', 'desc');
        
        if ($user_id) {
            $query->where('user_id', $user_id);
        }
        
        if (!is_null($status) && $status !== '' && $status !== 'all') {
            $query->where('status', $status);
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
        
        // Append user_name attribute for frontend convenience
        $list->each(function($item) {
            $item->user_name = $item->user ? ($item->user->nickname ?: $item->user->username) : 'Unknown';
        });

        return $this->success($list);
    }

    public function read($id)
    {
        $order = OrderModel::with(['items', 'user'])->find($id);
        if (!$order) return $this->error(ApiLocale::t('order.not_found'));
        
        $order->user_name = $order->user ? ($order->user->nickname ?: $order->user->username) : 'Unknown';
        
        return $this->success($order);
    }

    public function save()
    {
        $data = Request::only(['id', 'status', 'express_company', 'express_no']);

        if (empty($data['id'])) {
            return $this->error(ApiLocale::t('order.id_required'));
        }

        $order = OrderModel::find($data['id']);
        if (!$order) {
            return $this->error(ApiLocale::t('order.not_found'));
        }

        $oldStatus = (int) $order->status;

        $order->save($data);

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
}
