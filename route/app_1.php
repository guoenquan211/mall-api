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
    Route::get('users/:id/addresses', 'User/addresses'); // Specific route first
    Route::get('users', 'User/index');
    Route::post('users/save', 'User/save');
    // Frontend User Auth
    Route::post('user/login', 'User/login');
    Route::post('user/register', 'User/register');
    Route::get('user/affiliate-summary', 'User/affiliateSummary');
    Route::get('user/info/:id', 'User/info');

    Route::get('affiliate/public-config', 'Affiliate/publicConfig');
    Route::get('affiliate/invite-lookup', 'Affiliate/inviteLookup');
    Route::get('affiliate-admin/config', 'AffiliateAdmin/getConfig');
    Route::post('affiliate-admin/config', 'AffiliateAdmin/saveConfig');
    Route::post('affiliate-admin/unlock-commissions', 'AffiliateAdmin/unlockCommissions');
    Route::post('affiliate-admin/settle-commissions', 'AffiliateAdmin/settleCommissions');

    // Admin manages user addresses via User controller or dedicated Address controller? 
    // Admin likely manages addresses under User detail.
    // Let's add address management routes
    Route::get('addresses', 'User/addresses'); // If query by user_id
    Route::post('addresses/save', 'User/saveAddress');
    Route::delete('addresses/:id', 'User/deleteAddress');

    // Order Routes
    Route::get('orders', 'Order/index');
    Route::get('orders/:id', 'Order/read');
    Route::post('orders/save', 'Order/save');
    Route::post('orders/create', 'Order/create');
    Route::post('orders/ship', 'Order/ship');
    Route::delete('orders/:id', 'Order/delete');

    // News/Knowledge Routes
    Route::get('news', 'News/index')->append(['type' => 'news']); 
    Route::get('news/:id', 'News/read');
    Route::post('news/save', 'News/save');
    Route::delete('news/:id', 'News/delete');
    
    // Knowledge specific alias
    Route::get('knowledge', 'News/index')->append(['type' => 'knowledge']);

    // Log Routes
    Route::get('logs', 'Log/index');
    Route::post('logs/add', 'Log/save'); // Frontend calls addLog

    // Stats Routes
    Route::get('stats', 'Stats_1/index');
    Route::get('stats/traffic', 'Stats_1/traffic');
    Route::get('stats/trends', 'Stats_1/trends');

    // Upload Routes
    Route::post('upload/image', 'Upload/image');

    Route::post('contact/submit', 'ContactMessage_1/submit');
    Route::get('contact-messages', 'ContactMessage_1/adminIndex');
    Route::delete('contact-messages/:id', 'ContactMessage_1/adminDelete');

});
