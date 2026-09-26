<template>
  <div class="page-container gcash-admin">
    <div class="page-header">
      <h1 class="page-title">GCash 收款与提现</h1>
      <div class="tab-bar">
        <button type="button" :class="{ active: tab === 'accounts' }" @click="tab = 'accounts'">收款账号</button>
        <button type="button" :class="{ active: tab === 'payments' }" @click="switchTab('payments')">付款审核</button>
        <button type="button" :class="{ active: tab === 'withdrawals' }" @click="switchTab('withdrawals')">提现审核</button>
      </div>
    </div>

    <!-- Platform GCash accounts -->
    <div v-if="tab === 'accounts'" class="panel">
      <div v-for="slot in [1, 2]" :key="slot" class="account-card">
        <h3>收款账号 {{ slot }}</h3>
        <div class="form-grid">
          <label>显示名称<input v-model="accountForms[slot].label" type="text" /></label>
          <label>账户名<input v-model="accountForms[slot].account_name" type="text" /></label>
          <label>手机号<input v-model="accountForms[slot].mobile" type="text" /></label>
          <label>
            <input type="checkbox" v-model="accountForms[slot].is_active" :true-value="1" :false-value="0" />
            启用
          </label>
        </div>
        <div class="qr-section">
          <p class="qr-label">收款二维码</p>
          <div class="qr-upload">
            <div
              class="qr-preview-box"
              :class="{ empty: !accountForms[slot].qr_image, clickable: !!accountForms[slot].qr_image }"
              @click="openQrPreview(slot)"
            >
              <img
                v-if="accountForms[slot].qr_image"
                :src="qrImageUrl(slot)"
                alt="GCash QR"
                class="qr-preview"
                @error="onQrImgError(slot)"
              />
              <div v-else class="qr-placeholder">
                <i class="ri-qr-code-line"></i>
                <span>暂无二维码</span>
              </div>
              <div v-if="accountForms[slot].qr_image" class="qr-hover-tip">点击放大预览</div>
            </div>
            <div class="qr-actions">
              <label class="upload-btn">
                <i class="ri-upload-2-line"></i>
                {{ accountForms[slot].qr_image ? '更换二维码' : '上传二维码' }}
                <input type="file" accept="image/*" @change="(e) => onQrUpload(slot, e)" hidden />
              </label>
              <button
                v-if="accountForms[slot].qr_image"
                type="button"
                class="btn-text-danger"
                @click="clearQr(slot)"
              >
                移除
              </button>
            </div>
          </div>
        </div>
        <button class="btn-primary" :disabled="savingSlot === slot" @click="saveAccount(slot)">
          {{ savingSlot === slot ? '保存中…' : '保存账号' }}
        </button>
      </div>
    </div>

    <!-- Payment reviews -->
    <div v-if="tab === 'payments'" class="panel">
      <div v-if="loadingPayments" class="loading">加载中…</div>
      <div v-else-if="!paymentOrders.length" class="empty">暂无待审核付款</div>
      <table v-else class="data-table">
        <thead>
          <tr>
            <th>订单号</th>
            <th>用户</th>
            <th>金额</th>
            <th>备注</th>
            <th>申报时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="o in paymentOrders" :key="o.id">
            <td>{{ o.order_no }}</td>
            <td>{{ o.user_name }}</td>
            <td>₱{{ o.total_amount }}</td>
            <td>{{ o.payment_remark || '—' }}</td>
            <td>{{ formatTime(o.user_paid_at) }}</td>
            <td class="actions">
              <button class="btn-primary btn-sm" @click="approvePayment(o)">通过</button>
              <button class="btn-secondary btn-sm" @click="rejectPayment(o)">驳回</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Withdrawals -->
    <div v-if="tab === 'withdrawals'" class="panel">
      <div class="filter-row">
        <select v-model="withdrawFilter" @change="loadWithdrawals">
          <option value="pending">待审核</option>
          <option value="all">全部</option>
          <option value="approved">已通过</option>
          <option value="rejected">已拒绝</option>
        </select>
      </div>
      <div v-if="loadingWithdrawals" class="loading">加载中…</div>
      <div v-else-if="!withdrawals.length" class="empty">暂无提现记录</div>
      <table v-else class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>用户</th>
            <th>金额</th>
            <th>GCash</th>
            <th>状态</th>
            <th>时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="w in withdrawals" :key="w.id">
            <td>#{{ w.id }}</td>
            <td>{{ w.user_name }}</td>
            <td>₱{{ w.amount }}</td>
            <td>{{ w.gcash_number }}<br /><small>{{ w.gcash_name }}</small></td>
            <td><span class="status-badge" :class="'ws-' + w.status">{{ withdrawStatusText(w.status) }}</span></td>
            <td>{{ formatTime(w.created_at) }}</td>
            <td v-if="w.status === 'pending'" class="actions">
              <button class="btn-primary btn-sm" @click="approveWithdraw(w)">通过</button>
              <button class="btn-secondary btn-sm" @click="rejectWithdraw(w)">拒绝</button>
            </td>
            <td v-else>—</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="lightboxUrl" class="qr-lightbox" @click="lightboxUrl = ''">
      <div class="lightbox-inner" @click.stop>
        <button type="button" class="lightbox-close" aria-label="关闭" @click="lightboxUrl = ''">
          <i class="ri-close-line"></i>
        </button>
        <img :src="lightboxUrl" alt="GCash QR 预览" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'
