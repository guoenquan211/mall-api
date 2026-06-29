<?php
namespace app\controller;

use app\BaseController;
use app\model\User as UserModel;
use app\model\UserAddress;
use app\model\UserLog;
use app\model\CommissionRecord;
use app\service\AffiliateService;
use app\service\WalletAdjustService;
use app\support\ApiLocale;
use think\facade\Request;

class User extends BaseController
{
    /**
     * Helper: Add Log
     */
    private function recordLog($userId, $action, $detail)
    {
        UserLog::create([
            'user_id' => $userId,
            'action' => $action,
            'detail' => $detail,
            'ip' => Request::ip()
        ]);
    }

    public function login()
    {
        $username = Request::param('username');
        $password = Request::param('password');

        if (empty($username) || empty($password)) {
            return $this->error(ApiLocale::t('user.login_fields_required'));
        }

        $user = UserModel::where('username', $username)->find();
        if (!$user) {
            return $this->error(ApiLocale::t('user.not_found'));
        }

        $stored = (string)$user->password;
        $isHashed = str_starts_with($stored, '$2y$') || str_starts_with($stored, '$argon2');
        $valid = $isHashed ? password_verify($password, $stored) : ($stored === $password);
        if (!$valid) {
            return $this->error(ApiLocale::t('user.wrong_password'));
        }

        if ($user->status == 0) {
            return $this->error(ApiLocale::t('user.disabled'));
        }

        AffiliateService::ensureInviteCode($user);

        $loc = Request::param('locale', '');
        if (in_array($loc, ['zh-TW', 'en'], true) && (string) ($user->locale ?? '') !== $loc) {
            $user->locale = $loc;
            $user->save();
        }

        // Mock token
        $token = md5($user->id . time() . rand(1000, 9999));
        
        $this->recordLog($user->id, '登录', '用户登录成功');

        return $this->success([
            'token' => $token,
            'user' => $user
        ]);
    }

    public function register()
    {
        $data = Request::only(['username', 'password', 'nickname', 'phone', 'captcha', 'invite_code', 'ref']);

        if (empty($data['username']) || empty($data['password'])) {
            return $this->error(ApiLocale::t('user.register_fields_required'));
        }

        if (empty($data['captcha'])) {
            return $this->error(ApiLocale::t('user.captcha_required'));
        }

        if (!captcha_check(trim((string) $data['captcha']))) {
            return $this->error(ApiLocale::t('user.captcha_invalid'));
        }

        $invite = strtoupper(trim((string) ($data['invite_code'] ?? $data['ref'] ?? '')));
        unset($data['invite_code'], $data['ref']);

        $exist = UserModel::where('username', $data['username'])->find();
        if ($exist) {
            return $this->error(ApiLocale::t('user.username_taken'));
        }

        $parentId = null;
        if ($invite !== '') {
            $inv = UserModel::whereRaw('UPPER(invite_code) = ?', [$invite])->find();
            if ($inv) {
                $parentId = (int) $inv->id;
            }
        }

        $loc = Request::param('locale', 'en');
        $locale = in_array($loc, ['zh-TW', 'en'], true) ? $loc : 'en';

        $user = UserModel::create([
            'username'  => $data['username'],
            'password'  => password_hash($data['password'], PASSWORD_DEFAULT),
            'nickname'  => $data['nickname'] ?? $data['username'],
            'phone'     => $data['phone'] ?? null,
            'status'    => 1,
            'points'    => 0,
            'parent_id' => $parentId,
            'locale'    => $locale,
        ]);

        AffiliateService::ensureInviteCode($user);

        try {
            $this->recordLog($user->id, '注册', '用户注册成功');
        } catch (\Throwable $e) {
            // 日志写入失败不影响注册
        }

        return $this->success([
            'id'       => $user->id,
            'username' => $user->username,
            'nickname' => $user->nickname,
        ], ApiLocale::t('user.register_ok'));
    }

    public function info($id)
    {
        $user = UserModel::find($id);
        if (!$user) return $this->error(ApiLocale::t('user.not_found'));
        return $this->success($user);
    }

