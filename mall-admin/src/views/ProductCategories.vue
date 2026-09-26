<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ t('admin.categoriesPage.title') }}</h1>
        <p class="page-desc">{{ t('admin.categoriesPage.desc') }}</p>
      </div>
      <button class="btn-primary" type="button" @click="openModal()">
        <i class="ri-add-line"></i> {{ t('admin.categoriesPage.add') }}
      </button>
    </div>

    <div class="data-table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>{{ t('admin.categoriesPage.colId') }}</th>
            <th>{{ t('admin.categoriesPage.colNameZh') }}</th>
            <th>{{ t('admin.categoriesPage.colNameEn') }}</th>
            <th>{{ t('admin.categoriesPage.colSort') }}</th>
            <th>{{ t('admin.categoriesPage.colStatus') }}</th>
            <th>{{ t('admin.categoriesPage.colActions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in categories" :key="row.id">
            <td class="muted">#{{ row.id }}</td>
            <td><span class="name-cell">{{ row.name }}</span></td>
            <td><span class="name-cell muted-en">{{ row.name_en || '—' }}</span></td>
            <td>{{ row.sort_order }}</td>
            <td>
              <span class="status-dot" :class="{ active: row.status === 1 }"></span>
              {{ row.status === 1 ? t('admin.categoriesPage.enabled') : t('admin.categoriesPage.disabled') }}
            </td>
            <td class="actions">
              <button class="icon-btn" type="button" :title="t('admin.categoriesPage.editTitle')" @click="openModal(row)">
                <i class="ri-edit-line"></i>
              </button>
              <button class="icon-btn delete" type="button" :title="t('admin.categoriesPage.deleteRowTitle')" @click="remove(row)">
                <i class="ri-delete-bin-line"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-if="!categories.length" class="empty-hint">{{ t('admin.categoriesPage.empty') }}</p>
    </div>

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal modal-wide" @click.stop>
        <div class="modal-header">
          <h2>{{ editing ? t('admin.categoriesPage.editTitle') : t('admin.categoriesPage.addTitle') }}</h2>
          <button class="close-btn" type="button" @click="closeModal"><i class="ri-close-line"></i></button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>{{ t('admin.categoriesPage.nameZh') }}</label>
            <input v-model="form.name" type="text" :placeholder="t('admin.categoriesPage.nameZhPh')" maxlength="100" />
          </div>
          <div class="form-group">
            <label>{{ t('admin.categoriesPage.nameEn') }}</label>
            <input v-model="form.name_en" type="text" :placeholder="t('admin.categoriesPage.nameEnPh')" maxlength="100" />
          </div>
          <div class="form-group">
            <label>{{ t('admin.categoriesPage.sortHint') }}</label>
            <input v-model.number="form.sort_order" type="number" />
          </div>
          <div class="form-group">
            <label>{{ t('admin.categoriesPage.status') }}</label>
            <div class="status-toggle">
              <label class="radio-label" :class="{ active: form.status === 1 }">
                <input v-model.number="form.status" type="radio" :value="1" />
                <span>{{ t('admin.categoriesPage.enabled') }}</span>
              </label>
              <label class="radio-label" :class="{ active: form.status === 0 }">
                <input v-model.number="form.status" type="radio" :value="0" />
                <span>{{ t('admin.categoriesPage.disabled') }}</span>
              </label>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" type="button" @click="closeModal">{{ t('admin.categoriesPage.cancel') }}</button>
          <button class="btn-primary" type="button" @click.stop="save">{{ t('admin.categoriesPage.save') }}</button>
        </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { api } from '../api'
import { toast } from '../components/Toast/index.js'

const { t } = useI18n()

const categories = ref([])
const showModal = ref(false)
const editing = ref(false)
const form = reactive({
  id: null,
  name: '',
  name_en: '',
  sort_order: 0,
  status: 1,
})

const load = async () => {
  const res = await api.listProductCategories()
  if (res.code === 0) {
    categories.value = Array.isArray(res.data) ? res.data : []
  } else {
    toast.error(res.msg || t('admin.categoriesPage.loadFail'))
  }
}

const openModal = (row = null) => {
  editing.value = !!row
  if (row) {
    form.id = row.id
    form.name = row.name ?? ''
    form.name_en = row.name_en ?? ''
    form.sort_order = row.sort_order ?? 0
    form.status = row.status ?? 1
  } else {
    form.id = null
    form.name = ''
    form.name_en = ''
    form.sort_order = (categories.value[categories.value.length - 1]?.sort_order ?? 0) + 10
    form.status = 1
  }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

const save = async () => {
  try {
    const name = String(form.name || '').trim()
    if (!name) {
      toast.warning(t('admin.categoriesPage.nameRequired'))
      return
    }
    const nameEn = String(form.name_en || '').trim()
    const res = await api.saveProductCategory({
      id: form.id,
      name,
      name_en: nameEn,
      sort_order: Number(form.sort_order) || 0,
      status: form.status === 0 ? 0 : 1,
    })
    if (res.code === 0) {
      toast.success(t('admin.categoriesPage.saveOk'))
      closeModal()
      load()
    } else {
      toast.error(res.msg || t('admin.categoriesPage.saveFail'))
    }
  } catch (e) {
    console.error(e)
    toast.error(e?.message || t('admin.categoriesPage.saveFail'))
  }
}

const remove = async (row) => {
  if (!confirm(t('admin.categoriesPage.deleteConfirm', { name: row.name }))) return
  const res = await api.deleteProductCategory(row.id)
  if (res.code === 0) {
    toast.success(t('admin.categoriesPage.deleted'))
    load()
  } else {
    toast.error(res.msg || t('admin.categoriesPage.deleteFail'))
  }
}

onMounted(load)
</script>

<style scoped>
.page-container {
  padding: 2rem;
  max-width: 960px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
  gap: 1rem;
}

.page-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--color-primary-dark);
  margin: 0 0 0.35rem;
}

.page-desc {
  margin: 0;
  font-size: 0.9rem;
  color: var(--color-text-muted, #6b7280);
  max-width: 36rem;
}

.data-table-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.08);
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
  font-size: 0.85rem;
}

.muted {
  color: #9ca3af;
  font-size: 0.9rem;
}

.muted-en {
  color: #6b7280;
  font-weight: 400;
}

.name-cell {
  font-weight: 500;
  color: #111827;
}

.status-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #d1d5db;
  margin-right: 0.5rem;
}

