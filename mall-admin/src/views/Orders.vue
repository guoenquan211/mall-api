<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">订单管理</h1>
      <div class="header-actions">
        <div class="search-box">
          <i class="ri-search-line"></i>
          <input type="text" placeholder="搜索订单号/用户名/收货地址" v-model="searchQuery">
        </div>
        <div class="filter-box">
          <select v-model="filterStatus">
            <option value="all">全部状态</option>
            <option value="0">待付款</option>
            <option value="1">待发货</option>
            <option value="2">已发货</option>
            <option value="3">已完成</option>
            <option value="4">已取消</option>
          </select>
          <select v-model="filterPaymentStatus" class="payment-filter">
            <option value="all">全部付款</option>
            <option value="user_confirmed">待审核付款</option>
            <option value="pending">未申报付款</option>
            <option value="approved">付款已通过</option>
            <option value="rejected">付款已驳回</option>
          </select>
        </div>
      </div>
    </div>

    <div class="data-table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th class="col-order">订单号</th>
            <th class="col-user">用户</th>
            <th class="col-addr">收货地址</th>
            <th class="col-product">商品信息</th>
            <th class="col-price">总金额</th>
            <th class="col-status">订单状态</th>
            <th class="col-status">付款状态</th>
            <th class="col-remark">付款备注</th>
            <th class="col-proof">付款凭证</th>
            <th class="col-date">下单时间</th>
            <th class="col-actions sticky-right">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="order in filteredOrders" :key="order.id">
            <td class="order-no">{{ order.order_no }}</td>
            <td class="user-cell">{{ order.user_name }}</td>
            <td class="address-cell">
              <template v-if="hasShippingAddress(order)">
                <div class="addr-line name-phone">
                  <span class="addr-name">{{ parseAddress(order)?.name }}</span>
                  <span class="addr-phone">{{ parseAddress(order)?.phone }}</span>
                </div>
                <div class="addr-line region" :title="addressRegionLine(order)">
                  {{ addressRegionLine(order) }}
                </div>
              </template>
              <span v-else class="text-muted">未填写</span>
            </td>
            <td class="product-info">
              <div
                v-for="item in order.items"
                :key="item.id"
                class="item-row"
                :title="`${item.product_name} x${item.quantity}`"
              >
                {{ item.product_name }} <span class="text-muted">x{{ item.quantity }}</span>
              </div>
            </td>
            <td class="price">₱ {{ order.total_amount }}</td>
            <td>
              <span class="status-badge" :class="getStatusClass(order.status)">
                {{ getStatusText(order.status) }}
              </span>
            </td>
            <td>
              <span class="status-badge" :class="getPaymentStatusClass(order.payment_status)">
                {{ getPaymentStatusText(order.payment_status) }}
              </span>
            </td>
            <td class="payment-remark-cell">
              <span v-if="order.payment_remark" class="remark-text" :title="order.payment_remark">
                {{ order.payment_remark }}
              </span>
              <span v-else class="text-muted">—</span>
            </td>
            <td class="proof-cell">
              <button
                v-if="proofUrl(order)"
                type="button"
                class="proof-thumb-btn"
                title="点击查看付款凭证"
                @click="viewOrder(order)"
              >
                <img :src="proofUrl(order)" alt="付款凭证" class="proof-thumb" />
              </button>
              <span v-else-if="order.payment_status === 'user_confirmed'" class="text-warn">未上传</span>
              <span v-else class="text-muted">—</span>
            </td>
            <td class="date">{{ orderDisplayTime(order) }}</td>
            <td class="actions sticky-right">
              <div class="action-group">
                <button
                  class="icon-btn"
                  :class="{ highlight: order.payment_status === 'user_confirmed' }"
                  :title="order.payment_status === 'user_confirmed' ? '查看付款凭证与备注' : '查看详情'"
                  @click="viewOrder(order)"
                >
                  <i class="ri-file-list-3-line"></i>
                </button>
                <template v-if="order.payment_status === 'user_confirmed'">
                  <button class="icon-btn success" title="通过付款" @click="approvePayment(order)">
                    <i class="ri-check-line"></i>
                  </button>
                  <button class="icon-btn danger" title="驳回付款" @click="rejectPayment(order)">
                    <i class="ri-close-line"></i>
                  </button>
                </template>
                <button v-if="order.status === 1" class="icon-btn" title="发货" @click="openShipModal(order)">
                  <i class="ri-truck-line"></i>
                </button>
                <button class="icon-btn" title="编辑订单" @click="openEditModal(order)">
                  <i class="ri-edit-line"></i>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Order Detail Modal -->
    <div v-if="showModal && selectedOrder" class="modal-overlay" @click.self="closeModal">
      <div class="modal modal-wide">
        <div class="modal-header">
          <h2>订单详情 · {{ selectedOrder.order_no }}</h2>
          <button class="close-btn" @click="closeModal">&times;</button>
        </div>
        <div class="modal-body">
          <div
            v-if="['user_confirmed', 'approved', 'rejected'].includes(selectedOrder.payment_status)"
            class="order-section payment-review-section"
          >
            <h3 class="section-title">付款申报信息</h3>
            <div class="info-grid">
              <div class="info-item"><span class="label">申报时间</span><span class="value">{{ selectedOrder.user_paid_at_text || '—' }}</span></div>
              <div class="info-item"><span class="label">付款状态</span><span class="value">{{ getPaymentStatusText(selectedOrder.payment_status) }}</span></div>
              <div class="info-item full-width">
                <span class="label">付款备注</span>
                <span class="value remark-block">{{ selectedOrder.payment_remark || '（用户未填写）' }}</span>
              </div>
              <div class="info-item full-width reject-reason" v-if="selectedOrder.payment_reject_reason">
                <span class="label">驳回原因</span><span class="value">{{ selectedOrder.payment_reject_reason }}</span>
              </div>
            </div>
            <div v-if="proofUrl(selectedOrder)" class="proof-detail">
              <p class="proof-detail-label">付款凭证</p>
              <a :href="proofUrl(selectedOrder)" target="_blank" rel="noopener" class="proof-link">
                <img :src="proofUrl(selectedOrder)" alt="付款凭证" class="proof-img" />
              </a>
              <p class="proof-tip">点击图片可在新窗口查看大图</p>
            </div>
            <p v-else class="no-proof-warn">用户已申报付款，但未上传付款凭证</p>
          </div>

          <div class="order-section shipping-section">
            <h3 class="section-title">配送地址</h3>
            <div v-if="hasShippingAddress(selectedOrder)" class="shipping-block">
              <div class="shipping-row">
                <span class="shipping-label">收件人</span>
                <span>{{ parseAddress(selectedOrder)?.name }}</span>
              </div>
              <div class="shipping-row">
                <span class="shipping-label">联系电话</span>
                <span>{{ parseAddress(selectedOrder)?.phone }}</span>
              </div>
              <div class="shipping-row">
                <span class="shipping-label">详细地址</span>
                <span>{{ addressRegionLine(selectedOrder) }}</span>
              </div>
            </div>
            <p v-else class="no-address-tip">该订单下单时未保存收货地址（多为地址功能上线前的历史订单）</p>
          </div>

          <div class="order-section">
            <h3 class="section-title">订单信息</h3>
            <div class="info-grid">
              <div class="info-item"><span class="label">订单号</span><span class="value">{{ selectedOrder.order_no }}</span></div>
              <div class="info-item"><span class="label">用户</span><span class="value">{{ selectedOrder.user_name }}</span></div>
              <div class="info-item"><span class="label">下单时间</span><span class="value">{{ orderDisplayTime(selectedOrder) || '—' }}</span></div>
              <div class="info-item"><span class="label">订单状态</span><span class="value">{{ getStatusText(selectedOrder.status) }}</span></div>
              <div v-if="selectedOrder.express_company || selectedOrder.express_no" class="info-item">
                <span class="label">物流公司</span><span class="value">{{ selectedOrder.express_company || '—' }}</span>
              </div>
              <div v-if="selectedOrder.express_company || selectedOrder.express_no" class="info-item">
                <span class="label">物流单号</span><span class="value">{{ selectedOrder.express_no || '—' }}</span>
              </div>
              <div v-if="selectedOrder.express_tracking_url" class="info-item full-width">
                <span class="label">实时物流</span>
                <a
                  class="tracking-link"
                  :href="selectedOrder.express_tracking_url"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <i class="ri-map-pin-time-line"></i> 打开实时物流页面
                </a>
              </div>
              <div v-if="selectedOrder.remark" class="info-item full-width">
                <span class="label">订单备注</span><span class="value remark-block">{{ selectedOrder.remark }}</span>
              </div>
            </div>
          </div>

          <div class="order-section">
            <h3 class="section-title">商品明细</h3>
            <div class="items-list">
              <div v-for="item in selectedOrder.items" :key="item.id" class="order-item">
                <div class="item-icon"><i class="ri-shopping-bag-line"></i></div>
                <div class="item-details">
                  <div class="item-name">{{ item.product_name }}</div>
                  <div class="item-meta" v-if="item.variant_name">{{ item.variant_name }}</div>
                </div>
                <div class="item-qty">x{{ item.quantity }}</div>
                <div class="item-price">₱ {{ item.price }}</div>
              </div>
            </div>
            <div class="order-total">
              <span>合计</span>
              <span class="total-price">₱ {{ selectedOrder.total_amount }}</span>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeModal">关闭</button>
          <template v-if="selectedOrder.payment_status === 'user_confirmed'">
            <button class="btn-danger" @click="rejectPayment(selectedOrder)">驳回付款</button>
            <button class="btn-primary" @click="approvePayment(selectedOrder)">通过付款</button>
          </template>
          <button v-if="selectedOrder.status === 1" class="btn-primary" @click="openShipModal(selectedOrder); closeModal()">发货</button>
          <button class="btn-primary outline" @click="openEditModal(selectedOrder)">编辑订单</button>
        </div>
      </div>
    </div>

    <!-- Edit Order Modal -->
    <div v-if="showEditModal" class="modal-overlay" @click.self="closeEditModal">
      <div class="modal" style="width: 520px;">
        <div class="modal-header">
          <h2>编辑订单 · {{ editForm.order_no }}</h2>
          <button class="close-btn" @click="closeEditModal">&times;</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>配送状态</label>
            <select v-model.number="editForm.status">
              <option :value="0">待付款</option>
              <option :value="1">待发货</option>
              <option :value="2">已发货</option>
              <option :value="3">已完成</option>
              <option :value="4">已取消</option>
            </select>
          </div>
          <div class="form-group" style="margin-top: 15px;">
            <label>物流公司</label>
            <input type="text" v-model="editForm.express_company" placeholder="如 J&T、LBC、Grab Express">
          </div>
          <div class="form-group" style="margin-top: 15px;">
            <label>物流单号</label>
            <input type="text" v-model="editForm.express_no" placeholder="运单号">
          </div>
          <div class="form-group" style="margin-top: 15px;">
            <label>实时物流链接</label>
            <input
              type="url"
              v-model.trim="editForm.express_tracking_url"
              placeholder="粘贴 Lalamove / Grab 等实时追踪链接"
            >
            <p class="field-hint">用户可在会员中心直接打开该链接查看骑手位置和配送进度。</p>
          </div>
          <div class="form-group" style="margin-top: 15px;">
            <label>订单备注（后台）</label>
            <textarea v-model="editForm.remark" rows="3" placeholder="内部备注，用户不可见"></textarea>
          </div>
          <p class="edit-hint">付款已通过后可修改配送状态与物流信息；设为「已完成」将触发分销结算。</p>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeEditModal">取消</button>
          <button class="btn-primary" @click="confirmSaveEdit" :disabled="savingEdit">
            {{ savingEdit ? '保存中...' : '保存' }}
          </button>
        </div>
      </div>
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
          <div class="form-group" style="margin-top: 15px;">
            <label>实时物流链接（选填）</label>
            <input
              type="url"
              v-model.trim="shipForm.express_tracking_url"
              placeholder="粘贴 Lalamove / Grab 等实时追踪链接"
            >
            <p class="field-hint">例如 Lalamove 分享给收件人的实时追踪网址。</p>
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
import { resolveMediaUrl } from '../utils/resolveMediaUrl'

