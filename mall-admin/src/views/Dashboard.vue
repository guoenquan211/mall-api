<template>
  <div class="dashboard-container">
    <div class="welcome-banner">
      <div class="welcome-text">
        <h1>{{ welcomeTitle }}</h1>
        <p>{{ dateLine }}</p>
      </div>
      <div class="welcome-decoration">
        <i class="ri-dashboard-3-line"></i>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon icon-users">
          <i class="ri-user-star-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiUsers') }}</h3>
          <p class="number">{{ stats.users }}</p>
          <span class="trend" :class="usersWeekTrendClass">
            <i :class="usersWeekIcon"></i>
            {{ usersWeekTrendText }}
          </span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-products">
          <i class="ri-store-2-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiProducts') }}</h3>
          <p class="number">{{ stats.products }}</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-orders">
          <i class="ri-shopping-bag-3-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiOrders') }}</h3>
          <p class="number">{{ stats.orders }}</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-revenue">
          <i class="ri-money-cny-circle-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiRevenueTotal') }}</h3>
          <p class="number"><span class="cur">{{ $t('admin.dashboard.currency') }}</span>{{ formatMoney(sales.revenue_total) }}</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-month">
          <i class="ri-calendar-check-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiRevenueMonth') }}</h3>
          <p class="number"><span class="cur">{{ $t('admin.dashboard.currency') }}</span>{{ formatMoney(sales.revenue_month) }}</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-today">
          <i class="ri-sun-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiRevenueToday') }}</h3>
          <p class="number"><span class="cur">{{ $t('admin.dashboard.currency') }}</span>{{ formatMoney(sales.revenue_today) }}</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-aov">
          <i class="ri-price-tag-3-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiAov') }}</h3>
          <p class="number"><span class="cur">{{ $t('admin.dashboard.currency') }}</span>{{ formatMoney(sales.avg_order_value) }}</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-fulfill">
          <i class="ri-truck-line"></i>
        </div>
        <div class="stat-info">
          <h3>{{ $t('admin.dashboard.kpiToFulfill') }}</h3>
          <p class="number">{{ toFulfill }}</p>
          <span class="trend neutral">{{ $t('admin.dashboard.kpiToFulfillHint') }}</span>
        </div>
      </div>
    </div>

    <div class="sub-kpi-row">
      <div class="sub-kpi">
        <span class="label">{{ $t('admin.dashboard.kpiNews') }}</span>
        <strong>{{ stats.news }}</strong>
      </div>
      <div class="sub-kpi">
        <span class="label">{{ $t('admin.dashboard.kpiKnowledge') }}</span>
        <strong>{{ stats.knowledge }}</strong>
      </div>
      <div class="sub-kpi">
        <span class="label">{{ $t('admin.dashboard.kpiRevenueWeek') }}</span>
        <strong><span class="cur">{{ $t('admin.dashboard.currency') }}</span>{{ formatMoney(sales.revenue_week) }}</strong>
      </div>
      <div class="sub-kpi">
        <span class="label">{{ $t('admin.dashboard.statusPending') }}</span>
        <strong>{{ sales.orders_pending_pay }}</strong>
      </div>
      <div class="sub-kpi">
        <span class="label">{{ $t('admin.dashboard.statusDone') }}</span>
        <strong>{{ sales.orders_completed }}</strong>
      </div>
      <div class="sub-kpi">
        <span class="label">{{ $t('admin.dashboard.statusCancelled') }}</span>
        <strong>{{ sales.orders_cancelled }}</strong>
      </div>
    </div>

    <div class="charts-grid">
      <div class="chart-card">
        <h3>{{ $t('admin.dashboard.chartCategory') }}</h3>
        <p class="chart-hint">{{ $t('admin.dashboard.chartCategoryHint') }}</p>
        <div ref="pieChartRef" class="chart-container"></div>
      </div>
      <div class="chart-card chart-wide">
        <h3>{{ $t('admin.dashboard.chartTrends') }}</h3>
        <p class="chart-hint">{{ $t('admin.dashboard.chartTrendsHint') }}</p>
        <div ref="lineChartRef" class="chart-container chart-tall"></div>
      </div>
      <div class="chart-card">
        <h3>{{ $t('admin.dashboard.chartFunnel') }}</h3>
        <div ref="barChartRef" class="chart-container"></div>
      </div>
    </div>

    <div class="dashboard-sections">
      <div class="section-card quick-actions">
        <h2><i class="ri-flashlight-line"></i> {{ $t('admin.dashboard.quickTitle') }}</h2>
        <div class="action-buttons">
          <button type="button" class="action-btn" @click="$router.push('/products')">
            <div class="btn-icon"><i class="ri-store-2-line"></i></div>
            <span>{{ $t('admin.dashboard.qaProduct') }}</span>
          </button>
          <button type="button" class="action-btn" @click="$router.push('/content')">
            <div class="btn-icon"><i class="ri-article-line"></i></div>
            <span>{{ $t('admin.dashboard.qaContent') }}</span>
          </button>
          <button type="button" class="action-btn" @click="$router.push('/orders')">
            <div class="btn-icon"><i class="ri-list-check"></i></div>
            <span>{{ $t('admin.dashboard.qaOrders') }}</span>
          </button>
        </div>
      </div>

      <div class="section-card system-status">
        <h2><i class="ri-server-line"></i> {{ $t('admin.dashboard.sysTitle') }}</h2>
        <ul class="status-list">
          <li class="status-item">
            <span class="label">{{ $t('admin.dashboard.sysApi') }}</span>
            <span class="value status-ok">{{ $t('admin.dashboard.sysRunning') }}</span>
          </li>
          <li class="status-item">
            <span class="label">{{ $t('admin.dashboard.sysDb') }}</span>
            <span class="value status-ok">{{ $t('admin.dashboard.sysConnected') }}</span>
          </li>
          <li class="status-item">
            <span class="label">{{ $t('admin.dashboard.sysBackup') }}</span>
            <span class="value">{{ $t('admin.dashboard.sysBackupHint') }}</span>
          </li>
          <li class="status-item">
            <span class="label">{{ $t('admin.dashboard.sysStorage') }}</span>
            <div class="progress-wrap">
              <div class="progress-bar">
                <div class="progress-fill" style="width: 28%"></div>
              </div>
              <span class="hint">{{ $t('admin.dashboard.sysStorageHint') }}</span>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted, nextTick, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { api } from '../api'
