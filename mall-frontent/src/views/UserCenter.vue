<script setup>
import { ref, onMounted, reactive, nextTick, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useUser } from '../store'
import { api } from '../api'
import { toast } from '../components/Toast'
import { pickLocalized } from '../utils/localeDisplay.js'
import { formatPrice } from '../utils/formatMoney.js'
import { resolveStockImage } from '../utils/resolveStockImage.js'
import { getApiLocale } from '../i18n/localeStorage.js'

const { t, locale } = useI18n()
const router = useRouter()
const route = useRoute()
const { user, logout: storeLogout, removeFavorite, updateProfile } = useUser()

const activeTab = ref('order')
const navMenuRef = ref(null)
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

const safeTrackingUrl = (order) => {
  const raw = String(order?.express_tracking_url || '').trim()
  if (!raw) return ''
  try {
    const url = new URL(raw)
    return ['http:', 'https:'].includes(url.protocol) ? url.href : ''
  } catch {
    return ''
  }
}
const loadingOrders = ref(false)

const affiliateSummary = ref(null)
const loadingAffiliate = ref(false)

const walletFlows = ref([])
const walletSummary = ref(null)
const walletTotal = ref(0)
const walletPage = ref(1)
const walletFilterType = ref('all')
const loadingWallet = ref(false)
const walletFilterOptions = [
  { value: 'all', labelKey: 'user.flowFilterAll' },
  { value: 'commission', labelKey: 'user.flowFilterCommission' },
  { value: 'order', labelKey: 'user.flowFilterOrder' },
]

const favoriteProducts = ref([])
const loadingFavorites = ref(false)

const profileForm = reactive({
  username: '',
  nickname: '',
  phone: '',
  email: '',
})
const savingProfile = ref(false)
const loadingProfile = ref(false)
const profileEditing = ref(false)

const navItems = [
  { tab: 'order', icon: 'ri-shopping-bag-3-line', labelKey: 'user.myOrders' },
  { tab: 'favorites', icon: 'ri-heart-line', labelKey: 'user.favorites' },
  { tab: 'address', icon: 'ri-map-pin-line', labelKey: 'user.addresses' },
  { tab: 'affiliate', icon: 'ri-share-forward-line', labelKey: 'user.affiliate' },
  { tab: 'wallet', icon: 'ri-wallet-3-line', labelKey: 'user.wallet' },
  { tab: 'profile', icon: 'ri-user-settings-line', labelKey: 'user.profile' },
]

const profileDisplay = (val) => {
  const s = val != null ? String(val).trim() : ''
  return s || '—'
}

const startEditProfile = () => {
  syncProfileFormFromUser()
  profileEditing.value = true
}

const cancelEditProfile = () => {
  syncProfileFormFromUser()
  profileEditing.value = false
}

// Navigation
const switchTab = async (tab) => {
  activeTab.value = tab
  if (tab === 'address') {
    loadAddresses()
  } else if (tab === 'order') {
    loadOrders()
  } else if (tab === 'affiliate') {
    loadAffiliate()
  } else if (tab === 'wallet') {
    await loadWalletFlows(1)
    await loadGcashWallet()
  } else if (tab === 'favorites') {
    loadFavorites()
  } else if (tab === 'profile') {
    profileEditing.value = false
    loadProfile()
  }
  await nextTick()
  const activeEl = navMenuRef.value?.querySelector('.nav-tab.active')
  activeEl?.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' })
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
    toast.warning(t('user.addressIncomplete'))
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
      toast.success(t('user.addressSaved'))
    } else {
      toast.error(res.msg || t('user.saveFailed'))
    }
  } catch (e) {
    console.error(e)
    toast.error(t('common.systemError'))
  } finally {
    savingAddress.value = false
  }
}

const confirmingDelete = ref(null)
const confirmingOrderDelete = ref(null)

const deleteAddress = async (id) => {
  if (confirmingDelete.value !== id) {
    confirmingDelete.value = id
    toast.info(t('common.confirmDeleteAgain'))
    setTimeout(() => confirmingDelete.value = null, 3000)
    return
  }
  confirmingDelete.value = null

  try {
    const res = await api.deleteUserAddress(id)
    if (res.code === 0) {
      loadAddresses()
      toast.success(t('user.addressDeleted'))
    } else {
      toast.error(res.msg || t('user.deleteFailed'))
    }
  } catch (e) {
    console.error(e)
  }
}