const orders = ref([])
const searchQuery = ref('')
const filterStatus = ref('all')
const filterPaymentStatus = ref('all')
const selectedOrder = ref(null)
const showModal = ref(false)
const showShipModal = ref(false)
const shipForm = ref({ express_company: '', express_no: '', express_tracking_url: '' })
const shipping = ref(false)
const currentShipOrder = ref(null)
const confirmingCancel = ref(null)
const showEditModal = ref(false)
const savingEdit = ref(false)
const editForm = ref({
  id: null,
  order_no: '',
  status: 1,
  express_company: '',
  express_no: '',
  express_tracking_url: '',
  remark: '',
})

const filteredOrders = computed(() => {
  return orders.value.filter(order => {
    const q = searchQuery.value.toLowerCase()
    const addrText = (order.address_text || addressDisplayText(order) || '').toLowerCase()
    const matchesSearch = !q
      || order.order_no.toLowerCase().includes(q)
      || (order.user_name || '').toLowerCase().includes(q)
      || addrText.includes(q)
    const matchesStatus = filterStatus.value === 'all' || order.status.toString() === filterStatus.value
    const ps = order.payment_status || 'pending'
    const matchesPayment = filterPaymentStatus.value === 'all' || ps === filterPaymentStatus.value
    return matchesSearch && matchesStatus && matchesPayment
  })
})

