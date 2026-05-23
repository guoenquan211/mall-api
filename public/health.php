<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$mods = get_loaded_extensions();
$hasSqlite = in_array('pdo_sqlite', $mods, true);
$dbOk = false;
$dbError = null;

if ($hasSqlite) {
    $root = dirname(__DIR__);
    $dbFile = $root . DIRECTORY_SEPARATOR . 'database.sqlite';
    try {
        $pdo = new PDO('sqlite:' . $dbFile);
        $pdo->query('SELECT 1');
        $dbOk = true;
    } catch (Throwable $e) {
        $dbError = $e->getMessage();
    }
}

echo json_encode([
    'php'           => PHP_VERSION,
    'pdo_sqlite'    => $hasSqlite,
    'database_file' => $dbOk,
    'database_error'=> $dbError,
    'sapi'          => PHP_SAPI,
], JSON_UNESCAPED_UNICODE);
