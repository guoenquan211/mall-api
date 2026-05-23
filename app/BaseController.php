<?php
declare (strict_types = 1);

namespace app;

use think\App;
use think\exception\ValidateException;
use think\Validate;

/**
 * Controler Base Class
 */
abstract class BaseController
{
    /**
     * Request Instance
     * @var \think\Request
     */
    protected $request;

    /**
     * App Instance
     * @var \think\App
     */
    protected $app;

    /**
     * Whether to check login
     * @var bool
     */
    protected $needLogin = false;

    /**
     * Whether validate() enables batch mode when the $batch argument is false.
     * Child controllers may override; Upload and others rely on this default.
     *
     * @var bool
     */
    protected $batchValidate = false;

    /**
     * Constructor
     * @param App $app
     */
    public function __construct(App $app)
    {
        $this->app     = $app;
        $this->request = $this->app->request;

        // Control initialization
        $this->initialize();
    }

    // Initialization
    protected function initialize()
    {}

    /**
     * Validate data
     * @param array        $data     Data to validate
     * @param string|array $validate Validator class or rules
     * @param array        $message  Error messages
     * @param bool         $batch    Batch validation
     * @return array|string|true
     * @throws ValidateException
     */
    protected function validate(array $data, $validate, array $message = [], bool $batch = false)
    {
        if (is_array($validate)) {
            $v = new Validate();
            $v->rule($validate);
        } else {
            if (strpos($validate, '.')) {
                // Support scene validation
                [$validate, $scene] = explode('.', $validate);
            }
            $class = false !== strpos($validate, '\\') ? $validate : $this->app->parseClass('validate', $validate);
            $v     = new $class();
            if (!empty($scene)) {
                $v->scene($scene);
            }
        }

        $v->message($message);

        // Batch validation
        if ($batch || $this->batchValidate) {
            $v->batch(true);
        }

        return $v->failException(true)->check($data);
    }

    /**
     * Return JSON response
     * @param int $code
     * @param string $msg
     * @param mixed $data
     * @return \think\response\Json
     */
    protected function success($data = [], $msg = 'success')
    {
        return json(['code' => 0, 'msg' => $msg, 'data' => $data]);
    }

    protected function error($msg = 'error', $code = -1)
    {
        return json(['code' => $code, 'msg' => $msg]);
    }

    /**
     * Record Admin Log
     * @param string $action
     * @param string $target
     * @param string $detail
     * @param int|null $adminId Optional admin ID override
     */
    protected function log($action, $target, $detail = '', $adminId = null)
    {
        try {
            // Get admin_id from header or default to 1 if not provided
            if (!$adminId) {
                $adminId = $this->request->header('X-Admin-Id', '1');
            }
            
            \app\model\AdminLog::create([
                'admin_id' => $adminId,
                'action' => $action,
                'target' => $target,
                'detail' => $detail,
                'ip' => $this->request->ip()
            ]);
        } catch (\Exception $e) {
            // Ignore logging errors
        }
    }
}