import { resolveMediaUrl } from '../utils/resolveMediaUrl'

const tab = ref('accounts')
const savingSlot = ref(0)
const accountForms = reactive({
  1: { id: null, slot: 1, label: '', account_name: '', mobile: '', qr_image: '', is_active: 1 },
  2: { id: null, slot: 2, label: '', account_name: '', mobile: '', qr_image: '', is_active: 1 },
})

const paymentOrders = ref([])
const loadingPayments = ref(false)
const withdrawals = ref([])
const loadingWithdrawals = ref(false)
const withdrawFilter = ref('pending')
const lightboxUrl = ref('')
/** 上传后本地即时预览（避免 dev 环境 storage 路径未解析前空白） */
const qrLocalPreview = reactive({ 1: '', 2: '' })

const revokeLocalPreview = (slot) => {
  if (qrLocalPreview[slot]) {
    URL.revokeObjectURL(qrLocalPreview[slot])
    qrLocalPreview[slot] = ''
  }
}

const qrImageUrl = (slot) => {
  if (qrLocalPreview[slot]) return qrLocalPreview[slot]
  return resolveMediaUrl(accountForms[slot].qr_image)
}

const openQrPreview = (slot) => {
  const url = qrImageUrl(slot)
  if (url) lightboxUrl.value = url
}

const onQrImgError = (slot) => {
  console.warn('QR image failed to load:', accountForms[slot].qr_image)
}

const clearQr = (slot) => {
  revokeLocalPreview(slot)
  accountForms[slot].qr_image = ''
}

const formatTime = (ts) => {
  if (!ts) return '—'
  const d = typeof ts === 'number' ? new Date(ts * 1000) : new Date(ts)
  return Number.isNaN(d.getTime()) ? String(ts) : d.toLocaleString()
}

const withdrawStatusText = (s) => ({ pending: '待审核', approved: '已通过', rejected: '已拒绝' }[s] || s)

const loadAccounts = async () => {
  const res = await api.getGcashAccounts()
  if (res.code === 0) {
    for (const row of res.data || []) {
      const slot = row.slot
      if (slot === 1 || slot === 2) {
        Object.assign(accountForms[slot], {
          id: row.id,
          slot: row.slot,
          label: row.label || '',
          account_name: row.account_name || '',
          mobile: row.mobile || '',
          qr_image: row.qr_image || '',
          is_active: row.is_active != null ? Number(row.is_active) : 1,
        })
      }
    }
  }
}

