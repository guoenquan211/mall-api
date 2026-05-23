<?php
namespace app\controller;

use app\BaseController;
use app\model\Product as ProductModel;
use app\model\ProductCategory as ProductCategoryModel;
use think\facade\Request;
use app\support\ApiLocale;

class ProductCategory extends BaseController
{
    /**
     * 后台：全部分类（含停用），按排序
     */
    public function index()
    {
        $list = ProductCategoryModel::order('sort_order', 'asc')->order('id', 'asc')->select();

        return json([
            'code' => 0,
            'msg'  => 'success',
            'data' => $list,
        ]);
    }

    /**
     * 新增 / 编辑
     */
    public function save()
    {
        $data       = Request::only(['id', 'name', 'name_en', 'sort_order', 'status']);
        $name       = trim((string) ($data['name'] ?? ''));
        $nameEn     = trim((string) ($data['name_en'] ?? ''));
        $sortOrder  = (int) ($data['sort_order'] ?? 0);
        $status     = array_key_exists('status', $data) ? (int) $data['status'] : 1;

        if ($name === '') {
            return json(['code' => 400, 'msg' => ApiLocale::t('pcategory.name_required')]);
        }

        $q = ProductCategoryModel::where('name', $name);
        if (!empty($data['id'])) {
            $q->where('id', '<>', (int) $data['id']);
        }
        if ($q->find()) {
            return json(['code' => 400, 'msg' => ApiLocale::t('pcategory.name_exists')]);
        }

        $payload = [
            'name'        => $name,
            'name_en'     => $nameEn !== '' ? $nameEn : null,
            'sort_order'  => $sortOrder,
            'status'      => $status,
        ];

        if (!empty($data['id'])) {
            $row = ProductCategoryModel::find((int) $data['id']);
            if (!$row) {
                return json(['code' => 404, 'msg' => ApiLocale::t('pcategory.not_found')]);
            }
            $row->save($payload);
            $this->log('更新', '商品分类', "更新分类: {$name}");
        } else {
            ProductCategoryModel::create($payload);
            $this->log('新增', '商品分类', "新增分类: {$name}");
        }

        return json(['code' => 0, 'msg' => ApiLocale::t('common.save_ok')]);
    }

    /**
     * 删除（有商品引用时不允许）
     */
    public function delete($id)
    {
        $row = ProductCategoryModel::find((int) $id);
        if (!$row) {
            return json(['code' => 404, 'msg' => ApiLocale::t('pcategory.not_found')]);
        }

        $count = ProductModel::where('category', $row->name)->count();
        if ($count > 0) {
            return json(['code' => 400, 'msg' => ApiLocale::t('pcategory.has_products', null, ['count' => (string) $count])]);
        }

        $name = $row->name;
        $row->delete();
        $this->log('删除', '商品分类', "删除分类: {$name}");

        return json(['code' => 0, 'msg' => ApiLocale::t('common.delete_ok')]);
    }
}