const formatStatus = (status) => {
  const key = `user.orderStatus.${status}`
  const translated = t(key)
  return translated === key ? t('user.orderStatus.unknown') : translated
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

const syncProfileFormFromUser = () => {
  profileForm.username = user.username || ''
  profileForm.nickname = user.nickname || ''
  profileForm.phone = user.phone || ''
  profileForm.email = user.email || ''
}

const applyProfileToStore = (data) => {
  updateProfile({
    username: data.username,
    nickname: data.nickname,
    name: data.nickname || data.username,
    phone: data.phone || '',
    email: data.email || '',
  })
}

const loadProfile = async () => {
  if (!user.id) return
  syncProfileFormFromUser()
  loadingProfile.value = true
  try {
    const res = await api.getUserInfo(user.id)
    if (res.code === 0 && res.data) {
      applyProfileToStore(res.data)
      syncProfileFormFromUser()
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingProfile.value = false
  }
}

const saveProfile = async () => {
  if (!user.id) return
  const username = profileForm.username.trim()
  if (!username) {
    toast.warning(t('user.profileUsernameRequired'))
    return
  }
  const email = profileForm.email.trim()
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    toast.warning(t('user.profileEmailInvalid'))
    return
  }
  savingProfile.value = true
  try {
    const res = await api.updateUserProfile({
      user_id: user.id,
      username,
      nickname: profileForm.nickname.trim(),
      phone: profileForm.phone.trim(),
      email,
    })
    if (res.code === 0) {
      applyProfileToStore(res.data)
      syncProfileFormFromUser()
      profileEditing.value = false
      toast.success(res.msg || t('user.profileSaved'))
    } else {
      toast.error(res.msg || t('user.saveFailed'))
    }
  } catch (e) {
    console.error(e)
    toast.error(t('common.systemError'))
  } finally {
    savingProfile.value = false
  }
}

const loadFavorites = async () => {
  const ids = (user.favorites || []).map(String)
  if (!ids.length) {
    favoriteProducts.value = []
    return
  }
  loadingFavorites.value = true
  try {
    const res = await api.getProducts({ status: 1, limit: 200 })
    let list = res.data?.list ?? res.data?.data ?? res.data ?? []
    if (!Array.isArray(list)) list = []
    const order = new Map(ids.map((id, i) => [id, i]))
    favoriteProducts.value = list
      .filter((p) => order.has(String(p.id)))
      .sort((a, b) => order.get(String(a.id)) - order.get(String(b.id)))
  } catch (e) {
    console.error(e)
    favoriteProducts.value = []
  } finally {
    loadingFavorites.value = false
  }
}

const favoriteDisplayName = (p) => pickLocalized(locale.value, p.name, p.name_en)

const handleRemoveFavorite = (productId) => {
  removeFavorite(productId)
  favoriteProducts.value = favoriteProducts.value.filter((p) => String(p.id) !== String(productId))
  toast.success(t('productDetail.favoriteRemoved'))
}

const setWalletFilter = (type) => {
  if (walletFilterType.value === type) return
  walletFilterType.value = type
  loadWalletFlows(1)
}

const loadWalletFlows = async (page = 1) => {
  if (!user.id) return
  loadingWallet.value = true
  walletPage.value = page
  try {
    const res = await api.getUserWalletFlows(user.id, {
      page: String(page),
      limit: '20',
      type: walletFilterType.value,
    })
    if (res.code === 0) {
      walletFlows.value = res.data?.list ?? []
      walletSummary.value = res.data?.summary ?? null
      walletTotal.value = res.data?.total ?? 0
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingWallet.value = false
  }
}

const formatFlowTime = (ts) => {
  if (!ts) return '-'
  const d = new Date(ts * 1000)
  return d.toLocaleString()
}

const flowStatusLabel = (row) => {
  if (row.category === 'order') {
    const m = { paid: t('user.flowOrderPaid'), shipped: t('user.flowOrderShipped'), completed: t('user.flowOrderCompleted'), cancelled: t('user.flowOrderCancelled') }
    return m[row.status] || row.status
  }
  const m = { pending: t('user.commissionPending'), available: t('user.commissionAvailable'), settled: t('user.commissionSettled') }
  return m[row.status] || row.status
}

const walletTotalPages = () => Math.max(1, Math.ceil(walletTotal.value / 20))

const gcashSummary = ref({
  commission_available: 0,
  withdrawal_locked: 0,
  withdrawable: 0,
  currency_suffix: 'P',
  gcash_number: '',
  gcash_name: '',
})
const gcashLoadError = ref('')
const gcashBindForm = reactive({ gcash_number: '', gcash_name: '' })
const myWithdrawals = ref([])
const withdrawAmount = ref('')
const savingGcashBind = ref(false)
const submittingWithdraw = ref(false)

const defaultWalletSummary = () => ({
  currency_suffix: 'P',
  total_income: 0,
  total_spent: 0,
  commission_available: 0,
  commission_pending: 0,
  withdrawable: 0,
})

const displayWalletSummary = computed(() => walletSummary.value || defaultWalletSummary())

const loadGcashWallet = async () => {
  if (!user.id) return
  gcashLoadError.value = ''
  try {
    const [sumRes, wdRes] = await Promise.all([
      api.getGcashWalletSummary(user.id),
      api.getMyWithdrawals(user.id),
    ])
    if (sumRes.code === 0) {
      gcashSummary.value = { ...gcashSummary.value, ...sumRes.data }
      gcashBindForm.gcash_number = sumRes.data.gcash_number || ''
      gcashBindForm.gcash_name = sumRes.data.gcash_name || ''
    } else {
      gcashLoadError.value = sumRes.msg || t('user.gcashLoadFail')
    }
    if (wdRes.code === 0) {
      const raw = wdRes.data
      myWithdrawals.value = Array.isArray(raw) ? raw : raw?.data ?? []
    }
  } catch (e) {
    console.error(e)
    gcashLoadError.value = t('user.gcashLoadFail')
  }
}

const saveGcashBind = async () => {
  if (!gcashBindForm.gcash_number?.trim() || !gcashBindForm.gcash_name?.trim()) {
    toast.warning(t('user.gcashBindRequired'))
    return
  }
  savingGcashBind.value = true
  try {
    const res = await api.bindGcash({
      user_id: user.id,
      gcash_number: gcashBindForm.gcash_number.trim(),
      gcash_name: gcashBindForm.gcash_name.trim(),
    })
    if (res.code === 0) {
      toast.success(res.msg || t('user.gcashBindOk'))
      await loadGcashWallet()
      loadWalletFlows(walletPage.value)
    } else {
      toast.error(res.msg || t('user.saveFailed'))
    }
  } catch (e) {
    console.error(e)
    toast.error(t('common.systemError'))
  } finally {
    savingGcashBind.value = false
  }
}

const submitWithdraw = async () => {
  const amt = parseFloat(withdrawAmount.value)
  if (!amt || amt <= 0) {
    toast.warning(t('user.withdrawAmountInvalid'))
    return
  }
  if (!gcashSummary.value?.gcash_number) {
    toast.warning(t('user.gcashBindFirst'))
    return
  }
  submittingWithdraw.value = true
  try {
    const res = await api.createWithdrawal({ user_id: user.id, amount: amt })
    if (res.code === 0) {
      toast.success(res.msg || t('user.withdrawSubmitted'))
      withdrawAmount.value = ''
      await loadGcashWallet()
      loadWalletFlows(walletPage.value)
    } else {
      toast.error(res.msg || t('user.withdrawFail'))
    }
  } catch (e) {
    console.error(e)
    toast.error(t('common.systemError'))
  } finally {
    submittingWithdraw.value = false
  }
}

const withdrawalStatusLabel = (status) => {
  const m = {
    pending: t('user.withdrawPending'),
    approved: t('user.withdrawApproved'),
    rejected: t('user.withdrawRejected'),
  }
  return m[status] || status
}

const paymentStatusLabel = (order) => {
  const ps = order.payment_status || 'pending'
  const m = {
    pending: t('user.payStatusPending'),
    user_confirmed: t('user.payStatusReview'),
    approved: t('user.payStatusApproved'),
    rejected: t('user.payStatusRejected'),
  }
  return m[ps] || ps
}

const canPayOrder = (order) =>
  Number(order.status) === 0 && ['pending', 'rejected'].includes(order.payment_status || 'pending')

const canDeleteOrder = (order) => {
  const status = Number(order.status)
  const ps = order.payment_status || 'pending'
  if (status === 4) return true
  return status === 0 && ['pending', 'rejected'].includes(ps)
}

const deleteOrder = async (order) => {
  if (!user.id || !order?.id) return
  if (confirmingOrderDelete.value !== order.id) {
    confirmingOrderDelete.value = order.id
    toast.info(t('common.confirmDeleteAgain'))
    setTimeout(() => {
      if (confirmingOrderDelete.value === order.id) confirmingOrderDelete.value = null
    }, 3000)
    return
  }
  confirmingOrderDelete.value = null

  try {
    const res = await api.deleteUserOrder(user.id, order.id)
    if (res.code === 0) {
      orders.value = orders.value.filter((o) => o.id !== order.id)
      toast.success(t('user.orderDeleted'))
    } else {
      toast.error(res.msg || t('user.deleteFailed'))
    }
  } catch (e) {
    console.error(e)
    toast.error(t('user.deleteFailed'))
  }
}

const goPayOrder = (order) => router.push(`/order/pay/${order.id}`)

const levelLabel = (lv) => {
  const c = affiliateSummary.value?.config
  if (!c) return `L${lv}`
  if (lv >= 3) return pickLocalized(locale.value, c.level3_name, c.level3_name_en)
  if (lv >= 2) return pickLocalized(locale.value, c.level2_name, c.level2_name_en)
  if (lv >= 1) return pickLocalized(locale.value, c.level1_name, c.level1_name_en)
  return t('user.memberLevel')
}

const affiliateConfigText = (zhKey, enKey) => {
  const c = affiliateSummary.value?.config
  if (!c) return ''
  return pickLocalized(locale.value, c[zhKey], c[enKey])
}

const formatDownlineDate = (ts) => {
  const n = Number(ts)
  if (!n || n <= 0 || Number.isNaN(n)) return '—'
  const d = new Date(n * 1000)
  if (Number.isNaN(d.getTime())) return '—'
  return d.toLocaleDateString(getApiLocale() === 'en' ? 'en-US' : 'zh-TW')
}

const downlineLevelLabel = (lv) => levelLabel(lv)

const shopInviteUrl = () => {
  if (typeof window === 'undefined' || !affiliateSummary.value?.invite_code) return ''
  return `${window.location.origin}/?ref=${encodeURIComponent(affiliateSummary.value.invite_code)}`
}

const promotionInviteUrl = (path) => {
  if (typeof window === 'undefined' || !affiliateSummary.value?.invite_code) return ''
  const base = window.location.origin
  const p = path || '/'
  const sep = p.includes('?') ? '&' : '?'
  return `${base}${p}${sep}ref=${encodeURIComponent(affiliateSummary.value.invite_code)}`
}

const promotionProductName = (item) => {
  if (!item) return ''
  return pickLocalized(locale.value, item.name, item.name_en)
}

const formatAffStatMoney = (val) => {
  const n = Number(val)
  if (!Number.isFinite(n)) return '0.00'
  return n.toFixed(2)
}

const qrUrl = () => {
  const u = shopInviteUrl()
  if (!u) return ''
  return `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(u)}`
}

const copyText = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    toast.success(t('common.copyOk'))
  } catch {
    toast.error(t('common.copyFail'))
  }
}

onMounted(() => {
  if (!user.loggedIn) {
    router.push('/login')
  } else {
    const tabQuery = route.query.tab
    if (typeof tabQuery === 'string' && navItems.some((n) => n.tab === tabQuery)) {
      switchTab(tabQuery)
    }
    // Initial load
    if (activeTab.value === 'address') loadAddresses()
    if (activeTab.value === 'order') loadOrders()
    if (activeTab.value === 'affiliate') loadAffiliate()
    if (activeTab.value === 'wallet') {
      loadWalletFlows(1)
      loadGcashWallet()
    }
    if (activeTab.value === 'profile') loadProfile()
  }
})
</script>

