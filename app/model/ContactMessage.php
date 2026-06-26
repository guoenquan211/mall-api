<?php
declare(strict_types=1);

namespace app\model;

class ContactMessage extends BaseModel
{
    protected $table = 'contact_messages';

    protected $autoWriteTimestamp = true;
}
