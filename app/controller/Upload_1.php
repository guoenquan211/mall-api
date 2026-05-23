<?php
namespace app\controller;

use app\BaseController;
use think\facade\Filesystem;
use think\facade\Request;
use app\support\ApiLocale;

class Upload extends BaseController
{
    public function image()
    {
        $file = Request::file('file');
        if (!$file) {
            return $this->error(ApiLocale::t('upload.no_file'));
        }

        $root = (string) (config('filesystem.disks.public.root') ?? (root_path() . 'public' . DIRECTORY_SEPARATOR . 'storage'));
        $root = rtrim(str_replace(['/', '\\'], DIRECTORY_SEPARATOR, $root), DIRECTORY_SEPARATOR);
        if (!is_dir($root)) {
            if (!@mkdir($root, 0775, true) && !is_dir($root)) {
                return $this->error(ApiLocale::t('upload.dir_create_fail'));
            }
        }
        if (!is_writable($root)) {
            return $this->error(ApiLocale::t('upload.dir_not_writable') . $root);
        }

        try {
            // think-validate fileSize 单位为字节；原 10240 仅 10KB，正常图片会被拒
            $this->validate(
                ['file' => $file],
                ['file' => 'fileSize:10485760|fileExt:jpg,jpeg,png,gif,webp']
            );

            $savename = Filesystem::disk('public')->putFile('uploads', $file);

            if ($savename) {
                return $this->success([
                    'url' => '/storage/' . str_replace('\\', '/', $savename),
                ]);
            }
        } catch (\think\exception\ValidateException $e) {
            return $this->error($e->getMessage());
        } catch (\Throwable $e) {
            return $this->error(ApiLocale::t('upload.failed') . ': ' . $e->getMessage());
        }

        return $this->error(ApiLocale::t('upload.save_failed'));
    }
}
