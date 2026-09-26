<template>
  <div class="wallet-page">
    <header class="page-hero">
      <div class="hero-text">
        <h1>资金流水</h1>
        <p>查看用户佣金收入与订单支出，支持按用户、订单号与状态筛选</p>
      </div>
      <div class="hero-deco" aria-hidden="true"><i class="ri-wallet-3-line"></i></div>
    </header>

    <section class="stats-grid" v-if="summary">
      <div class="stat-card">
        <div class="stat-icon icon-income"><i class="ri-arrow-down-circle-line"></i></div>
        <div class="stat-info">
          <h3>累计佣金</h3>
          <p class="number">{{ fmt(summary.total_income) }} <span class="unit">{{ summary.currency_suffix }}</span></p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-spent"><i class="ri-shopping-cart-2-line"></i></div>
        <div class="stat-info">
          <h3>累计消费</h3>
          <p class="number">{{ fmt(summary.total_spent) }} <span class="unit">{{ summary.currency_suffix }}</span></p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-available"><i class="ri-hand-coin-line"></i></div>
        <div class="stat-info">
          <h3>可结算佣金</h3>
          <p class="number">{{ fmt(summary.commission_available) }} <span class="unit">{{ summary.currency_suffix }}</span></p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-pending"><i class="ri-time-line"></i></div>
        <div class="stat-info">
          <h3>待解锁佣金</h3>
          <p class="number">{{ fmt(summary.commission_pending) }} <span class="unit">{{ summary.currency_suffix }}</span></p>
        </div>
      </div>
    </section>

    <section class="filter-card">
      <div class="filter-grid">
        <label class="field">
          <span>订单号</span>
          <div class="input-wrap">
            <i class="ri-search-line"></i>
            <input v-model="keyword" type="text" placeholder="搜索订单号" @keyup.enter="reload" />
          </div>
        </label>
        <label class="field">
          <span>用户 ID</span>
          <input v-model.number="filterUserId" type="number" class="plain-input" placeholder="留空查看全部" min="0" />
        </label>
        <label class="field">
          <span>流水类型</span>
          <select v-model="filterType" class="plain-input">
            <option value="all">全部类型</option>
            <option value="commission">佣金收入</option>
            <option value="order">订单支出</option>
          </select>
        </label>
        <label class="field">
          <span>佣金状态</span>
          <select v-model="filterStatus" class="plain-input" :disabled="filterType === 'order'">
            <option value="">全部状态</option>
            <option value="pending">待解锁</option>
            <option value="available">可结算</option>
            <option value="settled">已结算</option>
          </select>
        </label>
        <div class="field field-actions">
          <button class="btn-query" type="button" @click="reload">
            <i class="ri-filter-3-line"></i> 查询
          </button>
          <button class="btn-reset" type="button" @click="resetFilters">重置</button>
        </div>
      </div>
    </section>

    <section class="table-card">
      <div class="table-toolbar">
        <h2>流水明细</h2>
        <span class="record-count" v-if="!loading">共 {{ total }} 条</span>
      </div>

      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>时间</th>
              <th>用户</th>
              <th>类型</th>
              <th>说明</th>
              <th>关联订单</th>
              <th>状态</th>
              <th class="col-amt">金额</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="7">
                <div class="state-box"><div class="spinner"></div><p>加载中…</p></div>
              </td>
            </tr>
            <tr v-else-if="!flows.length">
              <td colspan="7">
                <div class="state-box empty">
                  <i class="ri-file-list-3-line"></i>
                  <p>暂无流水记录</p>
                  <span>调整筛选条件或等待用户产生订单/佣金</span>
                </div>
              </td>
            </tr>
            <tr v-for="row in flows" :key="row.flow_id" class="data-row">
              <td class="col-time">
                <span class="time-main">{{ formatTime(row.occurred_at).split(' ')[0] }}</span>
                <span class="time-sub">{{ formatTime(row.occurred_at).split(' ').slice(1).join(' ') }}</span>
              </td>
              <td>
                <div v-if="row.user_id" class="user-cell">
                  <span class="user-avatar">{{ userInitial(row) }}</span>
                  <span>
                    <span class="user-name">{{ row.user_name || '用户' }}</span>
                    <span class="user-id">#{{ row.user_id }}</span>
                  </span>
                </div>
                <span v-else class="muted">—</span>
              </td>
              <td>
                <span class="type-badge" :class="row.category">
                  <i :class="row.category === 'commission' ? 'ri-gift-line' : 'ri-shopping-bag-line'"></i>
                  {{ categoryLabel(row) }}
                </span>
              </td>
              <td class="col-desc">{{ row.title }}</td>
              <td><code class="order-no">{{ row.order_no || '—' }}</code></td>
              <td><span class="status-pill" :class="statusClass(row)">{{ statusLabel(row) }}</span></td>
              <td class="col-amt">
                <span class="amount" :class="row.direction">
                  {{ row.signed_amount > 0 ? '+' : '' }}{{ fmt(row.signed_amount) }}
                  <small>{{ row.currency_suffix }}</small>
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <footer class="table-footer" v-if="total > limit">
        <button type="button" class="page-btn" :disabled="page <= 1" @click="goPage(page - 1)">
          <i class="ri-arrow-left-s-line"></i> 上一页
        </button>
        <span class="page-info">第 {{ page }} / {{ totalPages }} 页</span>
        <button type="button" class="page-btn" :disabled="page >= totalPages" @click="goPage(page + 1)">
          下一页 <i class="ri-arrow-right-s-line"></i>
        </button>
      </footer>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api'

