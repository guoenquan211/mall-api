<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$root = dirname(__DIR__);
$out = ['ok' => false, 'steps' => []];

function step(array &$out, string $name, callable $fn): void
{
    try {
        $result = $fn();
        $out['steps'][$name] = ['ok' => true, 'detail' => $result];
    } catch (Throwable $e) {
        $out['steps'][$name] = [
            'ok'    => false,
            'error' => $e->getMessage(),
        ];
        throw $e;
    }
}

try {
    require $root . '/vendor/autoload.php';
    $app = new think\App();
    $app->initialize();

    $dbName = (string) config('database.connections.mysql.database');
    $out['database'] = $dbName;

    step($out, 'tables', function () {
        $need = ['affiliate_program_config', 'user_affiliate_stats', 'commission_records'];
        $missing = [];
        foreach ($need as $t) {
            $rows = \think\facade\Db::query(
                'SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',
                [$t]
            );
            if (!$rows) {
                $missing[] = $t;
            }
        }
        if ($missing) {
            throw new RuntimeException('缺少表: ' . implode(', ', $missing));
        }
        return 'ok';
    });

    step($out, 'users_affiliate_columns', function () {
        $cols = array_column(\think\facade\Db::query('SHOW COLUMNS FROM `users`'), 'Field');
        $need = ['invite_code', 'parent_id', 'affiliate_level', 'total_paid_goods'];
        $missing = array_values(array_diff($need, $cols));
        if ($missing) {
            throw new RuntimeException('users 缺少字段: ' . implode(', ', $missing));
        }
        return $cols;
    });

    step($out, 'affiliate_config_row', function () {
        $n = (int) \think\facade\Db::table('affiliate_program_config')->where('id', 1)->count();
        if ($n < 1) {
            throw new RuntimeException('affiliate_program_config 无 id=1 配置行');
        }
        return $n;
    });

    step($out, 'commission_sum', function () {
        \think\facade\Db::table('commission_records')
            ->where('user_id', 1)
            ->where('status', 'pending')
            ->sum('amount');
        return 'ok';
    });

    step($out, 'user_affiliate_stats_rw', function () {
        $uid = 1;
        $s = \app\model\UserAffiliateStat::find($uid);
        if (!$s) {
            \app\model\UserAffiliateStat::create([
                'user_id'           => $uid,
                'downline_pv_total' => 0,
                'updated_at'        => time(),
            ]);
        }
        return 'ok';
    });

    step($out, 'user_save_timestamp', function () {
        $u = \app\model\User::find(1);
        if (!$u) {
            return 'skip: no user id=1';
        }
        $before = $u->invite_code;
        if (empty($before)) {
            $u->invite_code = 'TEST' . substr(md5((string) time()), 0, 6);
        }
        $u->save();
        if (empty($before)) {
            $u->invite_code = null;
            $u->save();
        }
        return 'ok (BaseModel 时间戳字段正常)';
    });

    step($out, 'downline_query', function () {
        \think\facade\Db::table('users')
            ->where('parent_id', 1)
            ->field('id,username,nickname,affiliate_level,total_paid_goods,created_at,status')
            ->select();
        return 'ok';
    });

    step($out, 'affiliate_service', function () {
        \app\service\AffiliateService::publicConfigPayload();
        \app\service\AffiliateService::directDownlineList(1);
        return 'ok';
    });

    $out['ok'] = true;
    $out['hint'] = '分销相关检查全部通过。若前台仍失败，请删除 runtime/cache/* 并确认已上传 app/model/BaseModel.php';
} catch (Throwable $e) {
    $out['ok'] = false;
    $out['hint'] = '在 phpMyAdmin 选中数据库「' . ($out['database'] ?? '?') . '」后执行 sql/mysql/migrations/010_affiliate_safe.sql；'
        . '并上传 app/model/BaseModel.php 与 app/model/*.php。失败步骤: ' . $e->getMessage();
}

echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