    /**
     * 会员中心：更新个人资料（用户名、昵称、手机、邮箱）
     */
    public function updateProfile()
    {
        $userId = (int) Request::param('user_id', 0);
        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }

        $user = UserModel::find($userId);
        if (!$user) {
            return $this->error(ApiLocale::t('user.not_found'));
        }

        if ((int) $user->status === 0) {
            return $this->error(ApiLocale::t('user.disabled'));
        }

        $username = trim((string) Request::param('username', ''));
        $nickname = trim((string) Request::param('nickname', ''));
        $phone    = trim((string) Request::param('phone', ''));
        $email    = trim((string) Request::param('email', ''));

        if ($username === '') {
            return $this->error(ApiLocale::t('user.username_required'));
        }

        if ($username !== $user->username) {
            $taken = UserModel::where('username', $username)->where('id', '<>', $userId)->find();
            if ($taken) {
                return $this->error(ApiLocale::t('user.username_taken'));
            }
            $user->username = $username;
        }

        $user->nickname = $nickname !== '' ? $nickname : $username;
        $user->phone    = $phone !== '' ? $phone : null;
        $user->email    = $email !== '' ? $email : null;

        if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->error(ApiLocale::t('user.email_invalid'));
        }

        $user->save();
        $this->recordLog($userId, '资料', '更新个人资料');

        return $this->success($user, ApiLocale::t('user.profile_updated'));
    }

    public function index()
    {
        $limit = Request::param('limit', 10);
        $username = Request::param('username');
        
        $query = UserModel::order('created_at', 'desc');
        if ($username) {
            $query->where('username', 'like', "%{$username}%");
        }
        
        $list = $query->paginate($limit);
        return $this->success($list);
    }

    public function save()
    {
        $data = Request::only(['id', 'username', 'nickname', 'phone', 'email', 'status', 'points', 'password']);
        
        if (!empty($data['id'])) {
            $user = UserModel::find($data['id']);
            if (!$user) return $this->error(ApiLocale::t('user.not_found'));
            if (!empty($data['password'])) {
                $data['password'] = password_hash($data['password'], PASSWORD_DEFAULT);
            } else {
                unset($data['password']);
            }
            $user->save($data);
            $this->log('更新', '用户', "更新用户: {$user->username}");
        } else {
            // Check username
            if (empty($data['username'])) return $this->error(ApiLocale::t('user.username_required'));
            if (empty($data['password'])) return $this->error(ApiLocale::t('user.password_required'));
            $exist = UserModel::where('username', $data['username'])->find();
            if ($exist) return $this->error(ApiLocale::t('user.username_taken'));
            
            $data['password'] = password_hash($data['password'], PASSWORD_DEFAULT);
            $data['nickname'] = $data['nickname'] ?? $data['username'];
            $data['status'] = isset($data['status']) ? $data['status'] : 1;
            $data['points'] = isset($data['points']) ? $data['points'] : 0;
            $user = UserModel::create($data);
            $this->log('新增', '用户', "新增用户: {$user->username}");
        }
        return $this->success($user);
    }

    // Address methods
    public function addresses($id = null)
    {
        $userId = $id ?? Request::param('user_id');
        if (empty($userId)) return $this->error(ApiLocale::t('user.id_required'));

        $list = UserAddress::where('user_id', $userId)->order('is_default', 'desc')->select();
        return $this->success($list);
    }

    public function saveAddress()
    {
        $data = Request::only(['id', 'user_id', 'name', 'phone', 'province', 'city', 'district', 'detail', 'is_default']);
        
        if (empty($data['user_id'])) return $this->error(ApiLocale::t('user.id_required'));

        if (!empty($data['is_default'])) {
            // Reset other defaults
            UserAddress::where('user_id', $data['user_id'])->update(['is_default' => 0]);
        }

        if (!empty($data['id'])) {
            $address = UserAddress::find($data['id']);
            if ($address) {
                $address->save($data);
                $this->recordLog($data['user_id'], '地址', "更新地址: {$address->id}");
            }
        } else {
            $address = UserAddress::create($data);
            $this->recordLog($data['user_id'], '地址', "新增地址: {$address->id}");
        }
        
        return $this->success($address);
    }

    public function deleteAddress($id)
    {
        // Ideally verify user ownership
        $address = UserAddress::find($id);
        if ($address) {
            $userId = $address->user_id;
            UserAddress::destroy($id);
            $this->recordLog($userId, '地址', "删除地址: {$id}");
        }
        return $this->success(null, ApiLocale::t('common.delete_ok'));
    }

    /**
     * 推广中心：邀请码、佣金汇总（演示环境按 user_id 查询）
     */
    /** 后台：用户钱包概览 */
    public function walletOverview($id = null)
    {
        $userId = (int) ($id ?? Request::param('user_id', 0));
        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }
        try {
            $data = WalletAdjustService::userWalletOverview($userId);
            return $this->success($data);
        } catch (\RuntimeException $e) {
            $key = $e->getMessage();
            $msg = str_starts_with($key, 'user.') || str_starts_with($key, 'wallet.')
                ? ApiLocale::t($key)
                : $key;
            return $this->error($msg);
        }
    }

    /** 后台：人工调账（赠送/扣减佣金或积分） */
    public function walletAdjust()
    {
        $payload = [
            'user_id'           => Request::param('user_id', 0),
            'type'              => Request::param('type', 'commission'),
            'direction'         => Request::param('direction', 'credit'),
            'amount'            => Request::param('amount', 0),
            'remark'            => Request::param('remark', ''),
            'commission_status' => Request::param('commission_status', 'available'),
        ];
        try {
            $result = WalletAdjustService::adjust($payload);
            $user = UserModel::find((int) $payload['user_id']);
            $uname = $user ? $user->username : (string) $payload['user_id'];
            $this->log('调账', '用户钱包', sprintf(
                '用户 %s %s %s %.2f 备注:%s',
                $uname,
                $payload['type'],
                $payload['direction'],
                (float) $payload['amount'],
                $payload['remark']
            ));
            return $this->success($result, ApiLocale::t('wallet.adjust_ok'));
        } catch (\RuntimeException $e) {
            $key = $e->getMessage();
            $msg = str_starts_with($key, 'user.') || str_starts_with($key, 'wallet.')
                ? ApiLocale::t($key)
                : $key;
            return $this->error($msg);
        }
    }

    public function affiliateSummary()
    {
        $userId = (int) Request::param('user_id', 0);
        if ($userId <= 0) {
            return $this->error(ApiLocale::t('user.id_required'));
        }
        $user = UserModel::find($userId);
        if (!$user) {
            return $this->error(ApiLocale::t('user.not_found'));
        }
        try {
            $code = AffiliateService::ensureInviteCode($user);
            $cfg  = AffiliateService::publicConfigPayload();

            $sum = static function (string $st) use ($userId): float {
                return (float) CommissionRecord::where('user_id', $userId)->where('status', $st)->sum('amount');
            };

            return $this->success([
                'invite_code'          => $code,
                'affiliate_level'      => (int) $user->affiliate_level,
                'parent_id'            => $user->parent_id ? (int) $user->parent_id : null,
                'total_paid_goods'     => (float) $user->total_paid_goods,
                'config'               => $cfg,
                'progress'             => AffiliateService::userAffiliateProgress($userId),
                'downline'             => AffiliateService::directDownlineList($userId),
                'commission_pending'   => $sum('pending'),
                'commission_available' => $sum('available'),
                'commission_settled'   => $sum('settled'),
            ]);
        } catch (\Throwable $e) {
            $msg = $e->getMessage();
            if (str_contains($msg, 'doesn\'t exist') || str_contains($msg, 'Unknown column') || str_contains($msg, 'Base table or view not found')) {
                return $this->error('分销表未就绪，请执行 sql/mysql/migrations/010_affiliate_safe.sql');
            }
            throw $e;
        }
    }
}
