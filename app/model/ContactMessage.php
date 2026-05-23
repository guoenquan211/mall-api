<?php
declare(strict_types=1);

namespace app\model;

use think\Model;

class ContactMessage extends Model
{
    protected $table = 'contact_messages';

    protected $autoWriteTimestamp = true;
}
