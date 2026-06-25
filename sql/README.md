# CocoBrite 数据库 SQL 说明

根目录原先散落的 `database*.sql`、`database_migration_*.sql` 已归集到本目录。**以后只看这里。**

## 快速选择（看这一张表就够）

| 场景 | 用什么 | 在哪执行 |
|------|--------|----------|
| **宝塔 / 生产：新建 MySQL 库** | `mysql/schema_full.sql` + 可选 `mysql/seed_demo.sql` | 宝塔 → 数据库 → 导入 |
| **本地：新建 SQLite** | `sqlite/schema_full.sql` + 可选 `sqlite/seed_demo.sql` | `sqlite3 database.sqlite < sql/sqlite/schema_full.sql` |
| **老库升级（已有数据）** | 按编号执行 `mysql/migrations/` 或 `sqlite/migrations/` 里**还没跑过**的脚本 | 逐条导入，遇「列已存在」可跳过 |
| **只重灌商品/资讯演示数据** | `mysql/seed_demo.sql` 或 `sqlite/seed_demo.sql` | **会先删订单和商品**，执行前备份 |
| **GCash / 提现（SQLite 本地）** | `php scripts/apply_gcash_sqlite.php` | 会自动读 `sqlite/migrations/008_gcash.sql` |

## 目录结构

```
sql/
├── README.md                 ← 本说明
├── mysql/
│   ├── schema_full.sql       ← 【新库】完整表结构（MySQL，含分销+GCash+双语）
│   ├── seed_demo.sql         ← 【可选】演示数据（会清空商品/订单相关表）
│   └── migrations/           ← 【老库升级】按 001→008 顺序执行
└── sqlite/
    ├── schema_full.sql       ← 【新库】完整表结构（SQLite）
    ├── seed_demo.sql         ← 【可选】演示数据
    └── migrations/           ← 【老库升级】按 001→008 顺序执行
```

## 迁移脚本顺序（老库升级时用）

| 编号 | 内容 | 新库还要跑吗 |
|------|------|-------------|
| 001 | 商品分类表 `product_categories` | 否（已在 schema_full） |
| 002 | 首页主推 `products.show_on_home` | 否 |
| 003 | 用户语系 `users.locale` | 否 |
| 004 | 联络留言 `contact_messages` | 否 |
| 005 | 双语字段 `*_en` | 否 |
| 006 | 资讯图标长度 `news.icon` → 512 | 否 |
| 007 | 分销/邀请 `affiliate_*` | 否 |
| 008 | GCash 收款/提现 | 否 |

> **新库只需执行 `schema_full.sql` 一次**，不要再跑 migrations。

## 废弃文件（勿用）

以下文件是历史副本或旧版，已移到 `sql/archive/`，**不要导入**：

- `database_1.sql` / `database_sqlite_1.sql` — 旧版全量，缺双语或缺 GCash
- 根目录旧的 `database.sql` 等 — 已由 `sql/mysql/schema_full.sql` 替代

## 宝塔 MySQL 部署步骤

1. 宝塔 → 数据库 → 创建库（如 `cocobrite`）
2. 导入 `sql/mysql/schema_full.sql`
3. （可选）导入 `sql/mysql/seed_demo.sql` 写入演示商品
4. 在 `mall-api/.env` 配置 `DATABASE`、`USERNAME`、`PASSWORD` 等
5. 修改 `admin_users` 里 admin 密码（演示 hash 不可用）

## 本地 SQLite 步骤

```bash
cd mall-api
sqlite3 database.sqlite < sql/sqlite/schema_full.sql
sqlite3 database.sqlite < sql/sqlite/seed_demo.sql   # 可选
php scripts/apply_gcash_sqlite.php                   # schema_full 已含 GCash 时可跳过
```
