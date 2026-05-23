<?php
namespace app\middleware;

use think\Response;

class Cors
{
    public function handle($request, \Closure $next)
    {
        $origin = $request->header('origin');
        
        // 允许的源域名
        $allowedOrigins = [
            'http://localhost:5173',
            'http://127.0.0.1:5173',
            'http://localhost:5174', // Admin
            'http://127.0.0.1:5174',
        ];

        // 默认头部
        $header = [
            'Access-Control-Allow-Methods' => 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers' => 'Authorization, Content-Type, If-Match, If-Modified-Since, If-None-Match, If-Unmodified-Since, X-Requested-With, Token',
            'Access-Control-Max-Age'       => '1728000',
        ];

        // 动态设置 Allow-Origin
        $header['Access-Control-Allow-Origin'] = $origin ?: '*';
        $header['Access-Control-Allow-Credentials'] = 'true';
        
        // 处理 OPTIONS 请求
        if ($request->method(true) == 'OPTIONS') {
            return Response::create()->code(204)->header($header);
        }

        $response = $next($request);

        // 确保响应对象是 Response 实例
        if (!($response instanceof Response)) {
            // 如果控制器直接返回了数据而不是Response对象（虽然TP8通常会自动转换，但保险起见）
            $response = Response::create($response);
        }
        
        return $response->header($header);
    }
}
