<?php
use think\facade\Env;

return [
    'default'         => 'mysql',

    'time_query_rule' => [],

    'auto_timestamp'  => true,

    'datetime_format' => 'Y-m-d H:i:s',

    'connections'     => [
        'mysql' => [
            'type'            => 'mysql',
            'hostname'        => Env::get('database.hostname', '127.0.0.1'),
            'database'        => Env::get('database.database', 'cocobrite'),
            'username'        => Env::get('database.username', 'root'),
            'password'        => Env::get('database.password', ''),
            'hostport'        => Env::get('database.hostport', '3306'),
            'params'          => [],
            'charset'         => Env::get('database.charset', 'utf8mb4'),
            'prefix'          => Env::get('database.prefix', ''),
            'deploy'          => 0,
            'rw_separate'     => false,
            'master_num'      => 1,
            'slave_no'        => '',
            'fields_strict'   => true,
            'break_reconnect' => false,
            'trigger_sql'     => Env::get('app_debug', true),
            'fields_cache'    => false,
        ],
    ],
];