const saveAccount = async (slot) => {
  savingSlot.value = slot
  try {
    const payload = { ...accountForms[slot], slot, is_active: accountForms[slot].is_active ? 1 : 0 }
    const res = await api.saveGcashAccount(payload)
    if (res.code === 0) {
      toast.success('保存成功')
      if (res.data) {
        if (res.data.id) accountForms[slot].id = res.data.id
        if (res.data.qr_image) accountForms[slot].qr_image = res.data.qr_image
      }
    } else {
      toast.error(res.msg || '保存失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('系统错误')
  } finally {
    savingSlot.value = 0
  }
}

const onQrUpload = async (slot, e) => {
  const file = e.target?.files?.[0]
  if (!file) return
  revokeLocalPreview(slot)
  qrLocalPreview[slot] = URL.createObjectURL(file)
  try {
    const res = await api.uploadImage(file)
    if (res.code === 0 && res.data?.url) {
      accountForms[slot].qr_image = res.data.url
      revokeLocalPreview(slot)
      toast.success('二维码已上传，请点击「保存账号」写入配置')
    } else {
      revokeLocalPreview(slot)
      toast.error(res.msg || '上传失败')
    }
  } catch (err) {
    console.error(err)
    revokeLocalPreview(slot)
    toast.error('上传失败')
  }
  e.target.value = ''
}

const loadPaymentReviews = async () => {
  loadingPayments.value = true
  try {
    const res = await api.getGcashPaymentReviews({ limit: 50 })
    if (res.code === 0) {
      paymentOrders.value = res.data?.data ?? res.data ?? []
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingPayments.value = false
  }
}

const approvePayment = async (order) => {
  const note = window.prompt('审核备注（可选）', '') ?? ''
  const res = await api.approveGcashPayment({ order_id: order.id, admin_note: note })
  if (res.code === 0) {
    toast.success(res.msg || '已通过，可发货')
    loadPaymentReviews()
  } else {
    toast.error(res.msg || '操作失败')
  }
}

const rejectPayment = async (order) => {
  const note = window.prompt('驳回原因（建议填写）', '') ?? ''
  const res = await api.rejectGcashPayment({ order_id: order.id, admin_note: note })
  if (res.code === 0) {
    toast.success(res.msg || '已驳回')
    loadPaymentReviews()
  } else {
    toast.error(res.msg || '操作失败')
  }
}

const loadWithdrawals = async () => {
  loadingWithdrawals.value = true
  try {
    const res = await api.getGcashWithdrawals({ status: withdrawFilter.value, limit: 50 })
    if (res.code === 0) {
      withdrawals.value = res.data?.data ?? res.data ?? []
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingWithdrawals.value = false
  }
}

const approveWithdraw = async (row) => {
  const ref = window.prompt('转账参考号（可选）', '') ?? ''
  const note = window.prompt('备注（可选）', '') ?? ''
  const res = await api.approveGcashWithdrawal({ id: row.id, payout_ref: ref, admin_note: note })
  if (res.code === 0) {
    toast.success(res.msg || '已通过，请线下转账')
    loadWithdrawals()
  } else {
    toast.error(res.msg || '操作失败')
  }
}

const rejectWithdraw = async (row) => {
  const note = window.prompt('拒绝原因', '') ?? ''
  const res = await api.rejectGcashWithdrawal({ id: row.id, admin_note: note })
  if (res.code === 0) {
    toast.success(res.msg || '已拒绝')
    loadWithdrawals()
  } else {
    toast.error(res.msg || '操作失败')
  }
}

const switchTab = (t) => {
  tab.value = t
  if (t === 'payments') loadPaymentReviews()
  if (t === 'withdrawals') loadWithdrawals()
}

onMounted(loadAccounts)
</script>

<style scoped>
.gcash-admin .tab-bar {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
}
.gcash-admin .tab-bar button {
  padding: 0.5rem 1rem;
  border: 1px solid #e5e7eb;
  background: #fff;
  border-radius: 6px;
  cursor: pointer;
}
.gcash-admin .tab-bar button.active {
  background: #111;
  color: #fff;
  border-color: #111;
}
.panel {
  margin-top: 1.5rem;
}
.account-card {
  background: #fff;
  border: 1px solid #eee;
  border-radius: 10px;
  padding: 1.25rem;
  margin-bottom: 1rem;
}
.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 0.75rem;
  margin-bottom: 1rem;
}
.form-grid label {
  display: flex;
  flex-direction: column;
  font-size: 0.85rem;
  gap: 0.35rem;
}
.form-grid input[type='text'] {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 6px;
}
.qr-section {
  margin-bottom: 1rem;
}
.qr-label {
  font-size: 0.85rem;
  color: #6b7280;
  margin: 0 0 0.5rem;
}
.qr-upload {
  display: flex;
  align-items: flex-start;
  gap: 1.25rem;
  flex-wrap: wrap;
}
.qr-preview-box {
  position: relative;
  width: 160px;
  height: 160px;
  border: 2px dashed #d1d5db;
  border-radius: 10px;
  background: #fafafa;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}
.qr-preview-box.clickable {
  cursor: zoom-in;
  border-style: solid;
  border-color: #e5e7eb;
}
.qr-preview-box.clickable:hover .qr-hover-tip {
  opacity: 1;
}
.qr-preview {
  width: 100%;
  height: 100%;
  object-fit: contain;
  background: #fff;
}
.qr-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.35rem;
  color: #9ca3af;
  font-size: 0.82rem;
}
.qr-placeholder i {
  font-size: 2rem;
}
.qr-hover-tip {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  color: #fff;
  font-size: 0.8rem;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
  pointer-events: none;
}
.qr-actions {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.upload-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.5rem 1rem;
  background: #f3f4f6;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.88rem;
}
.upload-btn:hover {
  background: #e5e7eb;
}
.btn-text-danger {
  background: none;
  border: none;
  color: #dc2626;
  cursor: pointer;
  font-size: 0.85rem;
  padding: 0.25rem 0;
  text-align: left;
}
.qr-lightbox {
  position: fixed;
  inset: 0;
  z-index: 2000;
  background: rgba(0, 0, 0, 0.75);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}
.lightbox-inner {
  position: relative;
  max-width: min(90vw, 480px);
  max-height: 90vh;
  background: #fff;
  border-radius: 12px;
  padding: 1rem;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.35);
}
.lightbox-inner img {
  display: block;
  max-width: 100%;
  max-height: calc(90vh - 3rem);
  object-fit: contain;
  margin: 0 auto;
}
.lightbox-close {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 50%;
  background: #f3f4f6;
  cursor: pointer;
  font-size: 1.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
}
.lightbox-close:hover {
  background: #e5e7eb;
}
.filter-row {
  margin-bottom: 1rem;
}
.filter-row select {
  padding: 0.45rem 0.75rem;
}
.loading, .empty {
  padding: 2rem;
  text-align: center;
  color: #888;
}
.btn-sm {
  padding: 0.35rem 0.65rem;
  font-size: 0.82rem;
  margin-right: 0.35rem;
}
.actions {
  white-space: nowrap;
}
.ws-pending { background: #fef3c7; color: #92400e; }
.ws-approved { background: #d1fae5; color: #065f46; }
.ws-rejected { background: #fee2e2; color: #991b1b; }
</style>