const parseAddress = (order) => {
  if (!order) return null
  if (order.address_snapshot) {
    try {
      const snap = typeof order.address_snapshot === 'string'
        ? JSON.parse(order.address_snapshot)
        : order.address_snapshot
      if (snap && typeof snap === 'object') return snap
    } catch {
      /* use address_text fallback */
    }
  }
  if (order.address_text) {
    return { name: '', phone: '', _textOnly: order.address_text }
  }
  return null
}

const hasShippingAddress = (order) => {
  const snap = parseAddress(order)
  if (!snap) return false
  if (snap._textOnly) return !!snap._textOnly
  return !!(snap.name || snap.phone || snap.province || snap.city || snap.district || snap.detail)
}

const addressRegionLine = (order) => {
  const snap = parseAddress(order)
  if (!snap) return ''
  if (snap._textOnly) return snap._textOnly
  return [snap.province, snap.city, snap.district, snap.detail].filter(Boolean).join(' ')
}

const addressDisplayText = (order) => {
  if (!order) return '—'
  if (order.address_text) return order.address_text
  if (!hasShippingAddress(order)) return '—'
  const snap = parseAddress(order)
  const region = addressRegionLine(order)
  return [snap.name, snap.phone, region].filter(Boolean).join(' · ')
}

const normalizeOrder = (o) => ({
  ...o,
  payment_proof_image_url: o.payment_proof_image_url
    || (o.payment_proof_image ? resolveMediaUrl(o.payment_proof_image) : ''),
  address_text: o.address_text || (addressDisplayText(o) !== '—' ? addressDisplayText(o) : ''),
})

