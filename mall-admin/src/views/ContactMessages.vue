<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">{{ $t('admin.contactMessagesPage.title') }}</h1>
      <div class="header-actions">
        <button class="btn-secondary" type="button" @click="load">
          <i class="ri-refresh-line"></i> {{ $t('admin.contactMessagesPage.refresh') }}
        </button>
      </div>
    </div>

    <div class="data-table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>{{ $t('admin.contactMessagesPage.colTime') }}</th>
            <th>{{ $t('admin.contactMessagesPage.colName') }}</th>
            <th>{{ $t('admin.contactMessagesPage.colContact') }}</th>
            <th>{{ $t('admin.contactMessagesPage.colLocale') }}</th>
            <th>{{ $t('admin.contactMessagesPage.colIp') }}</th>
            <th>{{ $t('admin.contactMessagesPage.colContent') }}</th>
            <th>{{ $t('admin.contactMessagesPage.colAction') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in rows" :key="row.id">
            <td class="time">{{ formatTime(row.created_at) }}</td>
            <td>{{ row.visitor_name }}</td>
            <td class="wrap">{{ row.contact || '—' }}</td>
            <td>{{ row.locale || '—' }}</td>
            <td class="ip">{{ row.ip || '—' }}</td>
            <td class="detail" :title="row.content">{{ row.content }}</td>
            <td class="actions">
              <button class="icon-btn danger" type="button" :title="$t('admin.contactMessagesPage.delete')" @click="remove(row)">
                <i class="ri-delete-bin-line"></i>
              </button>
            </td>
          </tr>
          <tr v-if="rows.length === 0">
            <td colspan="7" class="empty-text">{{ $t('admin.contactMessagesPage.empty') }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="lastPage > 1" class="pager">
      <button class="btn-secondary" type="button" :disabled="page <= 1" @click="goPage(page - 1)">
        {{ $t('admin.contactMessagesPage.pagePrev') }}
      </button>
      <span class="pager-meta">{{ page }} / {{ lastPage }} · {{ $t('admin.contactMessagesPage.total', { n: total }) }}</span>
      <button class="btn-secondary" type="button" :disabled="page >= lastPage" @click="goPage(page + 1)">
        {{ $t('admin.contactMessagesPage.pageNext') }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { api } from '../api'
import { toast } from '../components/Toast'

const { t } = useI18n()

const rows = ref([])
const page = ref(1)
const lastPage = ref(1)
const total = ref(0)
const limit = 20

function formatTime(v) {
  if (v == null || v === '') return '—'
  if (typeof v === 'number' || /^\d+$/.test(String(v))) {
    const ts = Number(v) * (String(v).length <= 10 ? 1000 : 1)
    const d = new Date(ts)
    if (!Number.isNaN(d.getTime())) return d.toLocaleString()
  }
  return String(v)
}

async function load() {
  const res = await api.getContactMessages({ page: page.value, limit })
  if (res.code !== 0) {
    toast.error(res.msg || 'Error')
    return
  }
  const p = res.data
  const list = p?.data ?? p?.list ?? []
  rows.value = Array.isArray(list) ? list : []
  total.value = Number(p?.total ?? 0) || 0
  const per = Number(p?.per_page ?? limit) || limit
  const lp = Number(p?.last_page)
  lastPage.value = lp > 0 ? lp : Math.max(1, Math.ceil(total.value / per) || 1)
}

async function goPage(p) {
  page.value = p
  await load()
}

async function remove(row) {
  if (!window.confirm(t('admin.contactMessagesPage.deleteConfirm'))) return
  const res = await api.deleteContactMessage(row.id)
  if (res.code === 0) {
    toast.success(res.msg || 'OK')
    await load()
  } else {
    toast.error(res.msg || 'Error')
  }
}

onMounted(() => {
  load()
})
</script>

<style scoped>
.page-container {
  padding: 2rem;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.page-title {
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0;
}

.header-actions {
  display: flex;
  gap: 0.75rem;
}

.btn-secondary {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  background: #fff;
  cursor: pointer;
  font-size: 0.9rem;
}

.btn-secondary:hover:not(:disabled) {
  background: #f9fafb;
}

.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.data-table-card {
  background: #fff;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
  overflow: hidden;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9rem;
}

.data-table th,
.data-table td {
  padding: 0.85rem 1rem;
  text-align: left;
  border-bottom: 1px solid #f3f4f6;
}

.data-table th {
  background: #fafafa;
  font-weight: 600;
  color: #374151;
}

.data-table tr:hover td {
  background: #fafafa;
}

.detail {
  max-width: 320px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.wrap {
  max-width: 140px;
  word-break: break-all;
}

.ip {
  font-family: ui-monospace, monospace;
  font-size: 0.85rem;
}

.time {
  white-space: nowrap;
  color: #6b7280;
}

.actions {
  width: 72px;
}

.icon-btn {
  border: none;
  background: #f3f4f6;
  width: 36px;
  height: 36px;
  border-radius: 8px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.icon-btn.danger:hover {
  background: #fee2e2;
  color: #b91c1c;
}

.empty-text {
  text-align: center;
  color: #9ca3af;
  padding: 2rem !important;
}

.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  margin-top: 1.25rem;
}

.pager-meta {
  font-size: 0.9rem;
  color: #6b7280;
}
</style>
