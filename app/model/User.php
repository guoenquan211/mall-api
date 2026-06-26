<?php
namespace app\model;

class User extends BaseModel
{
    protected $table = 'users';
    protected $autoWriteTimestamp = true;

    protected $hidden = ['password'];
}
