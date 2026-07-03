<?php
namespace app\controller;

use app\BaseController;
use app\model\User as UserModel;
use app\service\AffiliateService;
use think\facade\Request;
use app\support\ApiLocale;

class Affiliate extends BaseController
{
    /** 前台展示：等级规则、佣金比例、文案（不含敏感后台字段） */
    public function publicConfig()
    {
        return json(['code' => 0, 'data' => AffiliateService::publicConfigPayload()]);
    }

    /** 校验邀请码是否存在 */
    public function inviteLookup()
    {
        $code = trim((string) Request::param('code', ''));
        if ($code === '') {
            return json(['code' => 400, 'msg' => ApiLocale::t('affiliate.code_missing')]);
        }
        $u = UserModel::where('invite_code', $code)->find();
        if (!$u) {
            return json(['code' => 404, 'msg' => ApiLocale::t('affiliate.code_invalid')]);
        }

        return json([
            'code' => 0,
            'data' => [
                'nickname'    => $u->nickname ?: $u->username,
                'invite_code' => $u->invite_code,
            ],
        ]);
    }

    /** 记录推广链接访问（ref 参数 + 可选商品 ID） */
    public function trackClick()
    {
        $code = trim((string) Request::param('ref', Request::param('code', '')));
        $productId = (int) Request::param('product_id', 0);
        if ($code === '') {
            return json(['code' => 400, 'msg' => ApiLocale::t('affiliate.code_missing')]);
        }
        $ok = AffiliateService::trackLinkClick($code, $productId);
        if (!$ok) {
            return json(['code' => 404, 'msg' => ApiLocale::t('affiliate.code_invalid')]);
        }

        return json(['code' => 0, 'msg' => 'ok']);
    }
}
