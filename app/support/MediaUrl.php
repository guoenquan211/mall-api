<?php
declare(strict_types=1);

namespace app\support;

use think\facade\Request;

/** 将 /storage、/uploads 等相对路径转为可访问的绝对 URL */
class MediaUrl
{
    public static function toAbsolute(string $path): string
    {
        $path = trim($path);
        if ($path === '') {
            return '';
        }
        if (preg_match('#^https?://#i', $path)) {
            return $path;
        }

        $path = str_replace('\\', '/', $path);
        if ($path[0] !== '/') {
            $path = '/' . $path;
        }

        $host = trim((string) (config('app.app_host') ?: env('APP_HOST', '')));
        if ($host !== '') {
            return rtrim($host, '/') . $path;
        }

        return Request::domain() . $path;
    }
}
