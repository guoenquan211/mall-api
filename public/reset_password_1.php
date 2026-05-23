<?php
require __DIR__ . '/../vendor/autoload.php';
use think\facade\Db;
$app = new \think\App();
$app->initialize();

$password = password_hash('123456', PASSWORD_DEFAULT);
echo "New password hash: " . $password . PHP_EOL;

try {
    // Update admin user
    $res = Db::name('admin_users')->where('username', 'admin')->update(['password' => $password]);
    echo "Admin password updated to '123456'. Result: " . $res . PHP_EOL;
    
    // Verify
    $user = Db::name('admin_users')->where('username', 'admin')->find();
    print_r($user);
    
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . PHP_EOL;
}
