<template>
  <div class="dashboard-container">
    <div class="welcome-banner">
      <div class="welcome-text">
        <h1>早安，管理员</h1>
        <p>今天是 {{ currentDate }}，系统运行正常。</p>
      </div>
      <div class="welcome-decoration">
        <i class="ri-plant-line"></i>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon icon-users">
          <i class="ri-user-star-line"></i>
        </div>
        <div class="stat-info">
          <h3>注册用户</h3>
          <p class="number">{{ stats.users }}</p>
          <span class="trend positive"><i class="ri-arrow-up-line"></i> 本周新增 5</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-products">
          <i class="ri-store-2-line"></i>
        </div>
        <div class="stat-info">
          <h3>商品总数</h3>
          <p class="number">{{ stats.products }}</p>
          <span class="trend positive"><i class="ri-arrow-up-line"></i> 本周新增 2</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-news">
          <i class="ri-newspaper-line"></i>
        </div>
        <div class="stat-info">
          <h3>资讯文章</h3>
          <p class="number">{{ stats.news }}</p>
          <span class="trend neutral"><i class="ri-subtract-line"></i> 无变化</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon icon-knowledge">
          <i class="ri-book-open-line"></i>
        </div>
        <div class="stat-info">
          <h3>科普知识</h3>
          <p class="number">{{ stats.knowledge }}</p>
          <span class="trend positive"><i class="ri-arrow-up-line"></i> 本周新增 1</span>
        </div>
      </div>
    </div>

    <div class="charts-grid">
      <div class="chart-card">
        <h3>访问来源</h3>
        <div ref="pieChartRef" class="chart-container"></div>
      </div>
      <div class="chart-card">
        <h3>流量趋势</h3>
        <div ref="lineChartRef" class="chart-container"></div>
      </div>
    </div>

    <div class="dashboard-sections">
      <div class="section-card quick-actions">
        <h2><i class="ri-flashlight-line"></i> 快捷操作</h2>
        <div class="action-buttons">
          <button class="action-btn" @click="$router.push('/products')">
            <div class="btn-icon"><i class="ri-add-circle-line"></i></div>
            <span>发布商品</span>
          </button>
          <button class="action-btn" @click="$router.push('/content')">
            <div class="btn-icon"><i class="ri-edit-box-line"></i></div>
            <span>发布资讯</span>
          </button>
          <button class="action-btn">
            <div class="btn-icon"><i class="ri-settings-3-line"></i></div>
            <span>系统设置</span>
          </button>
        </div>
      </div>

      <div class="section-card system-status">
        <h2><i class="ri-server-line"></i> 系统状态</h2>
        <ul class="status-list">
          <li class="status-item">
            <span class="label">API 服务</span>
            <span class="value status-ok">运行中</span>
          </li>
          <li class="status-item">
            <span class="label">数据库</span>
            <span class="value status-ok">已连接</span>
          </li>
          <li class="status-item">
            <span class="label">上次备份</span>
            <span class="value">2024-03-15 02:00</span>
          </li>
          <li class="status-item">
            <span class="label">存储空间</span>
            <div class="progress-bar">
              <div class="progress-fill" style="width: 25%"></div>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { api } from '../api'
import * as echarts from 'echarts'

const currentDate = computed(() => {
  return new Date().toLocaleDateString('zh-CN', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric', 
    weekday: 'long' 
  })
})

const stats = ref({
  users: 0,
  products: 0,
  news: 0,
  knowledge: 0
})

const pieChartRef = ref(null)
const lineChartRef = ref(null)
let pieChart = null
let lineChart = null

const initCharts = async () => {
  // Pie Chart
  if (pieChartRef.value) {
    pieChart = echarts.init(pieChartRef.value)
    const trafficStats = await api.getTrafficStats()
    
    pieChart.setOption({
      tooltip: {
        trigger: 'item'
      },
      legend: {
        bottom: '5%',
        left: 'center'
      },
      series: [
        {
          name: '访问来源',
          type: 'pie',
          radius: ['40%', '70%'],
          avoidLabelOverlap: false,
          itemStyle: {
            borderRadius: 10,
            borderColor: '#fff',
            borderWidth: 2
          },
          label: {
            show: false,
            position: 'center'
          },
          emphasis: {
            label: {
              show: true,
              fontSize: 20,
              fontWeight: 'bold'
            }
          },
          labelLine: {
            show: false
          },
          data: trafficStats.data
        }
      ]
    })
  }

  // Line Chart
  if (lineChartRef.value) {
    lineChart = echarts.init(lineChartRef.value)
    const trends = await api.getTrafficTrends()
    
    lineChart.setOption({
      tooltip: {
        trigger: 'axis'
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        boundaryGap: false,
        data: trends.data.map(item => item.date)
      },
      yAxis: {
        type: 'value'
      },
      series: [
        {
          name: '访问量',
          type: 'line',
          smooth: true,
          itemStyle: {
            color: '#6c5ce7'
          },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(108, 92, 231, 0.5)' },
              { offset: 1, color: 'rgba(108, 92, 231, 0.1)' }
            ])
          },
          data: trends.data.map(item => item.value)
        }
      ]
    })
  }
}

