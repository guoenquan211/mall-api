<?php
declare(strict_types=1);

namespace app\controller;

use app\BaseController;
use app\model\ContactMessage as ContactMessageModel;
use app\support\ApiLocale;
use think\facade\Request;

class ContactMessage extends BaseController
{
    /** 前台提交留言（無需登入） */
    public function submit()
    {
        $name = trim((string) Request::param('visitor_name', Request::param('name', '')));
        $contact = trim((string) Request::param('contact', Request::param('email', '')));
        $content = trim((string) Request::param('content', Request::param('message', '')));

        $name = strip_tags($name);
        $contact = strip_tags($contact);
        $content = strip_tags($content);

        if ($name === '' || $content === '') {
            return $this->error(ApiLocale::t('contact.fields_required'));
        }

        if (mb_strlen($name) > 100) {
            return $this->error(ApiLocale::t('contact.name_too_long'));
        }
        if (mb_strlen($contact) > 255) {
            return $this->error(ApiLocale::t('contact.contact_too_long'));
        }
        if (mb_strlen($content) > 8000) {
            return $this->error(ApiLocale::t('contact.content_too_long'));
        }

        $loc = ApiLocale::current();
        if (!in_array($loc, ['en', 'zh-TW'], true)) {
            $loc = 'zh-TW';
        }

        ContactMessageModel::create([
            'visitor_name' => $name,
            'contact'      => $contact,
            'content'      => $content,
            'locale'       => $loc,
            'ip'           => (string) Request::ip(),
            'status'       => 0,
        ]);

        return $this->success(null, ApiLocale::t('contact.submit_ok'));
    }

    /** 後台列表 */
    public function adminIndex()
    {
        $limit = (int) Request::param('limit', 20);
        if ($limit < 1 || $limit > 100) {
            $limit = 20;
        }

        $list = ContactMessageModel::order('id', 'desc')->paginate($limit);

        return $this->success($list);
    }

    /** 後台刪除 */
    public function adminDelete(int $id)
    {
        $row = ContactMessageModel::find($id);
        if (!$row) {
            return $this->error(ApiLocale::t('contact.not_found'));
        }
        $preview = mb_substr((string) $row->visitor_name, 0, 40);
        $row->delete();
        $this->log('刪除', '顧客留言', "刪除留言 #{$id}：{$preview}");

        return $this->success(null, ApiLocale::t('common.delete_ok'));
    }
}