const proofUrl = (order) => {
  if (!order) return ''
  const url = order.payment_proof_image_url || order.payment_proof_image || ''
  if (!url) return ''
  return resolveMediaUrl(url)
}

const orderDisplayTime = (order) => {
  if (!order) return '—'
  if (order.created_at_text) return order.created_at_text
  return formatTimestamp(order.created_at)
}

const formatTimestamp = (ts) => {
  if (!ts) return ''
  const d = typeof ts === 'number' ? new Date(ts * 1000) : new Date(ts)
  return Number.isNaN(d.getTime()) ? String(ts) : d.toLocaleString()
}

const getStatusText = (status) => {
  const map = { 0: '待付款', 1: '待发货', 2: '已发货', 3: '已完成', 4: '已取消' }
  return map[status] || '未知'
}

const getStatusClass = (status) => {
  const map = { 0: 'warning', 1: 'info', 2: 'primary', 3: 'success', 4: 'danger' }
  return map[status] || ''
}

const getPaymentStatusText = (ps) => {
  const map = {
    pending: '未申报',
    user_confirmed: '待审核',
    approved: '已通过',
    rejected: '已驳回',
  }
  return map[ps] || ps || '—'
}

const getPaymentStatusClass = (ps) => {
  const map = {
    pending: 'muted',
    user_confirmed: 'warning',
    approved: 'success',
    rejected: 'danger',
  }
  return map[ps] || 'muted'
}

