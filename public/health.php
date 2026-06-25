<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$result = [
    'php'         => PHP_VERSION,
    'pdo_mysql'   => extension_loaded('pdo_mysql'),
    'env_file'    => is_file(dirname(__DIR__) . '/.env') ? '.env' : 'missing',
    'db_database' => null,
    'db_ok'       => false,
    'db_error'    => null,
    'tables'      => [],
    'hint'        => null,
];

$root = dirname(__DIR__);

if (!extension_loaded('pdo_mysql')) {
    $result['hint'] = '宝塔 → PHP 8.2 → 安装扩展 → pdo_mysql';
    echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

try {
    require $root . '/vendor/autoload.php';
    $app = new think\App();
    $app->initialize();

    $conn = config('database.connections.mysql');
    $result['db_database'] = $conn['database'] ?? null;

    \think\facade\Db::connect()->getPdo()->query('SELECT 1');
    $result['db_ok'] = true;

    foreach (['products', 'product_categories', 'users', 'orders'] as $table) {
        try {
            $result['tables'][$table] = [
                'ok'    => true,
                'count' => (int) \think\facade\Db::table($table)->count(),
            ];
        } catch (Throwable $e) {
            $result['tables'][$table] = ['ok' => false, 'error' => $e->getMessage()];
        }
    }
} catch (Throwable $e) {
    $result['db_error'] = $e->getMessage();
}

if (!$result['db_ok']) {
    $result['hint'] = '检查 .env 里 DATABASE / USERNAME / PASSWORD，并导入 sql/mysql/schema_full.sql';
} elseif (isset($result['tables']['products']) && $result['tables']['products']['ok'] === false) {
    $result['hint'] = '导入 sql/mysql/schema_full.sql';
}

echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
