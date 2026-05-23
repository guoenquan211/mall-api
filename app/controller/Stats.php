<?php
declare(strict_types=1);

namespace app\controller;

use app\BaseController;
use app\model\AdminLog;
use app\model\News;
use app\model\Order;
use app\model\OrderItem;
use app\model\Product;
use app\model\User;

class Stats extends BaseController
{
    /** 已付款及之後流程（計入營收） */
    private const PAID_STATUSES = [1, 2, 3];

    private static function now(): int
    {
        return time();
    }

    private static function dayStart(?int $ts = null): int
    {
        $ts = $ts ?? self::now();

        return (int) strtotime(date('Y-m-d 00:00:00', $ts));
    }

    private static function weekStartMonday(?int $ts = null): int
    {
        $ts = $ts ?? self::now();
        $w = (int) date('w', $ts);
        $daysFromMon = $w === 0 ? 6 : $w - 1;

        return self::dayStart($ts - $daysFromMon * 86400);
    }

    private static function monthStart(?int $ts = null): int
    {
        $ts = $ts ?? self::now();

        return (int) strtotime(date('Y-m-01 00:00:00', $ts));
    }

    public function index()
    {
        $t = self::now();
        $dayStart = self::dayStart($t);
        $weekStart = self::weekStartMonday($t);
        $monthStart = self::monthStart($t);
        $paid = self::PAID_STATUSES;

        $revenueTotal = (float) Order::whereIn('status', $paid)->sum('total_amount');
        $revenueToday = (float) Order::whereIn('status', $paid)->where('created_at', '>=', $dayStart)->sum('total_amount');
        $revenueWeek = (float) Order::whereIn('status', $paid)->where('created_at', '>=', $weekStart)->sum('total_amount');
        $revenueMonth = (float) Order::whereIn('status', $paid)->where('created_at', '>=', $monthStart)->sum('total_amount');

        $ordersPaidCount = (int) Order::whereIn('status', $paid)->count();
        $aov = $ordersPaidCount > 0 ? round($revenueTotal / $ordersPaidCount, 2) : 0.0;

        $data = [
            'products' => Product::count(),
            'users' => User::count(),
            'orders' => Order::count(),
            'news' => News::where('type', 'news')->count(),
            'knowledge' => News::where('type', 'knowledge')->count(),
            'sales' => [
                'revenue_total' => round($revenueTotal, 2),
                'revenue_today' => round($revenueToday, 2),
                'revenue_week' => round($revenueWeek, 2),
                'revenue_month' => round($revenueMonth, 2),
                'orders_pending_pay' => Order::where('status', 0)->count(),
                'orders_to_ship' => Order::where('status', 1)->count(),
                'orders_shipped' => Order::where('status', 2)->count(),
                'orders_completed' => Order::where('status', 3)->count(),
                'orders_cancelled' => Order::where('status', 4)->count(),
                'avg_order_value' => $aov,
                'users_week' => User::where('created_at', '>=', $weekStart)->count(),
            ],
        ];

        return $this->success($data);
    }

    /**
     * 營收構成：依商品分類（已付款訂單）；無明細時改為訂單狀態筆數分布。
     *
     * @return array<int, array{name: string, value: float|int}>
     */
    public function traffic()
    {
        $paid = self::PAID_STATUSES;
        $buckets = [];

        $rows = OrderItem::alias('oi')
            ->join('orders o', 'o.id = oi.order_id')
            ->leftJoin('products p', 'p.id = oi.product_id')
            ->whereIn('o.status', $paid)
            ->field(['oi.price', 'oi.quantity', 'p.category'])
            ->select();

        foreach ($rows as $row) {
            $rowArr = $row instanceof \think\Model ? $row->toArray() : (array) $row;
            $cat = isset($rowArr['category']) ? trim((string) $rowArr['category']) : '';
            if ($cat === '') {
                $cat = '其他';
            }
            $amt = (float) ($rowArr['price'] ?? 0) * (int) ($rowArr['quantity'] ?? 0);
            if ($amt <= 0) {
                continue;
            }
            $buckets[$cat] = ($buckets[$cat] ?? 0.0) + $amt;
        }

        $data = [];
        foreach ($buckets as $name => $value) {
            $data[] = ['name' => $name, 'value' => round((float) $value, 2)];
        }

        if ($data === []) {
            $labels = [
                0 => '待付款',
                1 => '待發貨',
                2 => '已發貨',
                3 => '已完成',
                4 => '已取消',
            ];
            foreach ([0, 1, 2, 3, 4] as $st) {
                $c = (int) Order::where('status', $st)->count();
                if ($c > 0) {
                    $data[] = ['name' => $labels[$st] ?? (string) $st, 'value' => $c];
                }
            }
        }

        if ($data === []) {
            $data[] = ['name' => '—', 'value' => 1];
        }

        return $this->success($data);
    }

    /**
     * 近 14 日：每日訂單數（不含取消）、已付款營收、後台操作次數（作為運營活躍度代理指標）。
     *
     * @return array<int, array{date: string, revenue: float, orders: int, activity: int}>
     */
    public function trends()
    {
        $days = 14;
        $out = [];
        $t = self::now();

        for ($i = $days - 1; $i >= 0; $i--) {
            $dayTs = $t - $i * 86400;
            $ymd = date('Y-m-d', $dayTs);
            $start = self::dayStart($dayTs);
            $end = $start + 86400 - 1;

            $orders = (int) Order::whereBetween('created_at', [$start, $end])
                ->where('status', '<>', 4)
                ->count();

            $revenue = (float) Order::whereBetween('created_at', [$start, $end])
                ->whereIn('status', self::PAID_STATUSES)
                ->sum('total_amount');

            $activity = (int) AdminLog::whereBetween('created_at', [$start, $end])->count();

            $out[] = [
                'date' => $ymd,
                'revenue' => round($revenue, 2),
                'orders' => $orders,
                'activity' => $activity,
            ];
        }

        return $this->success($out);
    }
}
