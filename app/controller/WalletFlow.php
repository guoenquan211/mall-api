<?php
declare(strict_types=1);

namespace app\controller;

use app\BaseController;
use app\service\WalletFlowService;
use app\support\ApiLocale;
use think\facade\Request;

class WalletFlow extends BaseController
{
    /** 用户端：查看本人资金流水 */
    public function userIndex()
    {
        $userId = (int) Request::param('user_id', 0);
        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }

        return $this->success(WalletFlowService::listFlows($this->queryParams($userId)));
    }

    /** 管理端：全部或指定用户资金流水 */
    public function adminIndex()
    {
        $userId = (int) Request::param('user_id', 0);

        return $this->success(WalletFlowService::listFlows($this->queryParams($userId)));
    }

    /**
     * @return array<string, mixed>
     */
    private function queryParams(int $userId): array
    {
        return [
            'user_id' => $userId,
            'type'    => Request::param('type', 'all'),
            'status'  => Request::param('status', ''),
            'keyword' => Request::param('keyword', ''),
            'page'    => Request::param('page', 1),
            'limit'   => Request::param('limit', 20),
        ];
    }
}
