<?php
declare(strict_types=1);

namespace app\support;

use think\Request;

/**
 * API 回傳訊息多語系（依請求標頭 X-Locale：zh-TW | en）。
 */
final class ApiLocale
{
    public static function current(?Request $request = null): string
    {
        $req = $request ?? request();
        $h = strtolower(trim((string) $req->header('X-Locale', '')));
        if ($h === '' || $h === 'default') {
            return 'en';
        }
        if ($h === 'zh-tw' || str_starts_with($h, 'zh')) {
            return 'zh-TW';
        }
        if ($h === 'en' || str_starts_with($h, 'en')) {
            return 'en';
        }
        return 'en';
    }

    /** @return array<string, string> */
    private static function messages(string $locale): array
    {
        static $cache = [];
        if (!isset($cache[$locale])) {
            $dir = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'lang' . DIRECTORY_SEPARATOR;
            $file = $locale === 'en' ? 'api_en.php' : 'api_zh-TW.php';
            $path = $dir . $file;
            $cache[$locale] = is_file($path) ? (require $path) : [];
        }
        return $cache[$locale];
    }

    public static function t(string $key, ?Request $request = null, array $replace = []): string
    {
        $loc = self::current($request);
        $map = self::messages($loc);
        $s = $map[$key] ?? null;
        if ($s === null) {
            $other = $loc === 'en' ? 'zh-TW' : 'en';
            $fallback = self::messages($other);
            $s = $fallback[$key] ?? $key;
        }
        foreach ($replace as $rk => $rv) {
            $s = str_replace('{' . $rk . '}', (string) $rv, $s);
        }
        return $s;
    }
}