import * as echarts from 'echarts'

const { t, locale } = useI18n()

const emptySales = () => ({
  revenue_total: 0,
  revenue_today: 0,
  revenue_week: 0,
  revenue_month: 0,
  orders_pending_pay: 0,
  orders_to_ship: 0,
  orders_shipped: 0,
  orders_completed: 0,
  orders_cancelled: 0,
  avg_order_value: 0,
  users_week: 0,
})

const stats = ref({
  users: 0,
  products: 0,
  orders: 0,
  news: 0,
  knowledge: 0,
  sales: emptySales(),
})

const sales = computed(() => stats.value.sales || emptySales())
const toFulfill = computed(() => (sales.value.orders_to_ship || 0) + (sales.value.orders_shipped || 0))

const adminName = computed(() => {
  try {
    const u = JSON.parse(localStorage.getItem('admin_user') || '{}')
    return u.nickname || u.username || ''
  } catch {
    return ''
  }
})

const welcomeTitle = computed(() => {
  const n = adminName.value
  if (n) return t('admin.dashboard.welcome', { name: n })
  return t('admin.dashboard.welcomeFallback')
})

const currentDateStr = computed(() => {
  const loc = locale.value === 'en' ? 'en-US' : 'zh-TW'
  return new Date().toLocaleDateString(loc, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    weekday: 'long',
  })
})

const dateLine = computed(() =>
  t('admin.dashboard.dateLine', {
    date: currentDateStr.value,
    status: t('admin.dashboard.systemOk'),
  }),
)

const usersWeekTrendText = computed(() => {
  const n = sales.value.users_week || 0
  if (n > 0) return t('admin.dashboard.trendWeek', { n })
  return t('admin.dashboard.trendNone')
})

const usersWeekTrendClass = computed(() => {
  const n = sales.value.users_week || 0
  if (n > 0) return 'trend positive'
  return 'trend neutral'
})

const usersWeekIcon = computed(() => ((sales.value.users_week || 0) > 0 ? 'ri-arrow-up-line' : 'ri-subtract-line'))

function formatMoney(n) {
  const x = Number(n) || 0
  return x.toLocaleString(locale.value === 'en' ? 'en-US' : 'zh-TW', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })
}

const pieChartRef = ref(null)
const lineChartRef = ref(null)
const barChartRef = ref(null)
let pieChart = null
let lineChart = null
let barChart = null

