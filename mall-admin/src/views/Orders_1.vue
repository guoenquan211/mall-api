<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">订单管理</h1>
      <div class="header-actions">
        <div class="search-box">
          <i class="ri-search-line"></i>
          <input type="text" placeholder="搜索订单号/用户名" v-model="searchQuery">
        </div>
        <div class="filter-box">
          <select v-model="filterStatus">
            <option value="all">全部状态</option>
            <option value="0">待付款</option>
            <option value="1">待发货</option>
            <option value="2">已发货</option>
            <option value="3">已完成</option>
          </select>
        </div>
      </div>
    </div>

    <div class="data-table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>订单号</th>
            <th>用户</th>
            <th>商品信息</th>
            <th>总金额</th>
            <th>状态</th>
            <th>下单时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="order in filteredOrders" :key="order.id">
            <td class="order-no">{{ order.order_no }}</td>
            <td>{{ order.user_name }}</td>
            <td class="product-info">
              <div v-for="item in order.items" :key="item.id" class="item-row">
                {{ item.product_name }} <span class="text-muted">x{{ item.quantity }}</span>
              </div>
            </td>
            <td class="price">¥ {{ order.total_amount }}</td>
            <td>
              <span class="status-badge" :class="getStatusClass(order.status)">
                {{ getStatusText(order.status) }}
              </span>
            </td>
            <td class="date">{{ order.created_at }}</td>
            <td class="actions">
              <button class="icon-btn" title="查看详情" @click="viewOrder(order)">
                <i class="ri-eye-line"></i>
              </button>
              <button v-if="order.status === 1" class="icon-btn" title="发货" @click="openShipModal(order)">
                <i class="ri-truck-line"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Ship Modal -->
    <div v-if="showShipModal" class="modal-overlay" @click.self="closeShipModal">
      <div class="modal" style="width: 500px;">
        <div class="modal-header">
          <h2>订单发货</h2>
          <button class="close-btn" @click="closeShipModal">&times;</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>快递公司</label>
            <input type="text" v-model="shipForm.express_company" placeholder="请输入快递公司">
          </div>
          <div class="form-group" style="margin-top: 15px;">
            <label>快递单号</label>
            <input type="text" v-model="shipForm.express_no" placeholder="请输入快递单号">
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeShipModal">取消</button>
          <button class="btn-primary" @click="confirmShip" :disabled="shipping">
            {{ shipping ? '发货中...' : '确认发货' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'

const orders = ref([])
const searchQuery = ref('')
const filterStatus = ref('all')
const selectedOrder = ref(null)
const showModal = ref(false)
const showShipModal = ref(false)
const shipForm = ref({ express_company: '', express_no: '' })
const shipping = ref(false)
const currentShipOrder = ref(null)
const confirmingCancel = ref(null)

const filteredOrders = computed(() => {
  return orders.value.filter(order => {
    const matchesSearch = order.order_no.toLowerCase().includes(searchQuery.value.toLowerCase()) || 
                          order.user_name.toLowerCase().includes(searchQuery.value.toLowerCase())
    const matchesStatus = filterStatus.value === 'all' || order.status.toString() === filterStatus.value
    return matchesSearch && matchesStatus
  })
})

const getStatusText = (status) => {
  const map = { 0: '待付款', 1: '待发货', 2: '已发货', 3: '已完成', 4: '已取消' }
  return map[status] || '未知'
}

const getStatusClass = (status) => {
  const map = { 0: 'warning', 1: 'info', 2: 'primary', 3: 'success', 4: 'danger' }
  return map[status] || ''
}

const loadOrders = async () => {
  const res = await api.getOrders()
  if (res.code === 0) {
    orders.value = res.data.data || res.data
  }
}

const parseItems = (itemsStr) => {
  if (!itemsStr) return []
  // Split by comma for multiple items
  return itemsStr.split(',').map(itemStr => {
    // Basic parsing: "Name (Variant) xQty"
    const trimmed = itemStr.trim()
    const qtyMatch = trimmed.match(/x(\d+)$/)
    const qty = qtyMatch ? qtyMatch[1] : 1
    const namePart = trimmed.replace(/x\d+$/, '').trim()
    
    // Check for variant in parentheses
    const variantMatch = namePart.match(/\((.*?)\)/)
    const variant = variantMatch ? variantMatch[1] : ''
    const name = namePart.replace(/\(.*?\)/, '').trim()
    
    return { name, variant, qty }
  })
}

const viewOrder = (order) => {
  selectedOrder.value = { ...order }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
  selectedOrder.value = null
}

const openShipModal = (order) => {
  currentShipOrder.value = order
  shipForm.value = { express_company: '', express_no: '' }
  showShipModal.value = true
}

const closeShipModal = () => {
  showShipModal.value = false
  currentShipOrder.value = null
}

const confirmShip = async () => {
  if (!shipForm.value.express_company || !shipForm.value.express_no) {
    toast.warning('请填写快递信息')
    return
  }
  
  shipping.value = true
  try {
    const res = await api.shipOrder({
      id: currentShipOrder.value.id,
      ...shipForm.value
    })
    
    if (res.code === 0) {
      // Update local list
      const index = orders.value.findIndex(o => o.id === currentShipOrder.value.id)
      if (index !== -1) {
        orders.value[index].status = 2
        orders.value[index].express_company = shipForm.value.express_company
        orders.value[index].express_no = shipForm.value.express_no
      }
      toast.success('发货成功')
      closeShipModal()
    } else {
      toast.error(res.msg || '操作失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('系统错误')
  } finally {
    shipping.value = false
  }
}

const cancelOrder = async (order) => {
  if (confirmingCancel.value !== order.id) {
    confirmingCancel.value = order.id
    toast.info('再次点击以确认取消')
    setTimeout(() => confirmingCancel.value = null, 3000)
    return
  }
  confirmingCancel.value = null

  const res = await api.saveOrder({ ...order, status: 4 }) // 4 for cancelled
  if (res.code === 0) {
    const index = orders.value.findIndex(o => o.id === order.id)
    if (index !== -1) {
      orders.value[index].status = 4
    }
    if (selectedOrder.value && selectedOrder.value.id === order.id) {
      selectedOrder.value.status = 4
    }
    toast.success('订单已取消')
  } else {
    toast.error(res.msg || '操作失败')
  }
}

onMounted(() => {
  loadOrders()
})
</script>

<style scoped>
.page-container {
  padding: 2rem;
  max-width: 1600px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--color-primary-dark);
}

.header-actions {
  display: flex;
  gap: 1rem;
}

.search-box {
  position: relative;
}

.search-box i {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
}

.search-box input {
  padding: 0.5rem 1rem 0.5rem 2.2rem;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  width: 250px;
}

.filter-box select {
  padding: 0.5rem 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  background: white;
}

.data-table-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th,
.data-table td {
  padding: 1rem;
  text-align: left;
  border-bottom: 1px solid #f3f4f6;
}

.data-table th {
  background: #f9fafb;
  font-weight: 600;
  color: #4b5563;
}

.order-no {
  font-family: monospace;
  font-weight: 500;
}

.product-info {
  max-width: 300px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: #6b7280;
}

.price {
  font-weight: 600;
  color: var(--color-accent);
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.875rem;
  font-weight: 500;
}

.status-badge.warning { background: #fef3c7; color: #d97706; }
.status-badge.info { background: #dbeafe; color: #2563eb; }
.status-badge.primary { background: #e0e7ff; color: #4f46e5; }
.status-badge.success { background: #d1fae5; color: #059669; }
.status-badge.danger { background: #fee2e2; color: #dc2626; }

.date {
  color: #6b7280;
  font-size: 0.875rem;
}

.actions {
  display: flex;
  gap: 0.5rem;
}

.icon-btn {
  padding: 0.5rem;
  border: none;
  background: transparent;
  color: #6b7280;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.2s;
}

.icon-btn:hover {
  background: #f3f4f6;
  color: var(--color-primary);
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  backdrop-filter: blur(4px);
  transition: all 0.3s ease;
}

.modal {
  background: white;
  border-radius: 16px;
  width: 600px;
  max-width: 95%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  overflow: hidden;
}

.modal-header {
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #f3f4f6;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #fff;
}

.modal-header h2 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #9ca3af;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 50%;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  background: #f3f4f6;
  color: #4b5563;
}

.modal-body {
  padding: 2rem;
  overflow-y: auto;
  flex: 1;
}

.order-section {
  margin-bottom: 2rem;
}

.order-section:last-child {
  margin-bottom: 0;
}

.section-title {
  font-size: 1rem;
  font-weight: 600;
  color: #374151;
  margin-bottom: 1rem;
  padding-left: 0.5rem;
  border-left: 3px solid var(--color-primary);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.info-item.full-width {
  grid-column: span 2;
}

.info-item .label {
  font-size: 0.85rem;
  color: #6b7280;
}

.info-item .value {
  font-size: 0.95rem;
  color: #111827;
  font-weight: 500;
}

.items-list {
  border: 1px solid #f3f4f6;
  border-radius: 8px;
  overflow: hidden;
}

.order-item {
  display: flex;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #f3f4f6;
  gap: 1rem;
}

.order-item:last-child {
  border-bottom: none;
}

.item-icon {
  width: 40px;
  height: 40px;
  background: #f9fafb;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-primary);
  font-size: 1.2rem;
}

.item-details {
  flex: 1;
}

.item-name {
  font-weight: 500;
  color: #111827;
}

.item-meta {
  font-size: 0.85rem;
  color: #6b7280;
  margin-top: 0.25rem;
}

.item-qty {
  font-weight: 600;
  color: #374151;
}

.order-total {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 1rem;
  margin-top: 1rem;
  font-size: 1.1rem;
  font-weight: 600;
  color: #111827;
}

.total-price {
  color: var(--color-accent);
  font-size: 1.5rem;
}

.modal-footer {
  padding: 1.5rem 2rem;
  background: #f9fafb;
  border-top: 1px solid #f3f4f6;
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.btn-primary, .btn-secondary, .btn-danger {
  padding: 0.6rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border: none;
}

.btn-primary {
  background: var(--color-primary);
  color: white;
}

.btn-primary:hover {
  filter: brightness(110%);
}

.btn-secondary {
  background: white;
  border: 1px solid #e5e7eb;
  color: #4b5563;
}

.btn-secondary:hover {
  background: #f9fafb;
}

.btn-danger {
  background: #fee2e2;
  color: #dc2626;
}

.btn-danger:hover {
  background: #fecaca;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