const openEditModal = (order) => {
  editForm.value = {
    id: order.id,
    order_no: order.order_no,
    status: Number(order.status),
    express_company: order.express_company || '',
    express_no: order.express_no || '',
    express_tracking_url: order.express_tracking_url || '',
    remark: order.remark || '',
  }
  showEditModal.value = true
}

const closeEditModal = () => {
  showEditModal.value = false
}

const confirmSaveEdit = async () => {
  if (!editForm.value.id) return
  savingEdit.value = true
  try {
    const res = await api.saveOrder({ ...editForm.value })
    if (res.code === 0) {
      toast.success('保存成功')
      closeEditModal()
      await loadOrders()
      if (selectedOrder.value && selectedOrder.value.id === editForm.value.id) {
        const updated = orders.value.find((o) => o.id === editForm.value.id)
        if (updated) selectedOrder.value = normalizeOrder({ ...updated })
      }
    } else {
      toast.error(res.msg || '保存失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('系统错误')
  } finally {
    savingEdit.value = false
  }
}

const loadOrders = async () => {
  const res = await api.getOrders({ limit: 200 })
  if (res.code === 0) {
    const list = res.data.data || res.data || []
    orders.value = list.map((o) => normalizeOrder(o))
  }
}

const approvePayment = async (order) => {
  const note = window.prompt('审核备注（可选）', '') ?? ''
  const res = await api.approveGcashPayment({ order_id: order.id, admin_note: note })
  if (res.code === 0) {
    toast.success(res.msg || '已通过，可发货')
    closeModal()
    loadOrders()
  } else {
    toast.error(res.msg || '操作失败')
  }
}

const rejectPayment = async (order) => {
  const reason = window.prompt('请填写驳回原因（必填）', order.payment_reject_reason || '') ?? ''
  if (!reason.trim()) {
    toast.warning('请填写驳回原因')
    return
  }
  const res = await api.rejectGcashPayment({ order_id: order.id, admin_note: reason.trim() })
  if (res.code === 0) {
    toast.success(res.msg || '已驳回')
    closeModal()
    loadOrders()
  } else {
    toast.error(res.msg || '操作失败')
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

const viewOrder = async (order) => {
  selectedOrder.value = normalizeOrder({ ...order })
  showModal.value = true
  try {
    const res = await api.getOrder(order.id)
    if (res?.code === 0 && res.data && !Array.isArray(res.data.data)) {
      selectedOrder.value = normalizeOrder(res.data)
    }
  } catch (_) {
    /* 列表数据已足够时忽略 */
  }
}

const closeModal = () => {
  showModal.value = false
  selectedOrder.value = null
}

const openShipModal = (order) => {
  currentShipOrder.value = order
  shipForm.value = {
    express_company: order.express_company || '',
    express_no: order.express_no || '',
    express_tracking_url: order.express_tracking_url || '',
  }
  showShipModal.value = true
}

const closeShipModal = () => {
  showShipModal.value = false
  currentShipOrder.value = null
}

const confirmShip = async () => {
  if (!shipForm.value.express_company
    || (!shipForm.value.express_no && !shipForm.value.express_tracking_url)) {
    toast.warning('请填写物流公司，并至少填写物流单号或实时物流链接')
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
        orders.value[index].express_tracking_url = shipForm.value.express_tracking_url
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
  padding: 0.55rem 1rem 0.55rem 2.2rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  width: 260px;
  background: #fff;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.search-box input:focus {
  outline: none;
  border-color: var(--color-primary, #10b981);
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.12);
}

.filter-box {
  display: flex;
  gap: 0.5rem;
}
.filter-box select {
  padding: 0.55rem 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: white;
  cursor: pointer;
}

.filter-box select:focus {
  outline: none;
  border-color: var(--color-primary, #10b981);
}
.status-badge.muted { background: #f3f4f6; color: #6b7280; }
.icon-btn.success { color: #059669; }
.icon-btn.success:hover { background: #d1fae5; }
.icon-btn.danger { color: #dc2626; }
.icon-btn.danger:hover { background: #fee2e2; }
.proof-img {
  max-width: 100%;
  max-height: 360px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  display: block;
  margin: 0 auto;
}
.proof-link { display: block; }
.proof-tip, .no-proof-warn {
  font-size: 0.85rem;
  color: #6b7280;
  text-align: center;
  margin-top: 0.5rem;
}
.no-proof-warn { color: #dc2626; }
.reject-reason .value { color: #dc2626; }
.payment-review-section {
  background: #fffbeb;
  border: 1px solid #fde68a;
  border-radius: 10px;
  padding: 1rem 1.25rem;
}
.payment-review-section .section-title {
  border-left-color: #d97706;
}
.remark-block {
  white-space: pre-wrap;
  word-break: break-word;
}
.proof-detail-label {
  font-size: 0.85rem;
  color: #6b7280;
  margin: 0.75rem 0 0.5rem;
}
.payment-remark-cell {
  max-width: 120px;
  min-width: 88px;
}
.remark-text {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  font-size: 0.82rem;
  line-height: 1.4;
  color: #374151;
}
.text-muted { color: #9ca3af; font-size: 0.82rem; }
.text-warn { color: #d97706; font-size: 0.8rem; }
.proof-cell {
  width: 64px;
  text-align: center;
  vertical-align: middle;
}
.proof-thumb-btn {
  padding: 0;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  overflow: hidden;
  line-height: 0;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.proof-thumb-btn:hover {
  border-color: var(--color-primary);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
.proof-thumb {
  width: 44px;
  height: 44px;
  object-fit: cover;
  display: block;
}
.icon-btn.highlight {
  color: #d97706;
  background: #fef3c7;
}
.item-price { font-weight: 600; color: var(--color-accent); min-width: 4rem; text-align: right; }

.data-table-card {
  background: white;
  border-radius: 14px;
  border: 1px solid #eef0f2;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.04);
  overflow: auto;
  max-height: calc(100vh - 220px);
}

.data-table {
  width: 100%;
  min-width: 1180px;
  border-collapse: separate;
  border-spacing: 0;
  table-layout: fixed;
}

.data-table th,
.data-table td {
  padding: 0.85rem 0.9rem;
  text-align: left;
  border-bottom: 1px solid #f1f3f5;
  vertical-align: middle;
  background: #fff;
}

.data-table th {
  position: sticky;
  top: 0;
  z-index: 3;
  background: #f8faf9;
  font-weight: 600;
  color: #64748b;
  font-size: 0.78rem;
  letter-spacing: 0.04em;
  text-transform: none;
  white-space: nowrap;
  border-bottom: 1px solid #e8ece9;
}

.data-table tbody tr {
  transition: background 0.15s ease;
}

.data-table tbody tr:hover td {
  background: #fbfcfb;
}

.data-table tbody tr:last-child td {
  border-bottom: none;
}

.col-order { width: 150px; }
.col-user { width: 88px; }
.col-addr { width: 180px; }
.col-product { width: 200px; }
.col-price { width: 90px; }
.col-status { width: 96px; }
.col-remark { width: 110px; }
.col-proof { width: 72px; }
.col-date { width: 130px; }
.col-actions {
  width: 148px;
}

.sticky-right {
  position: sticky;
  right: 0;
  z-index: 2;
  box-shadow: -8px 0 16px rgba(15, 23, 42, 0.06);
}

thead .sticky-right {
  z-index: 4;
  background: #f8faf9;
}

tbody .sticky-right {
  background: #fff;
}

.data-table tbody tr:hover .sticky-right {
  background: #fbfcfb;
}

.order-no {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-weight: 600;
  font-size: 0.84rem;
  color: #1f2937;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.user-cell {
  font-size: 0.9rem;
  color: #374151;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.product-info {
  max-width: 100%;
  color: #6b7280;
  font-size: 0.86rem;
}

.product-info .item-row {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.45;
}

.product-info .item-row + .item-row {
  margin-top: 0.15rem;
}

.price {
  font-weight: 700;
  color: var(--color-accent);
  white-space: nowrap;
  font-size: 0.92rem;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 4.5rem;
  padding: 0.22rem 0.65rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
  line-height: 1.3;
  white-space: nowrap;
}

.status-badge.warning { background: #fef3c7; color: #d97706; }
.status-badge.info { background: #dbeafe; color: #2563eb; }
.status-badge.primary { background: #e0e7ff; color: #4f46e5; }
.status-badge.success { background: #d1fae5; color: #059669; }
.status-badge.danger { background: #fee2e2; color: #dc2626; }

.date {
  color: #6b7280;
  font-size: 0.8rem;
  white-space: nowrap;
}

.actions {
  padding-left: 0.75rem !important;
  padding-right: 0.75rem !important;
}

.action-group {
  display: inline-flex;
  align-items: center;
  justify-content: flex-end;
  gap: 0.25rem;
  flex-wrap: nowrap;
  min-height: 36px;
}

.icon-btn {
  width: 32px;
  height: 32px;
  padding: 0;
  border: 1px solid transparent;
  background: transparent;
  color: #6b7280;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.2s;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
  flex-shrink: 0;
}

.icon-btn:hover {
  background: #f3f4f6;
  color: var(--color-primary);
  border-color: #e5e7eb;
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

.modal.modal-wide {
  width: 720px;
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

.tracking-link {
  display: inline-flex;
  align-items: center;
  align-self: flex-start;
  gap: 0.4rem;
  color: #047857;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 0.5rem 0.75rem;
  font-size: 0.88rem;
  font-weight: 600;
  text-decoration: none;
}

.tracking-link:hover {
  background: #d1fae5;
}

.field-hint {
  margin: 0.4rem 0 0;
  color: #9ca3af;
  font-size: 0.78rem;
  line-height: 1.45;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  box-sizing: border-box;
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

.edit-hint {
  margin-top: 12px;
  font-size: 0.8rem;
  color: #6b7280;
  line-height: 1.5;
}

.modal-body textarea {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-family: inherit;
  resize: vertical;
}

.modal-body select {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
}

.btn-primary.outline {
  background: #fff;
  color: var(--color-primary, #2563eb);
  border: 1px solid var(--color-primary, #2563eb);
}

.address-cell {
  font-size: 0.82rem;
  line-height: 1.35;
  vertical-align: middle;
}

.address-cell .addr-line.name-phone {
  margin-bottom: 0.15rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.address-cell .addr-name {
  font-weight: 600;
  margin-right: 0.35rem;
  color: #1f2937;
}

.address-cell .addr-phone {
  color: #6b7280;
}

.address-cell .region {
  color: #4b5563;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
}

.shipping-section {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  padding: 1rem 1.25rem;
}

.shipping-block .shipping-row {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
  font-size: 0.95rem;
}

.shipping-block .shipping-row:last-child {
  margin-bottom: 0;
}

.shipping-label {
  flex-shrink: 0;
  width: 4.5rem;
  color: #6b7280;
  font-size: 0.85rem;
}

.no-address-tip {
  margin: 0;
  color: #9ca3af;
  font-size: 0.9rem;
}
</style>
