<?php
namespace app\controller;

use app\BaseController;
use app\model\Product as ProductModel;
use app\model\ProductCategory as ProductCategoryModel;
use app\model\ProductVariant;
use app\model\ProductImage;
use think\facade\Request;
use think\facade\Db;
use app\support\ApiLocale;

class Product extends BaseController
{
    /**
     * 获取商品列表
     */
    public function index()
    {
        $limit = Request::param('limit', 10);
        $status = Request::param('status');
        $keyword = Request::param('keyword');
        $category = Request::param('category');
        $showOnHome = Request::param('show_on_home', null);

        $where = [];
        if (!is_null($status)) {
            $where[] = ['status', '=', $status];
        }
        if ($showOnHome !== null && $showOnHome !== '') {
            $where[] = ['show_on_home', '=', (int) $showOnHome === 1 ? 1 : 0];
        }
        if ($keyword) {
            $where[] = ['name|name_en|description|description_en|category', 'like', "%{$keyword}%"];
        }
        if ($category) {
            $where[] = ['category', '=', $category];
        }

        $list = ProductModel::with(['variants']) // Load variants for min price check
            ->where($where)
            ->order('created_at', 'desc')
            ->paginate($limit);

        // Pre-process images if needed (though frontend usually handles URL)
        
        return json([
            'code' => 0,
            'msg' => 'success',
            'data' => $list
        ]);
    }

    /**
     * 上架商品的去重分类列表（供前台导航）
     */
    public function categories()
    {
        $catRows = ProductCategoryModel::where('status', 1)
            ->order('sort_order', 'asc')
            ->order('id', 'asc')
            ->select();

        $productNames = ProductModel::where('status', 1)
            ->whereNotNull('category')
            ->where('category', '<>', '')
            ->group('category')
            ->column('category');
        $productNames = array_values(array_filter($productNames));

        $inTable = [];
        foreach ($catRows as $r) {
            $inTable[$r->name] = true;
        }
        $extras = [];
        foreach ($productNames as $nm) {
            if ($nm !== '' && $nm !== null && !isset($inTable[$nm])) {
                $extras[] = $nm;
            }
        }
        sort($extras);

        $list = [];
        foreach ($catRows as $r) {
            $list[] = [
                'key' => $r->name,
                'name' => $r->name,
                'name_en' => $r->name_en,
            ];
        }
        foreach ($extras as $nm) {
            $list[] = [
                'key' => $nm,
                'name' => $nm,
                'name_en' => null,
            ];
        }

        // 前台导航/筛选不展示的历史兰花演示分类（商品仍可保留原 category，仅列表不返回）
        $hiddenNavCategories = ['墨兰', '惠兰', '蕙兰', '春兰'];
        $list = array_values(array_filter($list, static function ($item) use ($hiddenNavCategories) {
            return !in_array($item['key'], $hiddenNavCategories, true);
        }));

        return json([
            'code' => 0,
            'msg' => 'success',
            'data' => $list,
        ]);
    }

    /**
     * 获取商品详情
     */
    public function read($id)
    {
        $product = ProductModel::with(['variants', 'images'])->find($id);
        if (!$product) {
            return json(['code' => 404, 'msg' => ApiLocale::t('product.not_found')]);
        }
        if ($product->category) {
            $pc = ProductCategoryModel::where('name', $product->category)->find();
            $product->category_name_en = $pc ? ($pc->name_en ?? null) : null;
        }
        return json(['code' => 0, 'data' => $product]);
    }

    /**
     * 保存商品 (新增/编辑)
     */
    public function save()
    {
        $data = Request::only(['id', 'name', 'name_en', 'category', 'description', 'description_en', 'price', 'stock', 'status']);
        $data['show_on_home'] = filter_var(Request::param('show_on_home', 0), FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
        $variants = Request::param('variants', []);
        $images = Request::param('images', []);
        
        $name = trim((string) ($data['name'] ?? ''));
        $nameEn = trim((string) ($data['name_en'] ?? ''));
        if ($name === '') {
            $data['name'] = $nameEn;
            $name = $nameEn;
        }
        $data['name_en'] = $nameEn !== '' ? $nameEn : null;
        $de = $data['description_en'] ?? null;
        $data['description_en'] = ($de !== null && trim((string) $de) !== '') ? (string) $de : null;

        // Simple validation
        if (trim((string) ($data['name'] ?? '')) === '' || empty($data['price'])) {
            return json(['code' => 400, 'msg' => ApiLocale::t('product.name_price_required')]);
        }
        if (!isset($data['category']) || trim((string) $data['category']) === '') {
            return json(['code' => 400, 'msg' => ApiLocale::t('product.category_required')]);
        }

        // Use main image from images array if available
        $mainImage = !empty($images) ? $images[0] : null;
        $data['image'] = $mainImage;

        Db::startTrans();
        try {
            if (!empty($data['id'])) {
                $product = ProductModel::find($data['id']);
                if (!$product) {
                    throw new \Exception(ApiLocale::t('product.not_found'));
                }
                $product->save($data);
            } else {
                $product = ProductModel::create($data);
            }

            // Save Images
            ProductImage::where('product_id', $product->id)->delete();
            if (!empty($images)) {
                $imgData = [];
                foreach ($images as $k => $img) {
                    $imgData[] = [
                        'product_id' => $product->id,
                        'image' => $img,
                        'sort' => $k
                    ];
                }
                $product->images()->saveAll($imgData);
            }

            // Save Variants
            ProductVariant::where('product_id', $product->id)->delete();
            if (!empty($variants)) {
                $varData = [];
                foreach ($variants as $var) {
                    $varData[] = [
                        'product_id' => $product->id,
                        'name' => $var['name'],
                        'price' => $var['price'],
                        'stock' => $var['stock'],
                        'image' => $var['image'] ?? null
                    ];
                }
                $product->variants()->saveAll($varData);
            }

            Db::commit();
            
            // Add Log
            $action = !empty($data['id']) ? '更新' : '新增';
            $this->log($action, '商品', "{$action}商品: {$product->name}");
            
            return json(['code' => 0, 'msg' => ApiLocale::t('common.save_ok'), 'data' => $product]);
        } catch (\Exception $e) {
            Db::rollback();
            return json(['code' => 500, 'msg' => $e->getMessage()]);
        }
    }

    /**
     * 删除商品
     */
    public function delete($id)
    {
        $product = ProductModel::find($id);
        if ($product) {
            $product->delete();
            // Related data should be deleted via database foreign key cascade or manually here if no FK
            // Assuming FK Cascade is set in DB, otherwise:
            // ProductImage::where('product_id', $id)->delete();
            // ProductVariant::where('product_id', $id)->delete();
            
            $this->log('删除', '商品', "删除商品: {$product->name}");
        }
        return json(['code' => 0, 'msg' => ApiLocale::t('common.delete_ok')]);
    }

    /**
     * 上下架操作
     */
    public function setStatus($id)
    {
        $status = Request::param('status');
        $product = ProductModel::find($id);
        if (!$product) {
            return json(['code' => 404, 'msg' => ApiLocale::t('product.not_found')]);
        }
        $product->status = $status;
        $product->save();
        
        $action = $status == 1 ? '上架' : '下架';
        $this->log($action, '商品', "{$action}商品: {$product->name}");
        
        return json(['code' => 0, 'msg' => ApiLocale::t('common.success')]);
    }
}
