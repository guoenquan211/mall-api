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
        $limit = (int) Request::param('limit', 10);
        if ($limit < 1) {
            $limit = 10;
        }
        if ($limit > 200) {
            $limit = 200;
        }

        $query = NewsModel::where('type', $type);
        $status = Request::param('status');
        if ($status !== null && $status !== '' && $status !== 'all') {
            $query->where('status', (int) $status);
        }

        $list = $query->order('created_at', 'desc')->paginate($limit);

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
            'type', 'icon', 'cover_image', 'image', 'date', 'source', 'status',
        ]);

        $cover = trim((string) ($data['cover_image'] ?? ''));
        $image = trim((string) ($data['image'] ?? ''));
        $data['cover_image'] = $cover !== '' ? $cover : ($image !== '' ? $image : null);
        unset($data['image']);

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
        $data['status'] = array_key_exists('status', $data) && $data['status'] !== null && $data['status'] !== ''
            ? ((int) $data['status'] === 1 ? 1 : 0)
            : 1;

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

    public function setStatus($id)
    {
        $status = Request::param('status');
        $item = NewsModel::find($id);
        if (!$item) {
            return $this->error(ApiLocale::t('news.not_found'));
        }

        $item->status = (int) $status === 1 ? 1 : 0;
        $item->save();

        $target = ($item->type ?? 'news') === 'knowledge' ? 'Knowledge' : 'News';
        $action = $item->status === 1 ? 'Publish' : 'Unpublish';
        $this->log($action, $target, "{$action} {$target}: {$item->title}");

        return $this->success($item);
    }

    public function delete($id)
    {
        NewsModel::destroy($id);
        return $this->success(null, ApiLocale::t('common.delete_ok'));
    }
}
