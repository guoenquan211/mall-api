<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$result = [
    'php'         => PHP_VERSION,
    'pdo_mysql'   => extension_loaded('pdo_mysql'),
    'pdo_sqlite'  => extension_loaded('pdo_sqlite'),
    'env_file'    => null,
    'env_driver'  => null,
    'db_driver'   => null,
    'db_database' => null,
    'db_ok'       => false,
    'db_error'    => null,
    'tables'      => [],
    'products'    => null,
    'categories'  => null,
    'hint'        => null,
];

$root = dirname(__DIR__);
$envPath = $root . DIRECTORY_SEPARATOR . '.env';
$result['env_file'] = is_file($envPath) ? '.env' : (is_file($root . '/.env.dev') ? '.env.dev (only .env is loaded by ThinkPHP!)' : 'missing');

if (is_file($envPath)) {
    $envRaw = parse_ini_file($envPath, true, INI_SCANNER_RAW);
    $result['env_driver'] = $envRaw['DATABASE']['DRIVER'] ?? $envRaw['DATABASE']['TYPE'] ?? null;
}

try {
    require $root . '/vendor/autoload.php';
    $app = new think\App();
    $app->initialize();

    $dbCfg = config('database');
    $result['db_driver'] = $dbCfg['default'] ?? null;
    $conn = $dbCfg['connections'][$result['db_driver']] ?? [];
    $result['db_database'] = $conn['database'] ?? null;

    $pdo = \think\facade\Db::connect()->getPdo();
    $result['db_ok'] = true;

    $required = ['products', 'product_categories', 'product_variants', 'users', 'orders'];
    foreach ($required as $table) {
        try {
            $count = (int) \think\facade\Db::table($table)->count();
            $result['tables'][$table] = ['ok' => true, 'count' => $count];
        } catch (Throwable $e) {
            $result['tables'][$table] = ['ok' => false, 'error' => $e->getMessage()];
        }
    }

    try {
        $result['products'] = (int) \think\facade\Db::table('products')->where('status', 1)->count();
    } catch (Throwable $e) {
        $result['products'] = ['error' => $e->getMessage()];
    }

    try {
        $result['categories'] = (int) \think\facade\Db::table('product_categories')->where('status', 1)->count();
    } catch (Throwable $e) {
        $result['categories'] = ['error' => $e->getMessage()];
    }
} catch (Throwable $e) {
    $result['db_error'] = $e->getMessage();
}

if (!$result['db_ok']) {
    if ($result['env_driver'] === 'mysql' && !$result['pdo_mysql']) {
        $result['hint'] = 'PHP 未启用 pdo_mysql，请在宝塔 → PHP 8.2 → 安装扩展 → pdo_mysql';
    } elseif ($result['env_driver'] === 'mysql' && $result['db_driver'] === 'sqlite') {
        $result['hint'] = '请修改根目录 .env（不是 .env.dev），设置 [DATABASE] DRIVER = mysql';
    } elseif ($result['env_driver'] === 'sqlite') {
        $result['hint'] = '当前仍为 sqlite。生产环境请改 .env 为 mysql 并导入 sql/mysql/schema_full.sql';
    } else {
        $result['hint'] = '检查 .env 数据库账号密码，并确认已导入 sql/mysql/schema_full.sql';
    }
} elseif (isset($result['tables']['product_categories']) && $result['tables']['product_categories']['ok'] === false) {
    $result['hint'] = '表缺失：请在 MySQL 导入 mall-api/sql/mysql/schema_full.sql';
}

echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