const route = useRoute()
const flows = ref([])
const summary = ref(null)
const loading = ref(false)
const page = ref(1)
const limit = ref(20)
const total = ref(0)
const keyword = ref('')
const filterUserId = ref(route.query.user_id ? Number(route.query.user_id) : '')
const filterType = ref('all')
const filterStatus = ref('')

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / limit.value)))

const fmt = (n) => {
  const x = Number(n) || 0
  return x.toLocaleString('zh-TW', { minimumFractionDigits: 0, maximumFractionDigits: 2 })
}

const load = async () => {
  loading.value = true
  try {
    const params = {
      page: page.value,
      limit: limit.value,
      type: filterType.value,
      keyword: keyword.value,
    }
    if (filterUserId.value) params.user_id = filterUserId.value
    if (filterStatus.value && filterType.value !== 'order') params.status = filterStatus.value
    const res = await api.getWalletFlows(params)
    if (res.code === 0) {
      flows.value = res.data?.list ?? []
      summary.value = res.data?.summary ?? null
      total.value = res.data?.total ?? 0
    }
  } finally {
    loading.value = false
  }
}

const reload = () => {
  page.value = 1
  load()
}

const resetFilters = () => {
  keyword.value = ''
  filterUserId.value = ''
  filterType.value = 'all'
  filterStatus.value = ''
  reload()
}

const goPage = (p) => {
  page.value = p
  load()
}

const formatTime = (ts) => {
  if (!ts) return '—'
  return new Date(ts * 1000).toLocaleString('zh-TW', { hour12: false })
}

const categoryLabel = (row) => (row.category === 'commission' ? '佣金收入' : '订单支出')

const statusLabel = (row) => {
  if (row.category === 'order') {
    const m = { paid: '待发货', shipped: '已发货', completed: '已完成', cancelled: '已取消', unpaid: '待付款' }
    return m[row.status] || row.status
  }
  const m = { pending: '待解锁', available: '可结算', settled: '已结算' }
  return m[row.status] || row.status
}

const statusClass = (row) => {
  if (row.category === 'order') return `order-${row.status}`
  return `cr-${row.status}`
}

const userInitial = (row) => {
  const n = (row.user_name || 'U').trim()
  return n.charAt(0).toUpperCase()
}

onMounted(load)
</script>

