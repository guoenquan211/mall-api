<script setup>
import { ref, onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useUser } from '../store'
import { api } from '../api'
import { toast } from '../components/Toast'

const router = useRouter()
const { user, logout: storeLogout } = useUser()

const activeTab = ref('profile')
const addresses = ref([])
const showAddressModal = ref(false)
const addressForm = reactive({
  id: '',
  name: '',
  phone: '',
  province: '',
  city: '',
  district: '',
  detail: '',
  is_default: false
})
const savingAddress = ref(false)

const orders = ref([])
const loadingOrders = ref(false)

const affiliateSummary = ref(null)
const loadingAffiliate = ref(false)

// Navigation
const switchTab = (tab) => {
  activeTab.value = tab
  if (tab === 'address') {
    loadAddresses()
  } else if (tab === 'order') {
    loadOrders()
  } else if (tab === 'affiliate') {
    loadAffiliate()
  }
}

const handleLogout = () => {
  storeLogout()
  router.push('/login')
}

const loadOrders = async () => {
  if (!user.id) return
  loadingOrders.value = true
  try {
    const res = await api.getOrders({ user_id: user.id })
    if (res.code === 0) {
      // Backend returns paginated object { total, per_page, current_page, last_page, data: [] }
      // or just array depending on implementation. Order.php returns paginate result.
      orders.value = res.data.data ? res.data.data : res.data
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingOrders.value = false
  }
}

// Address Management
const loadAddresses = async () => {
  if (!user.id) return
  try {
    const res = await api.getUserAddresses(user.id)
    if (res.code === 0) {
      // Backend returns paginated object { total, per_page, current_page, last_page, data: [] }
      // or just array depending on implementation.
      addresses.value = res.data.data ? res.data.data : res.data
    }
  } catch (e) {
    console.error(e)
  }
}

const openAddressModal = (address = null) => {
  if (address) {
    Object.assign(addressForm, address)
    // Fix boolean for checkbox
    addressForm.is_default = !!address.is_default
  } else {
    // Reset form
    Object.assign(addressForm, {
      id: '',
      name: '',
      phone: '',
      province: '',
      city: '',
      district: '',
      detail: '',
      is_default: false
    })
  }
  showAddressModal.value = true
}

const saveAddress = async () => {
  if (!addressForm.name || !addressForm.phone || !addressForm.detail) {
    toast.warning('请填写完整地址信息')
    return
  }
  
  savingAddress.value = true
  try {
    const payload = { ...addressForm, user_id: user.id }
    // Convert boolean to int for backend if needed, or backend handles it
    payload.is_default = payload.is_default ? 1 : 0
    
    const res = await api.saveUserAddress(payload)
    if (res.code === 0) {
      await loadAddresses()
      showAddressModal.value = false
      toast.success('地址保存成功')
    } else {
      toast.error(res.msg || '保存失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('系统错误')
  } finally {
    savingAddress.value = false
  }
}

const confirmingDelete = ref(null)

const deleteAddress = async (id) => {
  if (confirmingDelete.value !== id) {
    confirmingDelete.value = id
    toast.info('再次点击以确认删除')
    setTimeout(() => confirmingDelete.value = null, 3000)
    return
  }
  confirmingDelete.value = null

  try {
    const res = await api.deleteUserAddress(id)
    if (res.code === 0) {
      loadAddresses()
      toast.success('地址删除成功')
    } else {
      toast.error(res.msg || '删除失败')
    }
  } catch (e) {
    console.error(e)
  }
}

const formatStatus = (status) => {
  const map = {
    0: '待付款',
    1: '待发货',
    2: '已发货',
    3: '已完成',
    4: '已取消'
  }
  return map[status] || '未知状态'
}

const loadAffiliate = async () => {
  if (!user.id) return
  loadingAffiliate.value = true
  try {
    const res = await api.getUserAffiliateSummary(user.id)
    if (res.code === 0) {
      affiliateSummary.value = res.data
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingAffiliate.value = false
  }
}

const levelLabel = (lv) => {
  const c = affiliateSummary.value?.config
  if (!c) return `L${lv}`
  if (lv >= 3) return c.level3_name
  if (lv >= 2) return c.level2_name
  if (lv >= 1) return c.level1_name
  return '普通会员'
}

const shopInviteUrl = () => {
  if (typeof window === 'undefined' || !affiliateSummary.value?.invite_code) return ''
  return `${window.location.origin}/?ref=${encodeURIComponent(affiliateSummary.value.invite_code)}`
}

const productInviteExample = () => {
  if (typeof window === 'undefined' || !affiliateSummary.value?.invite_code) return ''
  return `${window.location.origin}/product/1?ref=${encodeURIComponent(affiliateSummary.value.invite_code)}`
}

const qrUrl = () => {
  const u = shopInviteUrl()
  if (!u) return ''
  return `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(u)}`
}

const copyText = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    toast.success('已复制')
  } catch {
    toast.error('复制失败')
  }
}

onMounted(() => {
  if (!user.loggedIn) {
    router.push('/login')
  } else {
    // Initial load
    if (activeTab.value === 'address') loadAddresses()
    if (activeTab.value === 'order') loadOrders()
    if (activeTab.value === 'affiliate') loadAffiliate()
  }
})
</script>

<template>
  <div class="user-center-page">
    <div class="container">
      <div class="sidebar">
        <div class="user-card">
          <div class="avatar">
            {{ user.name ? user.name[0].toUpperCase() : 'C' }}
          </div>
          <div class="info">
            <h3>{{ user.nickname || '会员' }}</h3>
            <div class="points-badge">
              <i class="ri-copper-coin-line"></i> {{ user.points || 0 }} 积分
            </div>
          </div>
        </div>
        
        <div class="divider-line"></div>

        <nav class="nav-menu">
          <a @click="switchTab('order')" :class="{ active: activeTab === 'order' }">
            我的订单
          </a>
          <a @click="switchTab('favorites')" :class="{ active: activeTab === 'favorites' }">
            收藏夹
          </a>
          <a @click="switchTab('address')" :class="{ active: activeTab === 'address' }">
            收货地址
          </a>
          <a @click="switchTab('affiliate')" :class="{ active: activeTab === 'affiliate' }">
            推广与佣金
          </a>
          <a @click="switchTab('profile')" :class="{ active: activeTab === 'profile' }">
            个人设置
          </a>
        </nav>
      </div>

      <div class="content-area">
        <!-- Affiliate Tab -->
        <div v-if="activeTab === 'affiliate'" class="tab-pane">
          <div class="pane-header">
            <h2>推广与佣金</h2>
          </div>
          <div v-if="loadingAffiliate" class="loading-state">加载中...</div>
          <div v-else-if="affiliateSummary" class="affiliate-pane">
            <p class="aff-line">当前等级：<strong>{{ levelLabel(affiliateSummary.affiliate_level) }}</strong>（数值 {{ affiliateSummary.affiliate_level }}）</p>
            <p class="aff-line">邀请码：<code>{{ affiliateSummary.invite_code }}</code></p>
            <div class="aff-actions">
              <button type="button" class="btn-primary" @click="copyText(shopInviteUrl())">复制首页推广链接</button>
              <button type="button" class="btn-secondary" @click="copyText(productInviteExample())">复制商品链接示例</button>
            </div>
            <div class="qr-block" v-if="qrUrl()">
              <p>扫码访问店铺推广链接（含邀请码）</p>
              <img :src="qrUrl()" alt="Invite QR" width="220" height="220" />
            </div>
            <div class="commission-grid">
              <div><span>待解锁佣金</span><b>{{ affiliateSummary.commission_pending?.toFixed?.(2) ?? affiliateSummary.commission_pending }} {{ affiliateSummary.config?.currency_suffix }}</b></div>
              <div><span>可结算佣金</span><b>{{ affiliateSummary.commission_available?.toFixed?.(2) ?? affiliateSummary.commission_available }} {{ affiliateSummary.config?.currency_suffix }}</b></div>
              <div><span>已结算佣金</span><b>{{ affiliateSummary.commission_settled?.toFixed?.(2) ?? affiliateSummary.commission_settled }} {{ affiliateSummary.config?.currency_suffix }}</b></div>
            </div>
            <div class="aff-copy" v-if="affiliateSummary.config">
              <h4>奖励说明</h4>
              <pre>{{ affiliateSummary.config.reward_rules_text }}</pre>
              <h4>对外宣传</h4>
              <pre>{{ affiliateSummary.config.public_slogans_text }}</pre>
            </div>
          </div>
          <div v-else class="empty-state">无法加载推广数据（请确认已执行数据库迁移）</div>
        </div>

        <!-- Profile Tab -->
        <div v-if="activeTab === 'profile'" class="tab-pane">
          <div class="pane-header">
            <h2>个人设置</h2>
          </div>
          <div class="profile-info">
            <div class="info-item">
              <label>用户名</label>
              <span>{{ user.username }}</span>
            </div>
            <div class="info-item">
              <label>昵称</label>
              <span>{{ user.nickname || '-' }}</span>
            </div>
            <div class="info-item">
              <label>手机号</label>
              <span>{{ user.phone || '-' }}</span>
            </div>
            <div class="info-item">
              <label>邮箱</label>
              <span>{{ user.email || '-' }}</span>
            </div>
          </div>
          
          <div class="logout-section">
             <button @click="handleLogout" class="btn-logout-large">退出登录</button>
          </div>
        </div>

        <!-- Favorites Tab (Placeholder) -->
        <div v-if="activeTab === 'favorites'" class="tab-pane">
          <div class="pane-header">
            <h2>收藏夹</h2>
          </div>
          <div class="empty-state">
            <i class="ri-heart-line"></i>
            <p>暂无收藏商品</p>
          </div>
        </div>



        <!-- Address Tab -->
        <div v-if="activeTab === 'address'" class="tab-pane">
          <div class="pane-header">
            <h2>收货地址</h2>
            <button class="btn-primary" @click="openAddressModal()">新增地址</button>
          </div>
          
          <div class="address-list">
            <div v-for="addr in addresses" :key="addr.id" class="address-card">
              <div class="addr-header">
                <span class="name">{{ addr.name }}</span>
                <span class="phone">{{ addr.phone }}</span>
                <span v-if="addr.is_default" class="tag-default">默认</span>
              </div>
              <div class="addr-body">
                {{ addr.province }} {{ addr.city }} {{ addr.district }} {{ addr.detail }}
              </div>
              <div class="addr-actions">
                <button @click="openAddressModal(addr)">编辑</button>
                <button @click="deleteAddress(addr.id)" class="text-danger">删除</button>
              </div>
            </div>
            <div v-if="addresses.length === 0" class="empty-state">
              暂无收货地址
            </div>
          </div>
        </div>

        <!-- Order Tab -->
        <div v-if="activeTab === 'order'" class="tab-pane">
          <h2>我的订单</h2>
          <div v-if="loadingOrders" class="loading-state">加载中...</div>
          <div v-else-if="orders.length === 0" class="empty-state">
            暂无订单记录
          </div>
          <div v-else class="order-list">
            <div v-for="order in orders" :key="order.id" class="order-card">
              <div class="order-header">
                <span class="order-no">订单号：{{ order.order_no }}</span>
                <span class="order-status" :class="'status-' + order.status">
                  {{ ['待支付', '待发货', '已发货', '已完成', '已取消'][order.status] }}
                </span>
              </div>
              <div class="order-items">
                <div v-for="item in order.items" :key="item.id" class="order-item">
                  <img :src="item.product_image" class="item-thumb" />
                  <div class="item-info">
                    <h4>{{ item.product_name }}</h4>
                    <p class="variant-text" v-if="item.product_variant_data">{{ JSON.parse(item.product_variant_data).name }}</p>
                    <div class="item-meta">
                      <span class="price">¥{{ item.price }}</span>
                      <span class="qty">x{{ item.quantity }}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div class="order-footer">
                <div class="express-info" v-if="order.express_no">
                  <p>物流：{{ order.express_company }} ({{ order.express_no }})</p>
                </div>
                <div class="total-price">
                  <span>共 {{ order.items.length }} 件商品</span>
                  <span class="amount">实付：¥{{ order.total_amount }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Address Modal -->
    <div v-if="showAddressModal" class="modal-overlay">
      <div class="modal-content">
        <h3>{{ addressForm.id ? '编辑地址' : '新增地址' }}</h3>
        <div class="form-group">
          <label>收货人</label>
          <input v-model="addressForm.name" type="text" placeholder="姓名">
        </div>
        <div class="form-group">
          <label>联系电话</label>
          <input v-model="addressForm.phone" type="text" placeholder="手机号">
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>省</label>
            <input v-model="addressForm.province" type="text" placeholder="省份">
          </div>
          <div class="form-group">
            <label>市</label>
            <input v-model="addressForm.city" type="text" placeholder="城市">
          </div>
          <div class="form-group">
            <label>区/县</label>
            <input v-model="addressForm.district" type="text" placeholder="区县">
          </div>
        </div>
        <div class="form-group">
          <label>详细地址</label>
          <textarea v-model="addressForm.detail" placeholder="街道门牌号"></textarea>
        </div>
        <div class="form-checkbox">
          <input type="checkbox" id="isDefault" v-model="addressForm.is_default">
          <label for="isDefault">设为默认地址</label>
        </div>
        <div class="modal-actions">
          <button @click="showAddressModal = false" class="btn-cancel">取消</button>
          <button @click="saveAddress" class="btn-primary" :disabled="savingAddress">
            {{ savingAddress ? '保存中...' : '保存' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.user-center-page {
  padding: 4rem 2rem;
  max-width: 1200px;
  margin: 0 auto;
  min-height: 80vh;
  background-color: var(--bg-color);
}

.container {
  display: flex;
  gap: 3rem;
  align-items: flex-start;
}

/* Sidebar Styles - Restored */
.sidebar {
  width: 280px;
  background: #fff;
  border: 1px solid var(--border-color);
  padding: 3rem 0;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.user-card {
  text-align: center;
  margin-bottom: 2rem;
  padding: 0 2rem;
  width: 100%;
  box-sizing: border-box;
  border-bottom: none;
}

.avatar {
  width: 100px;
  height: 100px;
  background: #fff;
  color: var(--text-primary);
  border: 1px solid #ddd;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2.5rem;
  margin: 0 auto 1.5rem;
  font-family: var(--font-serif);
}

.info h3 {
  font-family: var(--font-serif);
  font-size: 1.2rem;
  font-weight: normal;
  margin: 0 0 1rem 0;
  color: var(--text-primary);
}

.points-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: linear-gradient(135deg, #C1A366, #A68B50);
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.85rem;
}

.divider-line {
  width: 60%;
  height: 1px;
  background-color: #eee;
  margin: 0 auto 2rem;
}

.nav-menu {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.nav-menu a {
  display: block;
  padding: 1rem 0;
  color: var(--text-secondary);
  cursor: pointer;
  text-align: center;
  transition: all 0.3s;
  font-family: var(--font-sans);
  font-size: 1rem;
}

.nav-menu a:hover {
  color: var(--primary-color);
  background: transparent;
}

.nav-menu a.active {
  background: #F7F7F7;
  color: var(--text-primary);
  font-weight: 500;
}

/* Content Area */
.content-area {
  flex: 1;
  padding-top: 1rem;
}

.tab-pane h2 {
  font-family: var(--font-serif);
  font-size: 1.8rem;
  margin-bottom: 1.5rem;
  font-weight: normal;
  border-bottom: 1px solid #eee;
  padding-bottom: 1rem;
}

.profile-info {
  background: #fff;
  padding: 2rem;
  border: 1px solid var(--border-color);
}

.profile-info .info-item {
  display: flex;
  padding: 1rem 0;
  border-bottom: 1px solid #f9f9f9;
}
.profile-info label {
  width: 100px;
  color: #999;
}

.logout-section {
  margin-top: 3rem;
  text-align: center;
}

.btn-logout-large {
  padding: 0.8rem 3rem;
  border: 1px solid #ddd;
  background: white;
  color: #666;
  cursor: pointer;
  transition: all 0.3s;
}
.btn-logout-large:hover {
  border-color: #f56c6c;
  color: #f56c6c;
}

/* Address & Order Lists Styles */
.address-card, .order-card {
  background: #fff;
  border: 1px solid var(--border-color);
  border-radius: 0;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.addr-header {
  display: flex;
  gap: 1rem;
  align-items: center;
  margin-bottom: 0.5rem;
}
.name { font-weight: bold; font-size: 1.1rem; }
.tag-default {
  background: #e6fffa;
  color: #00b894;
  padding: 2px 6px;
  font-size: 12px;
}
.addr-body { color: #666; margin-bottom: 1rem; }
.addr-actions {
  display: flex;
  gap: 1rem;
}
.addr-actions button {
  background: none;
  border: none;
  color: #999;
  cursor: pointer;
  padding: 0;
  font-size: 0.9rem;
}
.addr-actions button:hover { color: var(--accent-color); }
.addr-actions .text-danger:hover { color: #f56c6c; }

/* Order List Styles */
.order-header {
  display: flex;
  justify-content: space-between;
  padding-bottom: 1rem;
  border-bottom: 1px solid #f5f5f5;
  margin-bottom: 1rem;
  color: #666;
  background: transparent;
}
.order-status { font-weight: bold; }
.status-0 { color: #e6a23c; }
.status-1 { color: #409eff; }
.status-2 { color: #67c23a; }
.status-3 { color: #909399; }

.order-items { padding: 1rem 0; }
.order-item {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}
.item-thumb {
  width: 80px;
  height: 80px;
  border-radius: 0;
  object-fit: cover;
  background: #f5f5f5;
}
.item-info { flex: 1; }
.item-info h4 {
  margin: 0 0 0.5rem;
  font-size: 1rem;
  font-weight: 500;
  font-family: var(--font-serif);
}
.variant-text {
  font-size: 0.85rem;
  color: #888;
  margin: 0 0 0.5rem;
}
.item-meta {
  display: flex;
  gap: 1rem;
  font-size: 0.9rem;
  color: #666;
}
.order-footer {
  padding-top: 1rem;
  border-top: 1px solid #f5f5f5;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: transparent;
}
.express-info {
  font-size: 0.85rem;
  color: #666;
  background: #f9f9f9;
  padding: 4px 8px;
}
.total-price {
  font-size: 0.95rem;
}
.total-price .amount {
  font-weight: bold;
  font-size: 1.1rem;
  color: #C1A366;
  margin-left: 0.5rem;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0; left: 0; width: 100%; height: 100%;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}
.modal-content {
  background: white;
  padding: 2rem;
  width: 90%;
  max-width: 500px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  border-radius: 0;
}
.modal-content h3 {
  font-family: var(--font-serif);
  margin-bottom: 1.5rem;
  text-align: center;
}
.form-group { margin-bottom: 1rem; }
.form-group label { display: block; margin-bottom: 0.5rem; color: #666; }
.form-group input, .form-group textarea {
  width: 100%;
  padding: 0.8rem;
  border: 1px solid #ddd;
  font-family: var(--font-sans);
  box-sizing: border-box;
  border-radius: 0;
}
.form-row { display: flex; gap: 1rem; }
.form-row .form-group { flex: 1; }
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
}
.btn-primary {
  background: var(--primary-color);
  color: white;
  border: none;
  padding: 0.6rem 1.5rem;
  cursor: pointer;
  border-radius: 0;
}
.btn-cancel {
  background: #f5f5f5;
  border: none;
  padding: 0.6rem 1.5rem;
  cursor: pointer;
  border-radius: 0;
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 4rem 0;
  color: #999;
}
.empty-state i {
  font-size: 3rem;
  margin-bottom: 1rem;
  display: block;
  color: #ddd;
}
.loading-state { text-align: center; padding: 2rem; color: #999; }

.affiliate-pane { max-width: 640px; }
.aff-line { margin: 0.5rem 0; }
.aff-line code { background: #f5f5f5; padding: 0.15rem 0.4rem; }
.aff-actions { display: flex; flex-wrap: wrap; gap: 0.75rem; margin: 1rem 0; }
.btn-secondary {
  background: #f5f5f5;
  border: 1px solid #ddd;
  color: #333;
  padding: 0.6rem 1.25rem;
  cursor: pointer;
}
.qr-block { margin: 1.5rem 0; text-align: center; }
.qr-block img { border: 1px solid #eee; }
.commission-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 1rem;
  margin: 1rem 0;
}
.commission-grid div {
  background: #faf8f5;
  border: 1px solid var(--border-color, #e8ddd4);
  padding: 1rem;
  text-align: center;
}
.commission-grid span { display: block; font-size: 0.85rem; color: #666; margin-bottom: 0.35rem; }
.aff-copy pre {
  white-space: pre-wrap;
  background: #fafafa;
  padding: 1rem;
  border: 1px solid #eee;
  font-size: 0.9rem;
}

/* Responsive */
@media (max-width: 768px) {
  .container {
    flex-direction: column;
    gap: 0;
  }
  .sidebar {
    width: 100%;
    margin-bottom: 2rem;
    border: none;
    padding: 2rem 0;
    background: transparent;
  }
  .user-card {
    background: #fff;
    padding: 2rem;
    border: 1px solid var(--border-color);
  }
  .nav-menu {
    background: #fff;
    border: 1px solid var(--border-color);
    margin-top: 1rem;
  }
  .content-area {
    width: 100%;
    padding: 0;
  }
}
</style>