const handleResize = () => {
  pieChart && pieChart.resize()
  lineChart && lineChart.resize()
}

onMounted(async () => {
  const res = await api.getStats()
  if (res.code === 0) {
    stats.value = res.data
  }
  await initCharts()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  pieChart && pieChart.dispose()
  lineChart && lineChart.dispose()
})
</script>

<style scoped>
.dashboard-container {
  padding: 2rem;
  max-width: 1600px;
  margin: 0 auto;
}

.icon-users { background: rgba(59, 130, 246, 0.1); color: #3b82f6; }
.icon-orders { background: rgba(16, 185, 129, 0.1); color: #10b981; }

.traffic-source {
  flex: 1;
  min-width: 300px;
}

.traffic-item {
  margin-bottom: 1rem;
}

.traffic-label {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  color: var(--color-text-primary);
}

.traffic-value {
  font-weight: 500;
}

.traffic-bar-bg {
  height: 8px;
  background: #f3f4f6;
  border-radius: 4px;
  overflow: hidden;
}

.traffic-bar-fill {
  height: 100%;
  background: var(--color-accent);
  border-radius: 4px;
  transition: width 1s ease-out;
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
  opacity: 0.8;
  margin: 0;
  font-family: var(--font-sans);
}

.welcome-decoration {
  font-size: 8rem;
  opacity: 0.1;
  position: absolute;
  right: -20px;
  bottom: -40px;
  transform: rotate(-15deg);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.chart-card {
  background: white;
  padding: 1.5rem;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.chart-card:hover {
  transform: translateY(-5px);
  box-shadow: var(--shadow-md);
}

.chart-card h3 {
  margin: 0 0 1.5rem 0;
  font-size: 1.1rem;
  color: var(--color-text-primary);
  font-weight: 600;
}

.chart-container {
  height: 300px;
  width: 100%;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  display: flex;
  align-items: center;
  gap: 1.5rem;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-5px);
  box-shadow: var(--shadow-md);
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.8rem;
}

.icon-products {
  background: rgba(193, 163, 102, 0.15);
  color: var(--color-accent);
}

.icon-news {
  background: rgba(61, 90, 75, 0.15);
  color: var(--color-secondary);
}

.icon-knowledge {
  background: rgba(52, 152, 219, 0.15);
  color: #3498db;
}

.stat-info h3 {
  font-size: 0.9rem;
  color: var(--color-text-muted);
  margin-bottom: 0.2rem;
  font-family: var(--font-sans);
  font-weight: 500;
}

.number {
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--color-primary-dark);
  margin: 0 0 0.5rem 0;
  font-family: var(--font-sans);
}

.trend {
  font-size: 0.8rem;
  display: flex;
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

.section-card {
  background: white;
  padding: 1.5rem;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.section-card h2 {
  font-size: 1.2rem;
  margin-bottom: 1.5rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border-bottom: 1px solid var(--color-border);
  padding-bottom: 1rem;
}

.section-card h2 i {
  color: var(--color-accent);
}

/* Quick Actions */
.action-buttons {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 1rem;
}

.action-btn {
  background: var(--color-bg-main);
  border: 1px solid transparent;
  padding: 1.5rem 1rem;
  border-radius: var(--radius-md);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.8rem;
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
  font-size: 1.5rem;
  color: var(--color-primary-dark);
}

.action-btn span {
  font-size: 0.9rem;
  color: var(--color-text-main);
}

/* System Status */
.status-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.8rem 0;
  border-bottom: 1px solid var(--color-border);
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

.progress-bar {
  width: 100px;
  height: 6px;
  background: #eee;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: var(--color-accent);
}
</style>