<style scoped>
.wallet-page {
  padding: 2rem;
  max-width: 1600px;
  margin: 0 auto;
}

.page-hero {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.75rem 2rem;
  margin-bottom: 1.5rem;
  border-radius: var(--radius-lg);
  background: linear-gradient(135deg, var(--color-primary-dark) 0%, #2a3544 100%);
  color: #fff;
  overflow: hidden;
  box-shadow: var(--shadow-md);
}

.hero-text h1 {
  color: #fff;
  font-size: 1.65rem;
  font-weight: 600;
  margin: 0 0 0.4rem;
}

.hero-text p {
  margin: 0;
  font-size: 0.9rem;
  opacity: 0.85;
  max-width: 36rem;
  line-height: 1.5;
}

.hero-deco {
  font-size: 4.5rem;
  opacity: 0.12;
  line-height: 1;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1.25rem;
  margin-bottom: 1.5rem;
}

@media (max-width: 1100px) {
  .stats-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 560px) {
  .stats-grid { grid-template-columns: 1fr; }
}

.stat-card {
  background: var(--color-surface);
  padding: 1.25rem 1.35rem;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  display: flex;
  align-items: center;
  gap: 1rem;
  transition: transform 0.2s, box-shadow 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.stat-icon {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  flex-shrink: 0;
}

.icon-income { background: rgba(16, 185, 129, 0.12); color: #059669; }
.icon-spent { background: rgba(239, 68, 68, 0.1); color: #dc2626; }
.icon-available { background: rgba(193, 163, 102, 0.2); color: var(--color-accent); }
.icon-pending { background: rgba(245, 158, 11, 0.12); color: #d97706; }

.stat-info h3 {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--color-text-muted);
  margin: 0 0 0.35rem;
  font-family: var(--font-sans);
}

.stat-info .number {
  margin: 0;
  font-size: 1.45rem;
  font-weight: 700;
  color: var(--color-primary-dark);
  font-family: var(--font-sans);
}

.stat-info .unit {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--color-text-muted);
  margin-left: 0.15rem;
}

.filter-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.25rem 1.5rem;
  margin-bottom: 1.5rem;
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--color-border);
}

.filter-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 1rem 1.25rem;
  align-items: end;
}

@media (max-width: 1000px) {
  .filter-grid { grid-template-columns: repeat(2, 1fr); }
  .field-actions { grid-column: 1 / -1; }
}

.field span {
  display: block;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-muted);
  margin-bottom: 0.4rem;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.input-wrap {
  display: flex;
  align-items: center;
  background: var(--color-bg-main);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0 0.75rem;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.input-wrap:focus-within {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(var(--color-primary-rgb), 0.12);
}

.input-wrap i { color: #9ca3af; margin-right: 0.35rem; }

.input-wrap input {
  flex: 1;
  border: none;
  background: transparent;
  padding: 0.6rem 0;
  outline: none;
  font-size: 0.9rem;
  min-width: 0;
}

.plain-input {
  width: 100%;
  padding: 0.6rem 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-bg-main);
  font-size: 0.9rem;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.plain-input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(var(--color-primary-rgb), 0.12);
}

.plain-input:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.field-actions {
  display: flex;
  gap: 0.65rem;
  align-items: center;
}

.btn-query {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.6rem 1.25rem;
  background: var(--color-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius-md);
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
  transition: background 0.2s, transform 0.15s;
  white-space: nowrap;
}

.btn-query:hover { background: #0d9668; }

.btn-reset {
  padding: 0.6rem 1rem;
  background: transparent;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  color: var(--color-text-muted);
  cursor: pointer;
  font-size: 0.9rem;
  white-space: nowrap;
}

.btn-reset:hover {
  border-color: var(--color-primary);
  color: var(--color-primary-dark);
}

.table-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--color-border);
  overflow: hidden;
}

.table-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1.5rem;
  border-bottom: 1px solid var(--color-border);
  background: #fafafa;
}

.table-toolbar h2 {
  font-size: 1rem;
  font-weight: 600;
  margin: 0;
}