<template>
  <div class="user-center-page">
    <div class="container">
      <aside class="sidebar">
        <div class="user-card">
          <div class="avatar-ring">
            <div class="avatar">
              {{ user.name ? user.name[0].toUpperCase() : 'C' }}
            </div>
          </div>
          <div class="info">
            <h3>{{ user.nickname || $t('common.member') }}</h3>
            <p class="user-meta">{{ user.username || '—' }}</p>
            <div class="points-badge">
              <i class="ri-vip-crown-line"></i>
              <span>{{ user.points || 0 }} {{ $t('common.points') }}</span>
            </div>
          </div>
        </div>

        <div class="nav-menu-wrap">
          <nav ref="navMenuRef" class="nav-menu" role="tablist" aria-label="Member center">
            <a
              v-for="item in navItems"
              :key="item.tab"
              role="tab"
              class="nav-tab"
              :class="{ active: activeTab === item.tab }"
              :title="$t(item.labelKey)"
              @click="switchTab(item.tab)"
            >
              <i :class="item.icon" aria-hidden="true"></i>
              <span class="nav-tab-label">{{ $t(item.labelKey) }}</span>
            </a>
          </nav>
        </div>
      </aside>

      <div class="content-area">
        <div class="content-panel">
        <!-- Affiliate Tab -->
        <div v-if="activeTab === 'affiliate'" class="tab-pane">
          <div class="pane-header">
            <h2>{{ $t('user.affiliateTitle') }}</h2>
          </div>
          <div v-if="loadingAffiliate" class="loading-state">{{ $t('common.loading') }}</div>
          <div v-else-if="affiliateSummary" class="affiliate-pane">
            <p class="aff-line">{{ $t('user.currentLevel') }}：<strong>{{ levelLabel(affiliateSummary.affiliate_level) }}</strong>（{{ $t('user.levelValue') }} {{ affiliateSummary.affiliate_level }}）</p>
            <p class="aff-line">{{ $t('user.inviteCode') }}：<code>{{ affiliateSummary.invite_code }}</code></p>
            <div class="aff-actions">
              <button type="button" class="btn-primary" @click="copyText(shopInviteUrl())">{{ $t('user.copyShopLink') }}</button>
            </div>
            <div class="aff-product-links" v-if="affiliateSummary.promotion">
              <h4>{{ $t('user.promotionLinksTitle') }}</h4>
              <p class="aff-product-links-hint">{{ $t('user.promotionLinksHint') }}</p>
              <div class="aff-promo-table-wrap">
                <table class="aff-promo-table">
                  <thead>
                    <tr>
                      <th>{{ $t('user.promotionColProduct') }}</th>
                      <th>{{ $t('user.promotionColClicks') }}</th>
                      <th>{{ $t('user.promotionColOrders') }}</th>
                      <th>{{ $t('user.promotionColCommission') }}</th>
                      <th>{{ $t('user.promotionColLink') }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="item in affiliateSummary.promotion.product_links" :key="item.product_id">
                      <td>
                        <div class="promo-product-cell">
                          <img
                            v-if="item.image"
                            :src="resolveStockImage(item.image)"
                            :alt="promotionProductName(item)"
                            class="promo-thumb"
                            loading="lazy"
                          />
                          <span class="promo-name">{{ promotionProductName(item) }}</span>
                        </div>
                      </td>
                      <td>{{ item.click_count ?? 0 }}</td>
                      <td>{{ item.order_count ?? 0 }}</td>
                      <td>{{ formatAffStatMoney(item.commission_total) }} {{ affiliateSummary.config?.currency_suffix }}</td>
                      <td>
                        <button type="button" class="btn-link" @click="copyText(promotionInviteUrl(item.path))">{{ $t('user.copyLink') }}</button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div class="qr-block" v-if="qrUrl()">
              <p>{{ $t('user.qrHint') }}</p>
              <img :src="qrUrl()" alt="Invite QR" width="220" height="220" />
            </div>
            <div class="commission-grid">
              <div><span>{{ $t('user.commissionPending') }}</span><b>{{ affiliateSummary.commission_pending?.toFixed?.(2) ?? affiliateSummary.commission_pending }} {{ affiliateSummary.config?.currency_suffix }}</b></div>
              <div><span>{{ $t('user.commissionAvailable') }}</span><b>{{ affiliateSummary.commission_available?.toFixed?.(2) ?? affiliateSummary.commission_available }} {{ affiliateSummary.config?.currency_suffix }}</b></div>
              <div><span>{{ $t('user.commissionSettled') }}</span><b>{{ affiliateSummary.commission_settled?.toFixed?.(2) ?? affiliateSummary.commission_settled }} {{ affiliateSummary.config?.currency_suffix }}</b></div>
            </div>
            <div class="aff-progress" v-if="affiliateSummary.progress && affiliateSummary.config">
              <h4>{{ $t('user.upgradeProgress') }}</h4>
              <ul class="aff-progress-list">
                <li v-if="affiliateSummary.affiliate_level < 1">
                  {{ pickLocalized(locale, affiliateSummary.config.level1_name, affiliateSummary.config.level1_name_en) }}（{{ $t('user.level1Either') }}）：
                  <span v-if="affiliateSummary.config.level1_any_order">
                    {{ $t('user.level1AnyOrder') }} {{ affiliateSummary.progress.completed_orders }}/1
                  </span>
                  <span v-if="affiliateSummary.config.level1_any_order && affiliateSummary.config.level1_spend"> · </span>
                  <span v-if="affiliateSummary.config.level1_spend">
                    {{ $t('user.level1Spend') }} {{ affiliateSummary.progress.total_paid_goods }}/{{ affiliateSummary.config.level1_spend }}{{ affiliateSummary.config.currency_suffix }}
                  </span>
                </li>
                <li v-if="affiliateSummary.affiliate_level < 2">
                  {{ pickLocalized(locale, affiliateSummary.config.level2_name, affiliateSummary.config.level2_name_en) }}：
                  {{ $t('user.level2Direct') }} {{ affiliateSummary.progress.direct_l1_count }}/{{ affiliateSummary.config.level2_direct_l1 }}，
                  {{ $t('user.teamPv') }} {{ affiliateSummary.progress.team_pv }}/{{ affiliateSummary.config.level2_team_pv }}
                </li>
                <li v-if="affiliateSummary.affiliate_level < 3">
                  {{ pickLocalized(locale, affiliateSummary.config.level3_name, affiliateSummary.config.level3_name_en) }}：
                  {{ $t('user.level3Direct') }} {{ affiliateSummary.progress.direct_l2_count }}/{{ affiliateSummary.config.level3_direct_l2 }}，
                  {{ $t('user.teamPv') }} {{ affiliateSummary.progress.team_pv }}/{{ affiliateSummary.config.level3_team_pv }}
                </li>
                <li v-if="affiliateSummary.affiliate_level >= 3">{{ $t('user.maxLevelReached') }}</li>
              </ul>
            </div>
            <div class="aff-downline">
              <h4>{{ $t('user.myDownline') }}</h4>
              <p class="aff-downline-meta">
                {{ $t('user.directDownlineCount') }}：<strong>{{ affiliateSummary.progress?.direct_count ?? 0 }}</strong>
                · {{ $t('user.downlineValidCount') }}：<strong>{{ affiliateSummary.progress?.direct_l1_count ?? 0 }}</strong>
              </p>
              <div v-if="affiliateSummary.downline?.length" class="aff-downline-table-wrap">
                <table class="aff-downline-table">
                  <thead>
                    <tr>
                      <th>{{ $t('user.downlineMember') }}</th>
                      <th>{{ $t('user.downlineLevel') }}</th>
                      <th>{{ $t('user.downlineSpend') }}</th>
                      <th>{{ $t('user.downlineJoined') }}</th>
                      <th>{{ $t('user.downlineStatus') }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="m in affiliateSummary.downline" :key="m.id">
                      <td>
                        <span class="downline-name">{{ m.nickname || m.username }}</span>
                        <span class="downline-user">@{{ m.username }}</span>
                      </td>
                      <td>{{ downlineLevelLabel(m.affiliate_level) }}</td>
                      <td>{{ (m.total_paid_goods ?? 0).toFixed?.(2) ?? m.total_paid_goods }} {{ affiliateSummary.config?.currency_suffix }}</td>
                      <td>{{ formatDownlineDate(m.created_at) }}</td>
                      <td>
                        <span class="downline-badge" :class="m.is_valid ? 'valid' : 'pending'">
                          {{ m.is_valid ? $t('user.downlineValid') : $t('user.downlinePending') }}
                        </span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <p v-else class="aff-downline-empty">{{ $t('user.noDownline') }}</p>
            </div>
            <div class="aff-copy" v-if="affiliateSummary.config">
              <h4>{{ $t('user.complianceRules') }}</h4>
              <pre>{{ affiliateConfigText('compliance_rules_text', 'compliance_rules_text_en') }}</pre>
              <h4>{{ $t('user.rewardRules') }}</h4>
              <pre>{{ affiliateConfigText('reward_rules_text', 'reward_rules_text_en') }}</pre>
              <p class="aff-settle-hint">
                {{ $t('user.settlementHint', {
                  days: affiliateSummary.config.after_sale_days,
                  day: affiliateSummary.config.settlement_day,
                }) }}
              </p>
            </div>
          </div>
          <div v-else class="empty-state">{{ $t('user.affiliateLoadFail') }}</div>
        </div>

        <!-- Wallet flows -->
        <div v-if="activeTab === 'wallet'" class="tab-pane wallet-pane">
          <h2 class="wallet-title">{{ $t('user.walletTitle') }}</h2>
          <p class="wallet-intro">{{ $t('user.walletIntro') }}</p>
          <p class="wallet-affiliate-hint">
            {{ $t('user.walletAffiliateHint') }}
            <a href="#" class="wallet-affiliate-link" @click.prevent="switchTab('affiliate')">{{ $t('user.affiliate') }}</a>
          </p>
          <div class="wallet-toolbar">
            <div class="flow-filter-chips" role="tablist" :aria-label="$t('user.walletTitle')">
              <button
                v-for="opt in walletFilterOptions"
                :key="opt.value"
                type="button"
                role="tab"
                class="flow-chip"
                :class="{ active: walletFilterType === opt.value }"
                :aria-selected="walletFilterType === opt.value"
                @click="setWalletFilter(opt.value)"
              >
                {{ $t(opt.labelKey) }}
              </button>
            </div>
          </div>
          <div v-if="loadingWallet" class="loading-state">{{ $t('common.loading') }}</div>
          <template v-else>
            <div class="wallet-summary">
              <div class="wallet-stat wallet-stat--income">
                <span>{{ $t('user.flowTotalIncome') }}</span>
                <b>+{{ displayWalletSummary.total_income }}<em>{{ displayWalletSummary.currency_suffix }}</em></b>
              </div>
              <div class="wallet-stat wallet-stat--spent">
                <span>{{ $t('user.flowTotalSpent') }}</span>
                <b>-{{ displayWalletSummary.total_spent }}<em>{{ displayWalletSummary.currency_suffix }}</em></b>
              </div>
              <div class="wallet-stat wallet-stat--available">
                <span>{{ $t('user.commissionAvailable') }}</span>
                <b>{{ displayWalletSummary.commission_available }}<em>{{ displayWalletSummary.currency_suffix }}</em></b>
              </div>
              <div class="wallet-stat wallet-stat--withdraw">
                <span>{{ $t('user.withdrawable') }}</span>
                <b>{{ displayWalletSummary.withdrawable ?? 0 }}<em>{{ displayWalletSummary.currency_suffix }}</em></b>
              </div>
            </div>

            <section class="gcash-section">
              <p v-if="gcashLoadError" class="gcash-load-error">{{ gcashLoadError }}</p>
              <h3 class="gcash-heading">{{ $t('user.gcashBindTitle') }}</h3>
              <p class="gcash-hint">{{ $t('user.gcashBindHint') }}</p>
              <div class="gcash-form-grid">
                <label>
                  <span>{{ $t('user.gcashNumber') }}</span>
                  <input v-model="gcashBindForm.gcash_number" type="text" :placeholder="$t('user.gcashNumberPh')" />
                </label>
                <label>
                  <span>{{ $t('user.gcashName') }}</span>
                  <input v-model="gcashBindForm.gcash_name" type="text" :placeholder="$t('user.gcashNamePh')" />
                </label>
              </div>
              <button type="button" class="btn-gcash-save" :disabled="savingGcashBind" @click="saveGcashBind">
                {{ savingGcashBind ? $t('common.saving') : $t('user.gcashSaveBind') }}
              </button>

              <h3 class="gcash-heading">{{ $t('user.withdrawTitle') }}</h3>
              <p class="gcash-hint">
                {{ $t('user.withdrawable') }}：
                <strong>{{ gcashSummary.withdrawable }} {{ gcashSummary.currency_suffix }}</strong>
              </p>
              <div class="withdraw-row">
                <input v-model="withdrawAmount" type="number" min="0" step="0.01" :placeholder="$t('user.withdrawAmountPh')" />
                <button type="button" class="btn-withdraw" :disabled="submittingWithdraw" @click="submitWithdraw">
                  {{ submittingWithdraw ? $t('common.saving') : $t('user.withdrawSubmit') }}
                </button>
              </div>

              <div v-if="myWithdrawals.length" class="withdraw-list">
                <div v-for="w in myWithdrawals" :key="w.id" class="withdraw-item">
                  <div class="withdraw-main">
                    <strong>-{{ w.amount }} {{ gcashSummary.currency_suffix }}</strong>
                    <span class="withdraw-status" :class="'ws-' + w.status">{{ withdrawalStatusLabel(w.status) }}</span>
                  </div>
                  <div class="withdraw-sub">{{ w.gcash_number }} · {{ w.gcash_name }}</div>
                  <div class="withdraw-meta">{{ formatFlowTime(w.created_at) }}</div>
                </div>
              </div>
            </section>

            <div v-if="walletFlows.length" class="flow-list">
              <div v-for="row in walletFlows" :key="row.flow_id" class="flow-item" :class="row.direction">
                <div class="flow-main">
                  <strong>{{ row.title }}</strong>
                  <span class="flow-status">{{ flowStatusLabel(row) }}</span>
                </div>
                <div class="flow-sub">{{ row.remark }}</div>
                <div class="flow-meta">
                  <span>{{ formatFlowTime(row.occurred_at) }}</span>
                  <span class="flow-amt" :class="row.direction">{{ row.signed_amount > 0 ? '+' : '' }}{{ row.signed_amount }} {{ row.currency_suffix }}</span>
                </div>
              </div>
            </div>
            <div v-else class="empty-state">
              <p>{{ $t('user.walletEmpty') }}</p>
              <p class="wallet-empty-hint">{{ $t('user.walletEmptyHint') }}</p>
            </div>
            <div class="flow-pager" v-if="walletTotalPages() > 1">
              <button type="button" :disabled="walletPage <= 1" @click="loadWalletFlows(walletPage - 1)">{{ $t('common.prev') }}</button>
              <span>{{ walletPage }} / {{ walletTotalPages() }}</span>
              <button type="button" :disabled="walletPage >= walletTotalPages()" @click="loadWalletFlows(walletPage + 1)">{{ $t('common.next') }}</button>
            </div>
          </template>
        </div>

        <!-- Profile Tab -->
        <div v-if="activeTab === 'profile'" class="tab-pane profile-pane">
          <div class="pane-header profile-pane-header">
            <div class="pane-title-block">
              <h2>{{ $t('user.profileTitle') }}</h2>
              <p class="pane-subtitle">{{ $t('user.profileSubtitle') }}</p>
            </div>
            <button
              v-if="!loadingProfile && !profileEditing"
              type="button"
              class="btn-edit-profile"
              @click="startEditProfile"
            >
              <i class="ri-edit-line" aria-hidden="true"></i>
              {{ $t('user.editProfile') }}
            </button>
          </div>
          <div v-if="loadingProfile" class="loading-state">{{ $t('common.loading') }}</div>
          <div v-else-if="!profileEditing" class="profile-view">
            <div class="profile-info-grid">
              <div class="profile-info-item">
                <span class="profile-info-icon" aria-hidden="true"><i class="ri-user-3-line"></i></span>
                <div class="profile-info-body">
                  <span class="profile-info-label">{{ $t('user.labelUsername') }}</span>
                  <span class="profile-info-value">{{ profileDisplay(user.username) }}</span>
                </div>
              </div>
              <div class="profile-info-item">
                <span class="profile-info-icon" aria-hidden="true"><i class="ri-emotion-line"></i></span>
                <div class="profile-info-body">
                  <span class="profile-info-label">{{ $t('user.labelNickname') }}</span>
                  <span class="profile-info-value">{{ profileDisplay(user.nickname) }}</span>
                </div>
              </div>
              <div class="profile-info-item">
                <span class="profile-info-icon" aria-hidden="true"><i class="ri-smartphone-line"></i></span>
                <div class="profile-info-body">
                  <span class="profile-info-label">{{ $t('user.labelPhone') }}</span>
                  <span class="profile-info-value">{{ profileDisplay(user.phone) }}</span>
                </div>
              </div>
              <div class="profile-info-item">
                <span class="profile-info-icon" aria-hidden="true"><i class="ri-mail-line"></i></span>
                <div class="profile-info-body">
                  <span class="profile-info-label">{{ $t('user.labelEmail') }}</span>
                  <span class="profile-info-value">{{ profileDisplay(user.email) }}</span>
                </div>
              </div>
            </div>
            <div class="profile-card-footer">
              <button type="button" class="btn-logout-inline" @click="handleLogout">
                <i class="ri-logout-box-r-line" aria-hidden="true"></i>
                {{ $t('user.logoutLarge') }}
              </button>
            </div>
          </div>
          <form v-else class="profile-form" @submit.prevent="saveProfile">
            <div class="profile-field">
              <label for="profile-username">{{ $t('user.labelUsername') }}</label>
              <input
                id="profile-username"
                v-model="profileForm.username"
                type="text"
                autocomplete="username"
                :placeholder="$t('user.usernamePh')"
              />
            </div>
            <div class="profile-field">
              <label for="profile-nickname">{{ $t('user.labelNickname') }}</label>
              <input
                id="profile-nickname"
                v-model="profileForm.nickname"
                type="text"
                autocomplete="nickname"
                :placeholder="$t('user.nicknamePh')"
              />
            </div>
            <div class="profile-field">
              <label for="profile-phone">{{ $t('user.labelPhone') }}</label>
              <input
                id="profile-phone"
                v-model="profileForm.phone"
                type="tel"
                autocomplete="tel"
                :placeholder="$t('user.phonePh')"
              />
            </div>
            <div class="profile-field">
              <label for="profile-email">{{ $t('user.labelEmail') }}</label>
              <input
                id="profile-email"
                v-model="profileForm.email"
                type="email"
                autocomplete="email"
                :placeholder="$t('user.emailPh')"
              />
            </div>
            <div class="profile-form-actions">
              <button type="button" class="btn-profile-cancel" :disabled="savingProfile" @click="cancelEditProfile">
                {{ $t('common.cancel') }}
              </button>
              <button type="submit" class="btn-primary" :disabled="savingProfile">
                {{ savingProfile ? $t('common.saving') : $t('user.saveProfile') }}
              </button>
            </div>
          </form>
        </div>

        <!-- Favorites Tab -->
        <div v-if="activeTab === 'favorites'" class="tab-pane">
          <div class="pane-header">
            <h2>{{ $t('user.favoritesTitle') }}</h2>
          </div>
          <div v-if="loadingFavorites" class="loading-state">{{ $t('common.loading') }}</div>
          <div v-else-if="favoriteProducts.length" class="favorites-grid">
            <article v-for="p in favoriteProducts" :key="p.id" class="favorite-card">
              <router-link :to="`/product/${p.id}`" class="favorite-thumb-link">
                <img :src="p.image" :alt="favoriteDisplayName(p)" class="favorite-thumb" loading="lazy" />
              </router-link>
              <div class="favorite-body">
                <router-link :to="`/product/${p.id}`" class="favorite-name">{{ favoriteDisplayName(p) }}</router-link>
                <p class="favorite-price">{{ formatPrice(p.price) }}</p>
                <div class="favorite-actions">
                  <router-link :to="`/product/${p.id}`" class="btn-link">{{ $t('product.viewDetail') }}</router-link>
                  <button type="button" class="btn-link text-danger" @click="handleRemoveFavorite(p.id)">
                    {{ $t('user.removeFavorite') }}
                  </button>
                </div>
              </div>
            </article>
          </div>
          <div v-else class="empty-state">
            <i class="ri-heart-line"></i>
            <p>{{ $t('user.favoritesEmpty') }}</p>
          </div>
        </div>



        <!-- Address Tab -->
        <div v-if="activeTab === 'address'" class="tab-pane">
          <div class="pane-header">
            <h2>{{ $t('user.addressesTitle') }}</h2>
            <button class="btn-primary" @click="openAddressModal()">{{ $t('user.addAddress') }}</button>
          </div>
          
          <div class="address-list">
            <div v-for="addr in addresses" :key="addr.id" class="address-card">
              <div class="addr-header">
                <span class="name">{{ addr.name }}</span>
                <span class="phone">{{ addr.phone }}</span>
                <span v-if="addr.is_default" class="tag-default">{{ $t('common.default') }}</span>
              </div>
              <div class="addr-body">
                {{ addr.province }} {{ addr.city }} {{ addr.district }} {{ addr.detail }}
              </div>
              <div class="addr-actions">
                <button @click="openAddressModal(addr)">{{ $t('common.edit') }}</button>
                <button @click="deleteAddress(addr.id)" class="text-danger">{{ $t('common.delete') }}</button>
              </div>
            </div>
            <div v-if="addresses.length === 0" class="empty-state">
              {{ $t('user.noAddresses') }}
            </div>
          </div>
        </div>

        <!-- Order Tab -->
        <div v-if="activeTab === 'order'" class="tab-pane">
          <h2>{{ $t('user.ordersTitle') }}</h2>
          <div v-if="loadingOrders" class="loading-state">{{ $t('common.loading') }}</div>
          <div v-else-if="orders.length === 0" class="empty-state">
            {{ $t('user.noOrders') }}
          </div>
          <div v-else class="order-list">
            <div v-for="order in orders" :key="order.id" class="order-card">
              <div class="order-header">
                <span class="order-no">{{ $t('user.orderNo') }}：{{ order.order_no }}</span>
                <div class="order-status-group">
                  <span class="order-status" :class="'status-' + order.status">
                    {{ formatStatus(order.status) }}
                  </span>
                  <span v-if="Number(order.status) === 0" class="payment-status">
                    {{ paymentStatusLabel(order) }}
                  </span>
                </div>
              </div>
              <div class="order-items">
                <div v-for="item in order.items" :key="item.id" class="order-item">
                  <img :src="item.product_image" class="item-thumb" />
                  <div class="item-info">
                    <h4>{{ item.product_name }}</h4>
                    <p class="variant-text" v-if="item.product_variant_data">{{ JSON.parse(item.product_variant_data).name }}</p>
                    <div class="item-meta">
                      <span class="price">{{ formatPrice(item.price) }}</span>
                      <span class="qty">x{{ item.quantity }}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div class="order-footer">
                <div class="order-footer-main">
                  <div class="express-info" v-if="order.express_no || safeTrackingUrl(order)">
                    <p v-if="order.express_no">{{ $t('user.express') }}：{{ order.express_company }} ({{ order.express_no }})</p>
                    <a
                      v-if="safeTrackingUrl(order)"
                      class="express-tracking-link"
                      :href="safeTrackingUrl(order)"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <i class="ri-map-pin-time-line" aria-hidden="true"></i>
                      {{ $t('user.viewLiveTracking') }}
                    </a>
                  </div>
                  <div class="total-price">
                    <span>{{ $t('user.itemsCount', { n: order.items.length }) }}</span>
                    <span class="amount">{{ $t('user.orderAmount') }}：{{ formatPrice(order.total_amount) }}</span>
                  </div>
                </div>
                <div class="order-actions">
                  <button
                    v-if="canPayOrder(order)"
                    type="button"
                    class="btn-order-pay"
                    @click="goPayOrder(order)"
                  >
                    {{ $t('user.goPay') }}
                  </button>
                  <button
                    v-if="canDeleteOrder(order)"
                    type="button"
                    class="btn-order-delete"
                    @click="deleteOrder(order)"
                  >
                    {{ confirmingOrderDelete === order.id ? $t('user.confirmDeleteOrder') : $t('user.deleteOrder') }}
                  </button>
                </div>
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
        <h3>{{ addressForm.id ? $t('user.addressModalEdit') : $t('user.addressModalAdd') }}</h3>
        <div class="form-group">
          <label>{{ $t('user.receiver') }}</label>
          <input v-model="addressForm.name" type="text" :placeholder="$t('user.receiverPh')">
        </div>
        <div class="form-group">
          <label>{{ $t('user.phone') }}</label>
          <input v-model="addressForm.phone" type="text" :placeholder="$t('user.phonePh')">
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>{{ $t('user.province') }}</label>
            <input v-model="addressForm.province" type="text" :placeholder="$t('user.provincePh')">
          </div>
          <div class="form-group">
            <label>{{ $t('user.city') }}</label>
            <input v-model="addressForm.city" type="text" :placeholder="$t('user.cityPh')">
          </div>
          <div class="form-group">
            <label>{{ $t('user.district') }}</label>
            <input v-model="addressForm.district" type="text" :placeholder="$t('user.districtPh')">
          </div>
        </div>
        <div class="form-group">
          <label>{{ $t('user.detailAddress') }}</label>
          <textarea v-model="addressForm.detail" :placeholder="$t('user.detailPh')"></textarea>
        </div>
        <div class="form-checkbox">
          <input type="checkbox" id="isDefault" v-model="addressForm.is_default">
          <label for="isDefault">{{ $t('user.setDefault') }}</label>
        </div>
        <div class="modal-actions">
          <button @click="showAddressModal = false" class="btn-cancel">{{ $t('common.cancel') }}</button>
          <button @click="saveAddress" class="btn-primary" :disabled="savingAddress">
            {{ savingAddress ? $t('common.saving') : $t('common.save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.user-center-page {
  padding: 2rem 1.5rem 4rem;
  max-width: 1180px;
  margin: 0 auto;
  min-height: calc(100vh - 80px);
  background: linear-gradient(165deg, #faf6f3 0%, #f3ece8 45%, #faf8f6 100%);
  overflow-x: hidden;
  box-sizing: border-box;
}

.container {
  display: flex;
  gap: 1.75rem;
  align-items: flex-start;
}

.sidebar {
  width: 260px;
  flex-shrink: 0;
  position: sticky;
  top: 96px;
  background: #fff;
  border: 1px solid rgba(61, 43, 31, 0.08);
  border-radius: 16px;
  padding: 1.75rem 0 1.25rem;
  box-shadow: 0 8px 32px rgba(45, 31, 38, 0.06);
}

.user-card {
  text-align: center;
  padding: 0 1.25rem 1.25rem;
  margin-bottom: 0.5rem;
  border-bottom: 1px solid #f2ebe6;
}

.avatar-ring {
  display: inline-flex;
  padding: 3px;
  border-radius: 50%;
  background: linear-gradient(135deg, #d4a574, #c9956a, #8b6914);
  margin-bottom: 1rem;
}

.avatar {
  width: 88px;
  height: 88px;
  background: linear-gradient(145deg, #fff 0%, #faf6f2 100%);
  color: var(--primary-color, #3d2b1f);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-family: var(--font-serif);
}

.info h3 {
  font-family: var(--font-serif);
  font-size: 1.15rem;
  font-weight: 500;
  margin: 0 0 0.25rem;
  color: var(--text-primary);
}

.user-meta {
  margin: 0 0 0.75rem;
  font-size: 0.8rem;
  color: #6b5d56;
}

.points-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  background: linear-gradient(135deg, #c9a066 0%, #a8844f 100%);
  color: #fff;
  padding: 0.35rem 0.85rem;
  border-radius: 999px;
  font-size: 0.78rem;
  box-shadow: 0 2px 8px rgba(168, 132, 79, 0.25);
}

.nav-menu {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  padding: 0.5rem 0.65rem 0;
}

.nav-menu .nav-tab {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  padding: 0.72rem 1rem;
  color: #7a6d66;
  cursor: pointer;
  text-align: left;
  border-radius: 10px;
  transition: background 0.2s, color 0.2s;
  font-size: 0.92rem;
  text-decoration: none;
}

.nav-menu .nav-tab i {
  font-size: 1.1rem;
  opacity: 0.75;
  flex-shrink: 0;
}

.nav-menu .nav-tab:hover {
  color: var(--primary-color, #3d2b1f);
  background: rgba(201, 149, 160, 0.08);
}

.nav-menu .nav-tab.active {
  background: linear-gradient(90deg, rgba(201, 149, 160, 0.18) 0%, rgba(201, 149, 160, 0.06) 100%);
  color: var(--primary-color, #3d2b1f);
  font-weight: 600;
  box-shadow: inset 3px 0 0 var(--accent-color, #c99595);
}

.nav-menu .nav-tab.active i {
  opacity: 1;
  color: var(--accent-color, #b87a7a);
}

.content-area {
  flex: 1;
  min-width: 0;
}

.content-panel {
  background: #fff;
  border: 1px solid rgba(61, 43, 31, 0.08);
  border-radius: 16px;
  padding: 2rem 2.25rem 2.5rem;
  box-shadow: 0 8px 32px rgba(45, 31, 38, 0.05);
  min-height: 520px;
}

.tab-pane h2 {
  font-family: var(--font-serif);
  font-size: 1.65rem;
  margin: 0;
  font-weight: normal;
  color: var(--primary-color, #3d2b1f);
}

.pane-title-block .pane-subtitle {
  margin: 0.35rem 0 0;
  font-size: 0.88rem;
  color: #6b5d56;
}

.pane-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 1rem;
  padding-bottom: 1.25rem;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid #f0ebe6;
}

.profile-pane-header {
  align-items: center;
}

.profile-pane-header h2 {
  border: none;
  padding: 0;
  margin-bottom: 0;
}

.btn-edit-profile {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  flex: none;
  width: auto;
  padding: 0.55rem 1.15rem;
  font-size: 0.88rem;
  color: #fff;
  background: var(--primary-color, #3d2b1f);
  border: none;
  border-radius: 999px;
  cursor: pointer;
  box-shadow: 0 4px 14px rgba(61, 43, 31, 0.2);
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-edit-profile:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(61, 43, 31, 0.25);
}

.profile-view {
  max-width: 100%;
}

.profile-info-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

.profile-info-item {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 1.15rem 1.2rem;
  background: linear-gradient(145deg, #fdfbf9 0%, #f8f3ef 100%);
  border: 1px solid #efe6df;
  border-radius: 12px;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.profile-info-item:hover {
  border-color: #e5d5c8;
  box-shadow: 0 4px 16px rgba(45, 31, 38, 0.04);
}

.profile-info-icon {
  flex-shrink: 0;
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  background: #fff;
  color: var(--accent-color, #b87a7a);
  font-size: 1.15rem;
  box-shadow: 0 2px 8px rgba(45, 31, 38, 0.05);
}

.profile-info-body {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  min-width: 0;
}

.profile-info-label {
  font-size: 0.8rem;
  color: #5c4f48;
  font-weight: 500;
  letter-spacing: 0.02em;
}

.profile-info-value {
  font-size: 1rem;
  color: #2d1f1a;
  font-weight: 600;
  word-break: break-word;
}

.profile-card-footer {
  margin-top: 1.75rem;
  padding-top: 1.5rem;
  border-top: 1px solid #f0ebe6;
}

.btn-logout-inline {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.65rem 1.25rem;
  font-size: 0.9rem;
  color: #4a3f38;
  background: #fff;
  border: 1px solid #d9cfc6;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-logout-inline:hover {
  color: #c0392b;
  border-color: #f5c6c0;
  background: #fff8f7;
}

.profile-form {
  max-width: 560px;
  padding: 0.25rem 0 0;
}

.profile-field {
  margin-bottom: 1.15rem;
}

.profile-field label {
  display: block;
  font-size: 0.85rem;
  color: #5c4f48;
  font-weight: 500;
  margin-bottom: 0.4rem;
}

.profile-field input {
  width: 100%;
  box-sizing: border-box;
  padding: 0.75rem 0.85rem;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 0.95rem;
  font-family: var(--font-sans);
  color: var(--text-primary);
  background: #fff;
  transition: border-color 0.2s;
}

.profile-field input:focus {
  outline: none;
  border-color: var(--primary-color, #5c4033);
}

.profile-form-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.65rem;
  margin-top: 1.5rem;
  padding-top: 0.25rem;
}

.profile-form-actions .btn-primary,
.profile-form-actions .btn-profile-cancel {
  flex: none;
  width: auto;
  min-width: 100px;
  padding: 0.7rem 1.35rem;
  font-size: 0.95rem;
  cursor: pointer;
  border-radius: 6px;
}

.profile-form-actions .btn-primary {
  border: none;
}

.profile-form-actions .btn-profile-cancel {
  background: #fff;
  border: 1px solid #e5e7eb;
  color: #666;
}

.profile-form-actions .btn-profile-cancel:hover:not(:disabled) {
  border-color: #ccc;
  color: #333;
}

.profile-form-actions .btn-primary:disabled,
.profile-form-actions .btn-profile-cancel:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

/* Address & Order Lists Styles */
.address-card, .order-card {
  background: #faf8f6;
  border: 1px solid #efe6df;
  border-radius: 12px;
  padding: 1.35rem 1.5rem;
  margin-bottom: 1rem;
  transition: box-shadow 0.2s;
}

.address-card:hover, .order-card:hover {
  box-shadow: 0 4px 16px rgba(45, 31, 38, 0.05);
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
  align-items: flex-end;
  gap: 1rem;
  flex-wrap: wrap;
  background: transparent;
}
.order-footer-main {
  flex: 1 1 auto;
  min-width: 0;
}
.order-actions {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  flex-wrap: wrap;
  justify-content: flex-end;
}
.express-info {
  font-size: 0.85rem;
  color: #666;
  background: #f9f9f9;
  padding: 0.55rem 0.7rem;
  border-radius: 6px;
}
.express-info p {
  margin: 0;
}
.express-tracking-link {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  margin-top: 0.45rem;
  color: #047857;
  font-weight: 600;
  text-decoration: none;
}
.express-tracking-link:hover {
  color: #065f46;
  text-decoration: underline;
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

.favorites-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 1rem;
}
.favorite-card {
  display: flex;
  gap: 1rem;
  padding: 1rem;
  background: #faf8f6;
  border: 1px solid #efe6df;
  border-radius: 12px;
  transition: box-shadow 0.2s;
}

.favorite-card:hover {
  box-shadow: 0 4px 16px rgba(45, 31, 38, 0.06);
}
.favorite-thumb-link {
  flex-shrink: 0;
  display: block;
  width: 88px;
  height: 88px;
  overflow: hidden;
  background: #f5f5f5;
}
.favorite-thumb {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.favorite-body {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.favorite-name {
  font-family: var(--font-serif);
  font-size: 1rem;
  color: var(--text-primary);
  text-decoration: none;
  line-height: 1.35;
}
.favorite-name:hover {
  color: var(--primary-color);
}
.favorite-price {
  margin: 0;
  color: var(--primary-color, #5c4033);
  font-weight: 600;
}
.favorite-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-top: auto;
  padding-top: 0.35rem;
}
.btn-link {
  background: none;
  border: none;
  padding: 0;
  font-size: 0.85rem;
  color: var(--primary-color);
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;
}
.btn-link.text-danger {
  color: #dc2626;
}

.affiliate-pane { max-width: 960px; }
.aff-product-links { margin: 1.25rem 0; }
.aff-product-links h4 { margin: 0 0 0.35rem; font-size: 1rem; }
.aff-product-links-hint { margin: 0 0 0.75rem; font-size: 0.85rem; color: #888; line-height: 1.5; }
.aff-promo-table-wrap { overflow-x: auto; border: 1px solid #eee; border-radius: 8px; }
.aff-promo-table { width: 100%; min-width: 560px; border-collapse: collapse; font-size: 0.88rem; }
.aff-promo-table th,
.aff-promo-table td { padding: 0.65rem 0.75rem; text-align: left; border-bottom: 1px solid #f0f0f0; vertical-align: middle; }
.aff-promo-table th { background: #fafafa; color: #666; font-weight: 600; white-space: nowrap; }
.promo-product-cell { display: flex; align-items: center; gap: 0.6rem; min-width: 0; }
.promo-thumb { width: 40px; height: 40px; object-fit: cover; border-radius: 6px; flex-shrink: 0; background: #f5f5f5; }
.promo-name { font-weight: 500; color: #333; line-height: 1.35; }
.aff-progress { margin: 1.25rem 0; }
.aff-progress-list { margin: 0.5rem 0 0; padding-left: 1.25rem; color: #444; line-height: 1.6; }
.aff-downline { margin: 1.5rem 0; }
.aff-downline h4 { margin: 0 0 0.5rem; font-size: 1rem; }
.aff-downline-meta { margin: 0 0 0.75rem; font-size: 0.9rem; color: #666; }
.aff-downline-meta strong { color: #333; }
.aff-downline-table-wrap { overflow-x: auto; border: 1px solid #eee; border-radius: 8px; }
.aff-downline-table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
.aff-downline-table th,
.aff-downline-table td { padding: 0.65rem 0.75rem; text-align: left; border-bottom: 1px solid #f0f0f0; }
.aff-downline-table th { background: #fafafa; color: #666; font-weight: 600; }
.downline-name { display: block; font-weight: 500; color: #333; }
.downline-user { display: block; font-size: 0.8rem; color: #999; }
.downline-badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 999px; font-size: 0.75rem; }
.downline-badge.valid { background: #ecfdf5; color: #047857; }
.downline-badge.pending { background: #f3f4f6; color: #6b7280; }
.aff-downline-empty { margin: 0; font-size: 0.9rem; color: #888; line-height: 1.5; }
.aff-settle-hint { font-size: 0.9rem; color: #666; margin-top: 0.75rem; }
.wallet-pane .wallet-title {
  font-family: var(--font-serif);
  font-size: 1.8rem;
  margin: 0 0 0.5rem;
  font-weight: normal;
  border-bottom: none;
  padding-bottom: 0;
}
.wallet-intro,
.wallet-affiliate-hint {
  font-size: 0.88rem;
  color: #6b5d56;
  margin: 0 0 0.5rem;
  line-height: 1.5;
}
.wallet-affiliate-link {
  color: var(--primary-color, #5c4033);
  font-weight: 600;
  text-decoration: underline;
}
.wallet-empty-hint {
  font-size: 0.85rem;
  color: #888;
  margin-top: 0.5rem;
}
.gcash-load-error {
  color: #b45309;
  font-size: 0.88rem;
  margin-bottom: 0.75rem;
}
.wallet-toolbar { margin-bottom: 0.85rem; border-top: 1px solid #eee; padding-top: 0.85rem; }
.flow-filter-chips {
  display: flex;
  flex-wrap: nowrap;
  gap: 0.5rem;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: none;
  padding-bottom: 2px;
}
.flow-filter-chips::-webkit-scrollbar { display: none; }
.flow-chip {
  flex: 0 0 auto;
  padding: 0.4rem 0.95rem;
  border: 1px solid #e8e4df;
  background: #fff;
  border-radius: 999px;
  font-size: 0.85rem;
  color: #666;
  cursor: pointer;
  transition: background 0.2s, color 0.2s, border-color 0.2s;
  font-family: var(--font-sans);
}
.flow-chip.active {
  background: var(--primary-color, #3d2b1f);
  border-color: var(--primary-color, #3d2b1f);
  color: #fff;
}
.wallet-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.5rem;
  margin-bottom: 1.25rem;
}
.wallet-stat {
  background: #faf8f5;
  border: 1px solid #efe9e2;
  padding: 0.7rem 0.45rem;
  border-radius: 10px;
  text-align: center;
  min-width: 0;
}
.wallet-stat span {
  display: block;
  font-size: 0.72rem;
  color: #888;
  margin-bottom: 0.35rem;
  line-height: 1.35;
}
.wallet-stat b {
  display: block;
  font-size: 1rem;
  font-weight: 600;
  line-height: 1.25;
  word-break: break-all;
}
.wallet-stat b em {
  font-style: normal;
  font-size: 0.72em;
  font-weight: 500;
  margin-left: 0.1em;
  opacity: 0.85;
}
.wallet-stat--income b { color: #16a34a; }
.wallet-stat--spent b { color: #dc2626; }
.wallet-stat--available b { color: var(--primary-color, #5c4033); }
.wallet-stat--withdraw b { color: #0d9488; }
.gcash-section {
  margin: 1.5rem 0;
  padding: 1.25rem;
  background: #faf8f5;
  border: 1px solid var(--border-color, #e8ddd4);
  border-radius: 12px;
}
.gcash-heading {
  font-size: 1rem;
  margin: 0 0 0.5rem;
  font-family: var(--font-serif);
}
.gcash-heading:not(:first-child) { margin-top: 1.25rem; }
.gcash-hint { font-size: 0.85rem; color: #6b5d56; margin-bottom: 0.75rem; }
.gcash-form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}
@media (max-width: 600px) {
  .gcash-form-grid { grid-template-columns: 1fr; }
}
.gcash-form-grid label span {
  display: block;
  font-size: 0.82rem;
  color: #5c4f48;
  margin-bottom: 0.3rem;
}
.gcash-form-grid input {
  width: 100%;
  box-sizing: border-box;
  padding: 0.65rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.btn-gcash-save, .btn-withdraw {
  padding: 0.6rem 1.2rem;
  background: var(--primary-color, #5c4033);
  color: #fff;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
}
.withdraw-row {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}
.withdraw-row input {
  flex: 1;
  min-width: 120px;
  padding: 0.65rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.withdraw-list { margin-top: 1rem; display: flex; flex-direction: column; gap: 0.5rem; }
.withdraw-item {
  background: #fff;
  border: 1px solid #eee;
  border-radius: 8px;
  padding: 0.75rem 1rem;
}
.withdraw-main { display: flex; justify-content: space-between; align-items: center; }
.withdraw-status { font-size: 0.75rem; padding: 0.15rem 0.5rem; border-radius: 6px; background: #f3f4f6; }
.withdraw-status.ws-pending { background: #fef3c7; color: #92400e; }
.withdraw-status.ws-approved { background: #d1fae5; color: #065f46; }
.withdraw-status.ws-rejected { background: #fee2e2; color: #991b1b; }
.withdraw-sub, .withdraw-meta { font-size: 0.82rem; color: #888; margin-top: 0.25rem; }
.order-status-group { display: flex; flex-direction: column; align-items: flex-end; gap: 0.25rem; }
.payment-status { font-size: 0.75rem; color: #b45309; }
.btn-order-pay {
  padding: 0.55rem 1rem;
  background: var(--primary-color);
  color: #fff;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
}
.btn-order-delete {
  padding: 0.55rem 1rem;
  background: #fff;
  color: #dc2626;
  border: 1px solid #fecaca;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
}
.btn-order-delete:hover {
  background: #fef2f2;
}
.flow-list { display: flex; flex-direction: column; gap: 0.75rem; }
.flow-item { border: 1px solid #eee; border-radius: 10px; padding: 0.85rem 1rem; background: #fff; }
.flow-item.in { border-left: 3px solid #16a34a; }
.flow-item.out { border-left: 3px solid #dc2626; }
.flow-main { display: flex; justify-content: space-between; align-items: center; gap: 0.5rem; }
.flow-status { font-size: 0.75rem; color: #6b7280; background: #f3f4f6; padding: 0.15rem 0.5rem; border-radius: 6px; }
.flow-sub { font-size: 0.85rem; color: #666; margin: 0.35rem 0; }
.flow-meta { display: flex; justify-content: space-between; font-size: 0.8rem; color: #999; }
.flow-amt.in { color: #16a34a; font-weight: 600; }
.flow-amt.out { color: #dc2626; font-weight: 600; }
.flow-pager { display: flex; align-items: center; justify-content: center; gap: 1rem; margin-top: 1rem; }
.flow-pager button { padding: 0.4rem 0.9rem; border: 1px solid #e5e7eb; background: #fff; border-radius: 8px; cursor: pointer; }
.flow-pager button:disabled { opacity: 0.5; cursor: not-allowed; }
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

/* Tablet */
@media (max-width: 1024px) {
  .user-center-page {
    padding: 1.5rem 1rem 3rem;
  }
  .container {
    gap: 1.25rem;
  }
  .sidebar {
    width: 220px;
    position: static;
  }
  .content-panel {
    padding: 1.5rem 1.25rem 2rem;
  }
  .profile-info-grid {
    grid-template-columns: 1fr;
  }
}

/* Mobile */
@media (max-width: 768px) {
  .user-center-page {
    padding: 1rem 0 2.5rem;
    min-height: auto;
  }

  .container {
    flex-direction: column;
    gap: 0.75rem;
    padding: 0 0.75rem;
    box-sizing: border-box;
    max-width: 100%;
    overflow: visible;
  }

  .sidebar {
    width: 100%;
    max-width: 100%;
    position: static;
    padding: 0;
    border: none;
    background: transparent;
    box-shadow: none;
    overflow: visible;
    min-width: 0;
  }

  .user-card {
    display: flex;
    align-items: center;
    gap: 1rem;
    text-align: left;
    background: #fff;
    padding: 1rem 1.15rem;
    border: 1px solid rgba(61, 43, 31, 0.08);
    border-radius: 14px;
    margin-bottom: 0;
    box-shadow: 0 4px 16px rgba(45, 31, 38, 0.05);
  }

  .avatar-ring {
    margin-bottom: 0;
    flex-shrink: 0;
  }

  .avatar {
    width: 52px;
    height: 52px;
    font-size: 1.25rem;
  }

  .info h3 {
    font-size: 1.05rem;
    margin-bottom: 0.2rem;
  }

  .user-meta {
    margin-bottom: 0.5rem;
  }

  .content-panel {
    padding: 1.25rem 1rem 1.5rem;
    border-radius: 14px;
    min-height: auto;
  }

  .nav-menu-wrap {
    position: relative;
    width: 100%;
    max-width: 100%;
    margin: 0 0 0.75rem;
    min-width: 0;
  }

  .nav-menu-wrap::after {
    content: '';
    position: absolute;
    top: 0;
    right: 0;
    width: 2rem;
    height: 100%;
    pointer-events: none;
    background: linear-gradient(90deg, transparent, #fff 85%);
    border-radius: 0 14px 14px 0;
  }

  .nav-menu {
    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    align-items: stretch;
    width: 100%;
    max-width: 100%;
    margin: 0;
    padding: 0.45rem 0.65rem;
    overflow-x: auto;
    overflow-y: hidden;
    overscroll-behavior-x: contain;
    -webkit-overflow-scrolling: touch;
    scroll-snap-type: x proximity;
    scroll-padding-inline: 0.65rem;
    scrollbar-width: none;
    background: #fff;
    border: 1px solid rgba(61, 43, 31, 0.08);
    border-radius: 14px;
    box-shadow: 0 4px 16px rgba(45, 31, 38, 0.05);
    gap: 0.35rem;
    box-sizing: border-box;
  }

  .nav-menu::-webkit-scrollbar {
    display: none;
  }

  .nav-menu .nav-tab {
    flex: 0 0 auto;
    white-space: nowrap;
    scroll-snap-align: start;
    padding: 0.62rem 0.8rem;
    font-size: 0.82rem;
    border-bottom: none;
    box-shadow: none;
  }

  .nav-menu .nav-tab.active {
    background: rgba(201, 149, 160, 0.15);
    color: var(--primary-color, #3d2b1f);
    font-weight: 600;
    box-shadow: none;
  }

  .nav-menu .nav-tab i {
    font-size: 1rem;
  }

  .content-area {
    width: 100%;
    padding: 0;
    min-width: 0;
  }

  .tab-pane h2,
  .pane-header h2 {
    font-size: 1.35rem;
    margin-bottom: 1rem;
    padding-bottom: 0.75rem;
  }

  .pane-header {
    flex-direction: column;
    align-items: stretch;
  }

  .pane-header .btn-primary {
    width: 100%;
    box-sizing: border-box;
  }

  .wallet-pane .wallet-title {
    font-size: 1.35rem;
    margin-bottom: 0.75rem;
    padding-bottom: 0.65rem;
  }

  .wallet-stat {
    padding: 0.55rem 0.35rem;
    border-radius: 8px;
  }

  .wallet-stat span {
    font-size: 0.65rem;
  }

  .wallet-stat b {
    font-size: 0.88rem;
  }

  .profile-info-grid {
    grid-template-columns: 1fr;
  }

  .profile-form {
    max-width: none;
  }

  .profile-form-actions .btn-primary,
  .profile-form-actions .btn-profile-cancel {
    flex: 1;
    min-width: 0;
  }

  .btn-edit-profile {
    width: 100%;
    justify-content: center;
  }

  .profile-pane-header {
    flex-direction: column;
    align-items: stretch;
  }

  .address-card,
  .order-card {
    padding: 1rem;
    margin-bottom: 1rem;
  }

  .addr-header {
    flex-wrap: wrap;
    gap: 0.5rem;
  }

  .order-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.35rem;
  }

  .order-item {
    gap: 0.75rem;
  }

  .item-thumb {
    width: 64px;
    height: 64px;
    flex-shrink: 0;
  }

  .order-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
  }

  .total-price {
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .aff-actions {
    flex-direction: column;
  }

  .aff-actions .btn-primary,
  .aff-actions .btn-secondary {
    width: 100%;
    text-align: center;
    box-sizing: border-box;
  }

  .commission-grid {
    grid-template-columns: 1fr;
  }

  .flow-main {
    flex-direction: column;
    align-items: flex-start;
  }

  .flow-meta {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.35rem;
  }

  .aff-copy pre {
    font-size: 0.82rem;
    padding: 0.75rem;
  }

  .modal-overlay {
    align-items: flex-end;
    padding: 0;
  }

  .modal-content {
    width: 100%;
    max-width: none;
    max-height: 92vh;
    overflow-y: auto;
    border-radius: 12px 12px 0 0;
    padding: 1.25rem 1rem 1.5rem;
  }

  .form-row {
    flex-direction: column;
    gap: 0;
  }

  .modal-actions {
    flex-direction: column-reverse;
    gap: 0.65rem;
  }

  .modal-actions .btn-primary,
  .modal-actions .btn-cancel {
    width: 100%;
    padding: 0.85rem;
  }

  .btn-logout-large {
    width: 100%;
    max-width: 100%;
    box-sizing: border-box;
  }

  .empty-state {
    padding: 2.5rem 1rem;
  }
}

@media (max-width: 400px) {
  .nav-menu .nav-tab-label {
    display: none;
  }

  .nav-menu .nav-tab {
    padding: 0.65rem 0.7rem;
  }

  .nav-menu .nav-tab i {
    font-size: 1.15rem;
  }
}
</style>
