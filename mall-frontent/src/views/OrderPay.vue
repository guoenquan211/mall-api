<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { api } from '../api'
import { useUser } from '../store'
import { toast } from '../components/Toast'
import { formatPrice } from '../utils/formatMoney.js'
import { resolveMediaUrl } from '../utils/resolveMediaUrl.js'

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const { user } = useUser()

const loading = ref(true)
const submitting = ref(false)
const order = ref(null)
const accounts = ref([])
const selectedSlot = ref(1)
const remark = ref('')
const paymentProof = ref('')
const proofPreview = ref('')
const uploadingProof = ref(false)

const orderId = computed(() => route.params.id)

const selectedAccount = computed(() =>
  accounts.value.find((a) => a.slot === selectedSlot.value) || accounts.value[0]
)

const selectedQrSrc = computed(() => {
  const url = selectedAccount.value?.qr_image
  return url ? resolveMediaUrl(url) : ''
})

const canMarkPaid = computed(() => {
  const o = order.value
  if (!o) return false
  return Number(o.status) === 0 && ['pending', 'rejected'].includes(o.payment_status || 'pending')
})

const paymentStatusText = computed(() => {
  const ps = order.value?.payment_status
  if (ps === 'user_confirmed') return t('orderPay.statusReview')
  if (ps === 'approved') return t('orderPay.statusApproved')
  if (ps === 'rejected') return t('orderPay.statusRejected')
  return t('orderPay.statusPending')
})

const load = async () => {
  if (!user.loggedIn) {
    router.push('/login')
    return
  }
  loading.value = true
  try {
    const res = await api.getOrderPaymentInfo(orderId.value, user.id)
    if (res.code === 0) {
      order.value = res.data.order
      accounts.value = (res.data.accounts || []).map((acc) => ({
        ...acc,
        qr_image: acc.qr_image ? resolveMediaUrl(acc.qr_image) : '',
      }))
      if (accounts.value.length) {
        selectedSlot.value = accounts.value[0].slot
      }
    } else {
      toast.error(res.msg || t('common.systemError'))
      router.push('/user')
    }
  } catch (e) {
    console.error(e)
    toast.error(t('common.systemError'))
  } finally {
    loading.value = false
  }
}

const onProofUpload = async (e) => {
  const file = e.target?.files?.[0]
  if (!file) return
  uploadingProof.value = true
  if (proofPreview.value) {
    URL.revokeObjectURL(proofPreview.value)
    proofPreview.value = ''
  }
  try {
    const res = await api.uploadImage(file)
    if (res.code === 0 && res.data?.url) {
      paymentProof.value = res.data.url
      proofPreview.value = resolveMediaUrl(res.data.url)
      toast.success(t('orderPay.proofUploadOk'))
    } else {
      toast.error(res.msg || t('common.systemError'))
    }
  } catch (err) {
    console.error(err)
    toast.error(t('common.systemError'))
  } finally {
    uploadingProof.value = false
    e.target.value = ''
  }
}