.status-dot.active {
  background: #10b981;
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

.icon-btn.delete:hover {
  background: #fee2e2;
  color: #ef4444;
}

.empty-hint {
  padding: 2rem;
  text-align: center;
  color: #9ca3af;
  margin: 0;
}

.btn-primary {
  background: var(--color-primary);
  color: white;
  border: none;
  padding: 0.6rem 1.25rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  flex-shrink: 0;
}

.btn-primary:hover {
  filter: brightness(1.05);
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.modal {
  background: white;
  border-radius: 16px;
  width: 440px;
  max-width: 95%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  overflow: hidden;
}

.modal-wide {
  width: 480px;
}

.modal-header {
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid #f3f4f6;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h2 {
  font-size: 1.15rem;
  font-weight: 600;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.35rem;
  color: #9ca3af;
  cursor: pointer;
  padding: 0.35rem;
  border-radius: 50%;
}

.close-btn:hover {
  background: #f3f4f6;
  color: #4b5563;
}

.modal-body {
  padding: 1.5rem;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.45rem;
  font-weight: 500;
  color: #374151;
  font-size: 0.9rem;
}

.form-group input {
  width: 100%;
  padding: 0.65rem 0.85rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 0.95rem;
  box-sizing: border-box;
}

.form-group input:focus {
  outline: none;
  border-color: var(--color-primary);
}

.status-toggle {
  display: flex;
  background: #f3f4f6;
  padding: 4px;
  border-radius: 8px;
  width: fit-content;
  border: 1px solid #e5e7eb;
}

.radio-label {
  padding: 0.45rem 1.25rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #6b7280;
}

.radio-label input {
  display: none;
}

.radio-label.active {
  background: white;
  color: var(--color-primary);
  font-weight: 600;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
}

.modal-footer {
  padding: 1rem 1.5rem;
  background: #f9fafb;
  border-top: 1px solid #f3f4f6;
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

.btn-secondary {
  background: white;
  border: 1px solid #e5e7eb;
  color: #4b5563;
  padding: 0.55rem 1.25rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
}
</style>
