<?php
/**
 * 将数据库中 Unsplash 外链替换为路径 /images/stock/*.jpg（前端在 src/assets 中解析）
 * 用法：cd backend && php scripts/migrate_unsplash_to_local.php
 */
declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

$app = new think\App();
$app->initialize();

use think\facade\Db;

$map = [
    'photo-1620916566398' => '/images/stock/lotion.jpg',
    'photo-1612817288484' => '/images/stock/tube.jpg',
    'photo-1570172619644' => '/images/stock/spa.jpg',
    'photo-1556228578'     => '/images/stock/hero.jpg',
    'photo-1525331282665'  => '/images/stock/news.jpg',
    'photo-1598528652309'  => '/images/stock/admin-login.jpg',
];

$tables = [
    ['products', 'image'],
    ['news', 'image'],
    ['knowledge', 'image'],
];

foreach ($tables as [$table, $col]) {
    try {
        $rows = Db::name($table)->where($col, 'like', '%unsplash.com%')->select();
        $n = 0;
        foreach ($rows as $row) {
            $url = (string) $row[$col];
            $local = $url;
            foreach ($map as $needle => $path) {
                if (str_contains($url, $needle)) {
                    $local = $path;
                    break;
                }
            }
            if ($local !== $url) {
                Db::name($table)->where('id', $row['id'])->update([$col => $local]);
                $n++;
            }
        }
        echo "{$table}.{$col}: updated {$n} row(s)\n";
    } catch (Throwable $e) {
        echo "SKIP {$table}: {$e->getMessage()}\n";
    }
}

echo "Done.\n";