const markPaid = async () => {
  if (!canMarkPaid.value) return
  if (!paymentProof.value) {
    toast.warning(t('orderPay.proofRequired'))
    return
  }
  submitting.value = true
  try {
    const res = await api.markOrderPaid({
      order_id: order.value.id,
      user_id: user.id,
      account_slot: selectedSlot.value,
      remark: remark.value,
      payment_proof: paymentProof.value,
    })
    if (res.code === 0) {
      order.value = res.data
      toast.success(res.msg || t('orderPay.markPaidOk'))
      setTimeout(() => router.push('/user'), 1500)
    } else {
      toast.error(res.msg || t('orderPay.markPaidFail'))
    }
  } catch (e) {
    console.error(e)
    toast.error(t('common.systemError'))
  } finally {
    submitting.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page-container order-pay-page">
    <div v-if="loading" class="loading">{{ $t('common.loading') }}</div>
    <template v-else-if="order">
      <h1 class="page-title">{{ $t('orderPay.title') }}</h1>
      <p class="order-no">{{ $t('orderPay.orderNo') }}：{{ order.order_no }}</p>
      <p class="amount">{{ formatPrice(order.total_amount) }}</p>
      <p class="status-hint">{{ paymentStatusText }}</p>
      <p v-if="order.payment_reject_reason" class="reject-hint">
        {{ $t('orderPay.rejectReason') }}：{{ order.payment_reject_reason }}
      </p>

      <div v-if="canMarkPaid && accounts.length" class="pay-grid">
        <div class="account-tabs">
          <button
            v-for="acc in accounts"
            :key="acc.slot"
            type="button"
            class="acc-tab"
            :class="{ active: selectedSlot === acc.slot }"
            @click="selectedSlot = acc.slot"
          >
            {{ acc.label || `GCash ${acc.slot}` }}
          </button>
        </div>

        <div v-if="selectedAccount" class="qr-card">
          <p class="acc-meta" v-if="selectedAccount.account_name">
            {{ selectedAccount.account_name }}
            <span v-if="selectedAccount.mobile"> · {{ selectedAccount.mobile }}</span>
          </p>
          <div class="qr-wrap" v-if="selectedQrSrc">
            <img :src="selectedQrSrc" alt="GCash QR" />
          </div>
          <p v-else class="no-qr">{{ $t('orderPay.noQr') }}</p>
          <p class="tip">{{ $t('orderPay.scanTip') }}</p>
        </div>

        <div class="proof-field">
          <div class="proof-field-header">
            <span class="proof-required-badge">{{ $t('orderPay.proofLabel') }}</span>
            <p class="proof-hint">{{ $t('orderPay.proofHint') }}</p>
          </div>

          <label
            class="proof-upload-zone"
            :class="{
              'has-image': !!proofPreview,
              uploading: uploadingProof,
            }"
          >
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp,image/gif"
              class="proof-file-input"
              :disabled="uploadingProof"
              @change="onProofUpload"
            />

            <template v-if="uploadingProof">
              <div class="proof-zone-icon loading"><i class="ri-loader-4-line"></i></div>
              <p class="proof-zone-title">{{ $t('orderPay.proofUploading') }}</p>
            </template>

            <template v-else-if="proofPreview">
              <div class="proof-preview-wrap">
                <img :src="proofPreview" alt="payment proof" />
                <div class="proof-preview-mask">
                  <i class="ri-refresh-line"></i>
                  <span>{{ $t('orderPay.proofChange') }}</span>
                </div>
              </div>
              <p class="proof-zone-done"><i class="ri-checkbox-circle-fill"></i> {{ $t('orderPay.proofUploaded') }}</p>
            </template>

            <template v-else>
              <div class="proof-zone-icon">
                <i class="ri-upload-cloud-2-line"></i>
              </div>
              <p class="proof-zone-title">{{ $t('orderPay.proofZoneTitle') }}</p>
              <p class="proof-zone-sub">{{ $t('orderPay.proofZoneSub') }}</p>
              <span class="proof-zone-action">
                <i class="ri-image-add-line"></i>
                {{ $t('orderPay.proofUpload') }}
              </span>
              <p class="proof-zone-formats">{{ $t('orderPay.proofFormats') }}</p>
            </template>
          </label>
        </div>

        <div class="remark-field">
          <label>{{ $t('orderPay.remarkOptional') }}</label>
          <input v-model="remark" type="text" :placeholder="$t('orderPay.remarkPh')" />
        </div>

        <button type="button" class="pay-btn" :disabled="submitting || uploadingProof" @click="markPaid">
          {{ submitting ? $t('common.saving') : $t('orderPay.markPaidBtn') }}
        </button>
      </div>

      <div v-else-if="!canMarkPaid" class="done-box">
        <router-link to="/user" class="link-btn">{{ $t('orderPay.backUser') }}</router-link>
      </div>
    </template>
  </div>
</template>

<style scoped>
.order-pay-page {
  padding: 5rem 1.25rem 3rem;
  max-width: 480px;
  margin: 0 auto;
}
.page-title {
  font-family: var(--font-serif);
  font-size: 1.6rem;
  text-align: center;
  margin-bottom: 0.5rem;
}
.order-no, .status-hint {
  text-align: center;
  color: #6b5d56;
  font-size: 0.9rem;
}
.reject-hint {
  text-align: center;
  color: #dc2626;
  font-size: 0.88rem;
  margin: 0.5rem 0 0;
  padding: 0.5rem 0.75rem;
  background: #fef2f2;
  border-radius: 6px;
}
.amount {
  text-align: center;
  font-size: 2rem;
  color: var(--primary-color);
  margin: 1rem 0;
  font-weight: 600;
}
.account-tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}
.acc-tab {
  flex: 1;
  padding: 0.55rem;
  border: 1px solid #e5e7eb;
  background: #fff;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
}
.acc-tab.active {
  border-color: var(--primary-color);
  background: #faf8f5;
  font-weight: 600;
}
.qr-card {
  background: #fff;
  border: 1px solid #efe6df;
  border-radius: 12px;
  padding: 1.25rem;
  text-align: center;
  margin-bottom: 1rem;
}
.acc-meta {
  font-size: 0.88rem;
  color: #5c4f48;
  margin-bottom: 0.75rem;
}
.qr-wrap img {
  max-width: 260px;
  width: 100%;
  border-radius: 8px;
}
.no-qr {
  color: #999;
  padding: 2rem 0;
}
.tip {
  font-size: 0.82rem;
  color: #888;
  margin-top: 0.75rem;
}
.proof-field {
  margin-bottom: 1.25rem;
  text-align: left;
}
.proof-field-header {
  margin-bottom: 0.75rem;
}
.proof-required-badge {
  display: inline-block;
  font-size: 0.9rem;
  font-weight: 700;
  color: #3d342f;
  background: #fef3c7;
  border: 1px solid #fcd34d;
  padding: 0.2rem 0.55rem;
  border-radius: 6px;
}
.proof-hint {
  font-size: 0.82rem;
  color: #6b5d56;
  margin: 0.5rem 0 0;
  line-height: 1.45;
}
.proof-upload-zone {
  display: block;
  position: relative;
  padding: 1.35rem 1rem 1.15rem;
  border: 2px dashed #c4a882;
  border-radius: 12px;
  background: linear-gradient(180deg, #fffdf9 0%, #faf6f1 100%);
  cursor: pointer;
  text-align: center;
  transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
}
.proof-upload-zone:hover {
  border-color: var(--primary-color);
  background: #fff9f3;
  box-shadow: 0 4px 14px rgba(92, 79, 72, 0.08);
}
.proof-upload-zone.has-image {
  border-style: solid;
  border-color: #86efac;
  background: #f0fdf4;
  padding: 0.75rem;
}
.proof-upload-zone.uploading {
  pointer-events: none;
  opacity: 0.85;
}
.proof-file-input {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
  z-index: 2;
}
.proof-zone-icon {
  width: 56px;
  height: 56px;
  margin: 0 auto 0.65rem;
  border-radius: 50%;
  background: #efe6df;
  color: var(--primary-color);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.75rem;
}
.proof-zone-icon.loading i {
  animation: proof-spin 0.9s linear infinite;
}
@keyframes proof-spin {
  to { transform: rotate(360deg); }
}
.proof-zone-title {
  font-size: 1rem;
  font-weight: 700;
  color: #3d342f;
  margin: 0 0 0.25rem;
}
.proof-zone-sub {
  font-size: 0.85rem;
  color: #6b5d56;
  margin: 0 0 0.85rem;
}
.proof-zone-action {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.55rem 1.15rem;
  background: var(--primary-color);
  color: #fff;
  border-radius: 999px;
  font-size: 0.9rem;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(61, 52, 47, 0.2);
}
.proof-zone-formats {
  font-size: 0.75rem;
  color: #9ca3af;
  margin: 0.65rem 0 0;
}
.proof-preview-wrap {
  position: relative;
  border-radius: 10px;
  overflow: hidden;
  background: #fff;
  margin-bottom: 0.5rem;
}
.proof-preview-wrap img {
  display: block;
  width: 100%;
  max-height: 240px;
  object-fit: contain;
}
.proof-preview-mask {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  color: #fff;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  opacity: 0;
  transition: opacity 0.2s;
  font-size: 0.9rem;
  font-weight: 600;
}
.proof-preview-mask i {
  font-size: 1.5rem;
}
.proof-upload-zone.has-image:hover .proof-preview-mask {
  opacity: 1;
}
.proof-zone-done {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  font-size: 0.85rem;
  color: #047857;
  font-weight: 600;
  margin: 0;
}
.proof-zone-done i {
  font-size: 1.1rem;
}
.remark-field {
  margin-bottom: 1rem;
}
.remark-field label {
  display: block;
  font-size: 0.85rem;
  color: #5c4f48;
  margin-bottom: 0.35rem;
}
.remark-field input {
  width: 100%;
  box-sizing: border-box;
  padding: 0.7rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.pay-btn {
  width: 100%;
  padding: 0.95rem;
  background: var(--primary-color);
  color: #fff;
  border: none;
  font-size: 1rem;
  cursor: pointer;
  border-radius: 8px;
}
.pay-btn:disabled {
  opacity: 0.65;
}
.done-box {
  text-align: center;
  margin-top: 2rem;
}
.link-btn {
  color: var(--primary-color);
  text-decoration: underline;
}
.loading {
  text-align: center;
  padding: 3rem;
  color: #888;
}
</style>