.record-count {
  font-size: 0.85rem;
  color: var(--color-text-muted);
}

.table-wrap { overflow-x: auto; }

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9rem;
}

.data-table th {
  padding: 0.85rem 1.25rem;
  text-align: left;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  background: #fafafa;
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}

.data-table td {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}

.data-row:hover td {
  background: rgba(16, 185, 129, 0.03);
}

.col-time { white-space: nowrap; }
.time-main { display: block; font-weight: 500; color: var(--color-primary-dark); }
.time-sub { display: block; font-size: 0.78rem; color: var(--color-text-muted); margin-top: 0.15rem; }

.user-cell {
  display: flex;
  align-items: center;
  gap: 0.65rem;
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-accent), #a88b4a);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 0.9rem;
  flex-shrink: 0;
}

.user-name { display: block; font-weight: 500; color: var(--color-primary-dark); }
.user-id { display: block; font-size: 0.75rem; color: var(--color-text-muted); }

.type-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.78rem;
  font-weight: 600;
  padding: 0.3rem 0.65rem;
  border-radius: 999px;
}

.type-badge.commission { background: #ecfdf5; color: #047857; }
.type-badge.order { background: #fef2f2; color: #b91c1c; }

.col-desc { color: var(--color-text-main); max-width: 200px; }

.order-no {
  font-family: ui-monospace, monospace;
  font-size: 0.8rem;
  background: #f3f4f6;
  padding: 0.2rem 0.45rem;
  border-radius: 4px;
  color: #374151;
}

.status-pill {
  display: inline-block;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.25rem 0.6rem;
  border-radius: 6px;
}

.cr-pending { background: #fef3c7; color: #b45309; }
.cr-available { background: #dbeafe; color: #1d4ed8; }
.cr-settled { background: #e5e7eb; color: #4b5563; }
.order-paid { background: #fef3c7; color: #b45309; }
.order-shipped { background: #dbeafe; color: #1d4ed8; }
.order-completed { background: #dcfce7; color: #166534; }
.order-cancelled { background: #f3f4f6; color: #6b7280; }

.col-amt { text-align: right; white-space: nowrap; }

.amount {
  font-weight: 700;
  font-size: 1rem;
  font-variant-numeric: tabular-nums;
}

.amount.in { color: #059669; }
.amount.out { color: #dc2626; }
.amount small { font-size: 0.75rem; font-weight: 500; margin-left: 0.2rem; opacity: 0.75; }

.muted { color: #9ca3af; }

.state-box {
  padding: 3rem 1.5rem;
  text-align: center;
  color: var(--color-text-muted);
}

.state-box.empty i {
  font-size: 3rem;
  opacity: 0.35;
  display: block;
  margin-bottom: 0.75rem;
}

.state-box.empty p {
  margin: 0 0 0.35rem;
  font-size: 1rem;
  color: var(--color-primary-dark);
  font-weight: 500;
}

.state-box.empty span { font-size: 0.85rem; }

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #e5e7eb;
  border-top-color: var(--color-primary);
  border-radius: 50%;
  margin: 0 auto 0.75rem;
  animation: spin 0.7s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.table-footer {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1.25rem;
  padding: 1rem 1.5rem;
  border-top: 1px solid var(--color-border);
  background: #fafafa;
}

.page-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.5rem 1rem;
  border: 1px solid var(--color-border);
  background: #fff;
  border-radius: var(--radius-md);
  cursor: pointer;
  font-size: 0.88rem;
  color: var(--color-primary-dark);
  transition: border-color 0.2s, background 0.2s;
}

.page-btn:hover:not(:disabled) {
  border-color: var(--color-primary);
  background: rgba(16, 185, 129, 0.06);
}

.page-btn:disabled { opacity: 0.45; cursor: not-allowed; }

.page-info {
  font-size: 0.88rem;
  color: var(--color-text-muted);
  min-width: 6rem;
  text-align: center;
}
</style>
