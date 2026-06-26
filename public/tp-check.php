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
            'file'  => $e->getFile(),
            'line'  => $e->getLine(),
        ];
        throw $e;
    }
}

try {
    if (!extension_loaded('pdo_mysql')) {
        throw new RuntimeException('pdo_mysql 未安装');
    }

    step($out, 'vendor', function () use ($root) {
        require $root . '/vendor/autoload.php';
        return 'loaded';
    });

    step($out, 'env', function () use ($root) {
        $env = $root . '/.env';
        if (!is_file($env)) {
            throw new RuntimeException('.env 不存在，从 .env.example 复制并填写 MySQL 账号');
        }
        $ini = parse_ini_file($env, true, INI_SCANNER_RAW);
        $db = $ini['DATABASE'] ?? [];
        if (empty($db['DATABASE']) || empty($db['USERNAME'])) {
            throw new RuntimeException('.env 缺少 [DATABASE] DATABASE 或 USERNAME');
        }
        return [
            'database' => $db['DATABASE'],
            'username' => $db['USERNAME'],
            'hostname' => $db['HOSTNAME'] ?? '127.0.0.1',
        ];
    });

    step($out, 'thinkphp', function () use ($root) {
        $app = new think\App();
        $app->initialize();
        $sessionDir = $root . '/runtime/session';
        if (!is_dir($sessionDir)) {
            mkdir($sessionDir, 0755, true);
        }
        if (!is_writable($sessionDir)) {
            throw new RuntimeException('runtime/session/ 不可写 — 验证码与注册需要 Session');
        }
        $cfg = config('database.connections.mysql');
        return [
            'default'  => config('database.default'),
            'database' => $cfg['database'] ?? null,
            'username' => $cfg['username'] ?? null,
            'session_dir' => is_writable($sessionDir) ? 'writable' : 'not writable',
        ];
    });

    step($out, 'db_connect', function () {
        \think\facade\Db::query('SELECT 1');
        return 'ok';
    });

    step($out, 'users_columns', function () {
        $required = ['parent_id', 'invite_code', 'affiliate_level', 'locale'];
        $rows = \think\facade\Db::query('SHOW COLUMNS FROM `users`');
        $cols = array_column($rows, 'Field');
        $missing = array_values(array_diff($required, $cols));
        if ($missing) {
            throw new RuntimeException('users 表缺少字段: ' . implode(', ', $missing) . ' — 执行 sql/mysql/migrations/009_users_register_columns.sql');
        }
        return $cols;
    });

    step($out, 'tables', function () {
        $info = [];
        foreach (['products', 'product_categories', 'affiliate_program_config', 'users'] as $t) {
            $info[$t] = (int) \think\facade\Db::table($t)->count();
        }
        return $info;
    });

    $out['ok'] = true;
} catch (Throwable $e) {
    $out['ok'] = false;
    $out['hint'] = match (true) {
        str_contains($e->getMessage(), 'pdo_mysql') =>
            '宝塔 → PHP 8.2 → 安装扩展 → pdo_mysql',
        str_contains($e->getMessage(), 'Access denied') =>
            '.env 里 USERNAME / PASSWORD 与宝塔数据库不一致',
        str_contains($e->getMessage(), "doesn't exist"), str_contains($e->getMessage(), 'Unknown database') =>
            '先在宝塔创建数据库，再导入 sql/mysql/schema_full.sql',
        str_contains($e->getMessage(), 'users 表缺少字段') =>
            $e->getMessage(),
        str_contains($e->getMessage(), 'runtime/session') =>
            $e->getMessage(),
        str_contains($e->getMessage(), '.env') =>
            $e->getMessage(),
        default => '导入 sql/mysql/schema_full.sql，并删除 runtime/cache/*',
    };
}

echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
