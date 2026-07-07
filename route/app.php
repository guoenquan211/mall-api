<?php
use think\facade\Route;

// Captcha Route
Route::get('captcha/[:config]', '\\think\\captcha\\CaptchaController@index');

Route::group('api', function () {
    // Admin Routes
    Route::post('login', 'Admin/login');
    Route::get('admins', 'Admin/index');
    Route::post('admins/save', 'Admin/save');
    Route::delete('admins/:id', 'Admin/delete');

    // 商品分类字典（须在 products 相关路由之外单独注册）
    Route::get('product-categories', 'ProductCategory/index');
    Route::post('product-categories/save', 'ProductCategory/save');
    Route::delete('product-categories/:id', 'ProductCategory/delete');

    // Product Routes（须先注册更具体路径，避免 products 前缀吞掉 products/:id）
    Route::get('products/categories', 'Product/categories');
    Route::get('products/:id', 'Product/read');
    Route::delete('products/:id', 'Product/delete');
    Route::post('products/:id/status', 'Product/setStatus');
    Route::get('products', 'Product/index');
    Route::post('products/save', 'Product/save');

    // User Routes
    Route::get('users/:id/wallet-overview', 'User/walletOverview');
    Route::get('users/:id/addresses', 'User/addresses');
    Route::post('users/wallet-adjust', 'User/walletAdjust');
    Route::get('users', 'User/index');
    Route::post('users/save', 'User/save');
    // Frontend User Auth
    Route::post('user/login', 'User/login');
    Route::post('user/register', 'User/register');
    Route::get('user/affiliate-summary', 'User/affiliateSummary');
    Route::get('user/wallet-flows', 'WalletFlow/userIndex');
    Route::get('user/info/:id', 'User/info');
    Route::post('user/profile', 'User/updateProfile');
    Route::post('user/delete-order', 'Order/userDelete');

    Route::get('gcash/public-accounts', 'Gcash/publicAccounts');
    Route::get('gcash/wallet-summary', 'Gcash/walletSummary');
    Route::post('gcash/bind', 'Gcash/bindGcash');
    Route::post('gcash/mark-order-paid', 'Gcash/markOrderPaid');
    Route::post('gcash/withdraw', 'Gcash/createWithdrawal');
    Route::get('gcash/my-withdrawals', 'Gcash/myWithdrawals');
    Route::get('gcash/order-payment/:id', 'Gcash/orderPaymentInfo');

    Route::get('gcash-admin/accounts', 'GcashAdmin/accounts');
    Route::post('gcash-admin/accounts/save', 'GcashAdmin/saveAccount');
    Route::get('gcash-admin/payment-reviews', 'GcashAdmin/paymentReviews');
    Route::post('gcash-admin/payment-approve', 'GcashAdmin/approvePayment');
    Route::post('gcash-admin/payment-reject', 'GcashAdmin/rejectPayment');
    Route::get('gcash-admin/withdrawals', 'GcashAdmin/withdrawals');
    Route::post('gcash-admin/withdrawal-approve', 'GcashAdmin/approveWithdrawal');
    Route::post('gcash-admin/withdrawal-reject', 'GcashAdmin/rejectWithdrawal');

    Route::get('wallet-flows', 'WalletFlow/adminIndex');

    Route::get('affiliate/public-config', 'Affiliate/publicConfig');
    Route::get('affiliate/invite-lookup', 'Affiliate/inviteLookup');
    Route::post('affiliate/track-click', 'Affiliate/trackClick');
    Route::get('home/public-config', 'SiteHome/publicConfig');
    Route::get('affiliate-admin/config', 'AffiliateAdmin/getConfig');
    Route::post('affiliate-admin/config', 'AffiliateAdmin/saveConfig');
    Route::post('affiliate-admin/unlock-commissions', 'AffiliateAdmin/unlockCommissions');
    Route::post('affiliate-admin/settle-commissions', 'AffiliateAdmin/settleCommissions');
    Route::post('affiliate-admin/run-cron', 'AffiliateAdmin/runCron');
    Route::get('home-admin/config', 'SiteHomeAdmin/getConfig');
    Route::post('home-admin/config', 'SiteHomeAdmin/saveConfig');

    // Admin manages user addresses
    Route::get('addresses', 'User/addresses'); // If query by user_id
    Route::post('addresses/save', 'User/saveAddress');
    Route::delete('addresses/:id', 'User/deleteAddress');

    // Order Routes（具体路径须在 orders 列表之前）
    Route::get('orders/:id', 'Order/read');
    Route::get('orders', 'Order/index');
    Route::post('orders/save', 'Order/save');
    Route::post('orders/create', 'Order/create');
    Route::post('orders/ship', 'Order/ship');
    Route::delete('orders/:id', 'Order/delete');

    // News/Knowledge Routes
    Route::get('news', 'News/index')->append(['type' => 'news']);
    Route::post('news/:id/status', 'News/setStatus');
    Route::get('news/:id', 'News/read');
    Route::post('news/save', 'News/save');
    Route::delete('news/:id', 'News/delete');
    
    // Knowledge specific alias
    Route::get('knowledge', 'News/index')->append(['type' => 'knowledge']);

    // Log Routes
    Route::get('logs', 'Log/index');
    Route::post('logs/add', 'Log/save'); // Frontend calls addLog

    // Stats Routes
    Route::get('stats', 'Stats/index');
    Route::get('stats/traffic', 'Stats/traffic');
    Route::get('stats/trends', 'Stats/trends');

    // Upload Routes
    Route::post('upload/image', 'Upload/image');

    Route::post('contact/submit', 'ContactMessage/submit');
    Route::get('contact-messages', 'ContactMessage/adminIndex');
    Route::delete('contact-messages/:id', 'ContactMessage/adminDelete');

});
