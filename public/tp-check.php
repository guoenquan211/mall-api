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
    step($out, 'vendor', function () use ($root) {
        $autoload = $root . '/vendor/autoload.php';
        if (!is_file($autoload)) {
            throw new RuntimeException('vendor/autoload.php missing — run composer install');
        }
        require $autoload;
        return 'loaded';
    });

    step($out, 'env', function () use ($root) {
        $env = $root . '/.env';
        if (!is_file($env)) {
            throw new RuntimeException('.env missing — copy from .env.example (NOT .env.dev)');
        }
        $ini = parse_ini_file($env, true, INI_SCANNER_RAW);
        return [
            'file'   => '.env',
            'driver' => $ini['DATABASE']['DRIVER'] ?? $ini['DATABASE']['TYPE'] ?? '?',
            'db'     => $ini['DATABASE']['DATABASE'] ?? '?',
            'user'   => $ini['DATABASE']['USERNAME'] ?? '?',
        ];
    });

    step($out, 'extensions', function () {
        return [
            'pdo_mysql'  => extension_loaded('pdo_mysql'),
            'pdo_sqlite' => extension_loaded('pdo_sqlite'),
        ];
    });

    step($out, 'runtime', function () use ($root) {
        $dir = $root . '/runtime';
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        if (!is_writable($dir)) {
            throw new RuntimeException('runtime/ not writable — chmod 755 or chown www');
        }
        return is_writable($dir) ? 'writable' : 'not writable';
    });

    step($out, 'thinkphp', function () use ($root) {
        $app = new think\App();
        $app->initialize();
        $cfg = config('database');
        return [
            'default'  => $cfg['default'] ?? null,
            'database' => $cfg['connections'][$cfg['default']]['database'] ?? null,
        ];
    });

    step($out, 'db_connect', function () {
        \think\facade\Db::connect()->getPdo()->query('SELECT 1');
        return 'SELECT 1 ok';
    });

    step($out, 'tables', function () {
        $tables = ['products', 'product_categories', 'affiliate_program_config', 'users'];
        $info = [];
        foreach ($tables as $t) {
            $info[$t] = (int) \think\facade\Db::table($t)->count();
        }
        return $info;
    });

    step($out, 'api_products', function () {
        $count = \think\facade\Db::table('products')->where('status', 1)->count();
        return ['active_products' => $count];
    });

    $out['ok'] = true;
    $out['hint'] = 'Database OK. If /api still 500, clear runtime/cache/* and retry.';
} catch (Throwable $e) {
    $out['ok'] = false;
    $out['hint'] = match (true) {
        str_contains($e->getMessage(), 'could not find driver') =>
            'Enable pdo_mysql in Baota PHP 8.2 extensions, or set DRIVER=sqlite',
        str_contains($e->getMessage(), 'Access denied') =>
            'Fix .env DATABASE USERNAME/PASSWORD to match Baota MySQL',
        str_contains($e->getMessage(), "doesn't exist"), str_contains($e->getMessage(), 'no such table') =>
            'Import sql/mysql/schema_full.sql in Baota database panel',
        str_contains($e->getMessage(), '.env missing') =>
            'Create /www/wwwroot/.../.env with MySQL settings (ThinkPHP ignores .env.dev)',
        default => 'See failed step above',
    };
}

echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