const initCharts = async () => {
  const trafficRes = await api.getTrafficStats()
  const pieData =
    trafficRes.code === 0 && Array.isArray(trafficRes.data) ? trafficRes.data : []

  if (pieChartRef.value) {
    if (pieChart) pieChart.dispose()
    pieChart = echarts.init(pieChartRef.value)
    pieChart.setOption({
      tooltip: { trigger: 'item', valueFormatter: (v) => String(v) },
      legend: { bottom: '0%', left: 'center' },
      series: [
        {
          type: 'pie',
          radius: ['38%', '68%'],
          avoidLabelOverlap: true,
          itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 },
          label: { show: true, formatter: '{b}\n{d}%' },
          data: pieData,
        },
      ],
    })
  }

  const trendsRes = await api.getTrafficTrends()
  const trendRows =
    trendsRes.code === 0 && Array.isArray(trendsRes.data) ? trendsRes.data : []

  if (lineChartRef.value) {
    if (lineChart) lineChart.dispose()
    lineChart = echarts.init(lineChartRef.value)
    const dates = trendRows.map((item) => item.date)
    lineChart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { data: [t('admin.dashboard.seriesRevenue'), t('admin.dashboard.seriesOrders'), t('admin.dashboard.seriesActivity')], bottom: 0 },
      grid: { left: '3%', right: '4%', bottom: '14%', top: '12%', containLabel: true },
      xAxis: { type: 'category', boundaryGap: false, data: dates },
      yAxis: [
        {
          type: 'value',
          name: t('admin.dashboard.seriesRevenue'),
          splitLine: { lineStyle: { type: 'dashed', opacity: 0.35 } },
        },
        {
          type: 'value',
          name: t('admin.dashboard.seriesOrders'),
          splitLine: { show: false },
        },
      ],
      series: [
        {
          name: t('admin.dashboard.seriesRevenue'),
          type: 'line',
          smooth: true,
          yAxisIndex: 0,
          itemStyle: { color: '#c9a5a0' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(201, 165, 160, 0.45)' },
              { offset: 1, color: 'rgba(201, 165, 160, 0.05)' },
            ]),
          },
          data: trendRows.map((item) => item.revenue ?? 0),
        },
        {
          name: t('admin.dashboard.seriesOrders'),
          type: 'bar',
          yAxisIndex: 1,
          itemStyle: { color: '#3d5a4b', borderRadius: [4, 4, 0, 0] },
          data: trendRows.map((item) => item.orders ?? 0),
        },
        {
          name: t('admin.dashboard.seriesActivity'),
          type: 'line',
          smooth: true,
          yAxisIndex: 1,
          itemStyle: { color: '#94a3b8' },
          data: trendRows.map((item) => item.activity ?? 0),
        },
      ],
    })
  }

  if (barChartRef.value) {
    if (barChart) barChart.dispose()
    barChart = echarts.init(barChartRef.value)
    const s = sales.value
    const labels = [
      t('admin.dashboard.statusPending'),
      t('admin.dashboard.statusPaid'),
      t('admin.dashboard.statusShipped'),
      t('admin.dashboard.statusDone'),
      t('admin.dashboard.statusCancelled'),
    ]
    const values = [
      s.orders_pending_pay,
      s.orders_to_ship,
      s.orders_shipped,
      s.orders_completed,
      s.orders_cancelled,
    ]
    barChart.setOption({
      tooltip: { trigger: 'axis' },
      grid: { left: '3%', right: '4%', bottom: '3%', top: '10%', containLabel: true },
      xAxis: { type: 'category', data: labels, axisLabel: { interval: 0, rotate: 22, fontSize: 11 } },
      yAxis: { type: 'value', minInterval: 1 },
      series: [
        {
          type: 'bar',
          data: values,
          itemStyle: {
            color: (params) => {
              const colors = ['#f59e0b', '#3b82f6', '#8b5cf6', '#10b981', '#ef4444']
              return colors[params.dataIndex] || '#94a3b8'
            },
            borderRadius: [6, 6, 0, 0],
          },
        },
      ],
    })
  }
}

const handleResize = () => {
  pieChart && pieChart.resize()
  lineChart && lineChart.resize()
  barChart && barChart.resize()
}

onMounted(async () => {
  const res = await api.getStats()
  if (res.code === 0 && res.data) {
    stats.value = {
      users: res.data.users ?? 0,
      products: res.data.products ?? 0,
      orders: res.data.orders ?? 0,
      news: res.data.news ?? 0,
      knowledge: res.data.knowledge ?? 0,
      sales: { ...emptySales(), ...(res.data.sales || {}) },
    }
  }
  await nextTick()
  await initCharts()
  window.addEventListener('resize', handleResize)
})

watch(locale, async () => {
  await nextTick()
  await initCharts()
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  pieChart && pieChart.dispose()
  lineChart && lineChart.dispose()
  barChart && barChart.dispose()
})
</script>

<style scoped>
.dashboard-container {
  padding: 2rem;
  max-width: 1600px;
  margin: 0 auto;
}

