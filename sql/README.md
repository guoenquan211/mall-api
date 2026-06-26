# 数据库 SQL（MySQL）

## 新建库

1. 宝塔创建 MySQL 数据库
2. 导入 **`mysql/schema_full.sql`**
3. 导入 **`mysql/seed_all.sql`**（全站演示数据，含商品/资讯/会员/订单）
4. 配置项目根目录 **`.env`**：

```ini
[DATABASE]
HOSTNAME = 127.0.0.1
DATABASE = cocobrite
USERNAME = cocobrite
PASSWORD = 你的密码
HOSTPORT = 3306
CHARSET = utf8mb4
PREFIX =
```

5. 删除 `runtime/cache/*`
6. 访问 `/tp-check.php` 确认 `"ok": true`

## 老库升级

按顺序执行 **`mysql/migrations/`** 里尚未跑过的脚本（001 → 008）。  
**新库不要跑 migrations**，只导 `schema_full.sql`。

## 文件说明

| 文件 | 用途 |
|------|------|
| `mysql/schema_full.sql` | 完整表结构（必导） |
| `mysql/seed_all.sql` | 全站演示数据（推荐） |
| `mysql/seed_admin.sql` | 仅创建管理员（可选） |
| `mysql/seed_demo.sql` | 旧版精简演示（已被 seed_all 替代） |
| `mysql/migrations/` | 老库增量升级 |
| `archive/` | 历史文件，勿用 |
