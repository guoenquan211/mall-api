<?php
namespace app\controller;

use app\BaseController;
use app\model\News as NewsModel;
use think\facade\Request;
use app\support\ApiLocale;

class News extends BaseController
{
    public function index()
    {
        $type = Request::param('type', 'news');
        $list = NewsModel::where('type', $type)
            ->order('created_at', 'desc')
            ->paginate(10);

        return json(['code' => 0, 'data' => $list]);
    }

    public function read($id)
    {
        $item = NewsModel::find($id);
        return json(['code' => 0, 'data' => $item]);
    }

    public function save()
    {
        $data = Request::only([
            'id', 'title', 'title_en', 'category', 'summary', 'summary_en', 'content', 'content_en',
            'type', 'icon', 'cover_image', 'date', 'source',
        ]);

        $title = trim((string) ($data['title'] ?? ''));
        $titleEn = trim((string) ($data['title_en'] ?? ''));
        if ($title === '' && $titleEn === '') {
            return $this->error(ApiLocale::t('news.title_or_title_en_required'));
        }
        if ($title === '') {
            $data['title'] = $titleEn;
        }
        $data['title_en'] = $titleEn !== '' ? $titleEn : null;
        $sumEn = trim((string) ($data['summary_en'] ?? ''));
        $data['summary_en'] = $sumEn !== '' ? $data['summary_en'] : null;
        $contEn = $data['content_en'] ?? null;
        $data['content_en'] = ($contEn !== null && trim((string) $contEn) !== '') ? (string) $contEn : null;

        if (!empty($data['id'])) {
            $item = NewsModel::find($data['id']);
            if (!$item) return $this->error(ApiLocale::t('news.not_found'));
            $item->save($data);
        } else {
            $item = NewsModel::create($data);
        }

        $target = ($data['type'] ?? 'news') === 'knowledge' ? 'Knowledge' : 'News';
        $action = !empty($data['id']) ? 'Update' : 'Create';
        $this->log($action, $target, "{$action} {$target}: {$item->title}");
        
        return $this->success($item);
    }

    public function delete($id)
    {
        NewsModel::destroy($id);
        return $this->success(null, ApiLocale::t('common.delete_ok'));
    }
}