.welcome-banner {
  background: linear-gradient(135deg, var(--color-primary-dark) 0%, #2c3e50 100%);
  color: white;
  padding: 2.5rem;
  border-radius: var(--radius-lg);
  margin-bottom: 2rem;
  position: relative;
  overflow: hidden;
  box-shadow: var(--shadow-md);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.welcome-text h1 {
  color: white;
  font-size: 2rem;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.welcome-text p {
  opacity: 0.88;
  margin: 0;
  font-family: var(--font-sans);
  max-width: 42rem;
  line-height: 1.5;
}

.welcome-decoration {
  font-size: 6rem;
  opacity: 0.12;
  position: absolute;
  right: 1rem;
  bottom: -1rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1.25rem;
  margin-bottom: 1.25rem;
}

.sub-kpi-row {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 0.75rem;
  margin-bottom: 2rem;
}

.sub-kpi {
  background: #fafafa;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.75rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.sub-kpi .label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.sub-kpi strong {
  font-size: 1.1rem;
  color: var(--color-text-primary);
}

.charts-grid {
  display: grid;
  grid-template-columns: 1fr 1.4fr 1fr;
  gap: 1.5rem;
  margin-bottom: 2rem;
}

@media (max-width: 1200px) {
  .charts-grid {
    grid-template-columns: 1fr;
  }
}

.chart-card {
  background: white;
  padding: 1.5rem;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  transition:
    transform 0.3s ease,
    box-shadow 0.3s ease;
}

.chart-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-md);
}

.chart-card h3 {
  margin: 0 0 0.35rem 0;
  font-size: 1.05rem;
  color: var(--color-text-primary);
  font-weight: 600;
}

.chart-hint {
  margin: 0 0 1rem 0;
  font-size: 0.78rem;
  color: var(--color-text-muted);
  line-height: 1.4;
}

.chart-container {
  height: 280px;
  width: 100%;
}

.chart-tall {
  height: 320px;
}

.stat-card {
  background: white;
  padding: 1.35rem;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  display: flex;
  align-items: center;
  gap: 1.25rem;
  transition:
    transform 0.3s ease,
    box-shadow 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-md);
}

.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.65rem;
  flex-shrink: 0;
}

.icon-users {
  background: rgba(59, 130, 246, 0.1);
  color: #3b82f6;
}
.icon-products {
  background: rgba(193, 163, 102, 0.15);
  color: var(--color-accent);
}
.icon-orders {
  background: rgba(16, 185, 129, 0.12);
  color: #10b981;
}
.icon-revenue {
  background: rgba(201, 165, 160, 0.2);
  color: #a67c7c;
}
.icon-month {
  background: rgba(139, 92, 246, 0.12);
  color: #8b5cf6;
}
.icon-today {
  background: rgba(245, 158, 11, 0.15);
  color: #d97706;
}
.icon-aov {
  background: rgba(61, 90, 75, 0.15);
  color: var(--color-secondary);
}
.icon-fulfill {
  background: rgba(14, 165, 233, 0.12);
  color: #0284c7;
}

.stat-info h3 {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  margin-bottom: 0.15rem;
  font-weight: 500;
}

.number {
  font-size: 1.55rem;
  font-weight: 700;
  color: var(--color-primary-dark);
  margin: 0 0 0.35rem 0;
}

.cur {
  font-size: 0.95rem;
  font-weight: 600;
  margin-right: 2px;
  color: var(--color-text-muted);
}

.trend {
  font-size: 0.78rem;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.trend.positive {
  color: var(--color-secondary);
}

.trend.neutral {
  color: var(--color-text-muted);
}

.dashboard-sections {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 1.5rem;
}

@media (max-width: 900px) {
  .dashboard-sections {
    grid-template-columns: 1fr;
  }
}

.section-card {
  background: white;
  padding: 1.5rem;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.section-card h2 {
  font-size: 1.15rem;
  margin-bottom: 1.25rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border-bottom: 1px solid var(--color-border);
  padding-bottom: 1rem;
}

.section-card h2 i {
  color: var(--color-accent);
}

.action-buttons {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 1rem;
}

.action-btn {
  background: var(--color-bg-main);
  border: 1px solid transparent;
  padding: 1.35rem 1rem;
  border-radius: var(--radius-md);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.65rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.action-btn:hover {
  background: white;
  border-color: var(--color-accent);
  box-shadow: var(--shadow-sm);
  transform: translateY(-2px);
}

.btn-icon {
  font-size: 1.45rem;
  color: var(--color-primary-dark);
}

.status-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--color-border);
  gap: 1rem;
}

.status-item:last-child {
  border-bottom: none;
}

.status-item .label {
  color: var(--color-text-muted);
  font-size: 0.9rem;
}

.status-item .value {
  font-weight: 500;
  font-size: 0.9rem;
}

.status-ok {
  color: var(--color-secondary);
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-ok::before {
  content: '';
  width: 8px;
  height: 8px;
  background: var(--color-secondary);
  border-radius: 50%;
}

.progress-wrap {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.35rem;
  min-width: 120px;
}

.progress-bar {
  width: 120px;
  height: 6px;
  background: #eee;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: var(--color-accent);
}

.hint {
  font-size: 0.72rem;
  color: var(--color-text-muted);
}
</style>
