<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">用户管理</h1>
      <div class="header-actions">
        <div class="search-box">
          <i class="ri-search-line"></i>
          <input type="text" placeholder="搜索用户名/昵称/手机号" v-model="searchQuery">
        </div>
          <button class="btn-primary" @click="createUser">
            <i class="ri-user-add-line"></i> 新增用户
          </button>
      </div>
    </div>

    <div class="data-table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>用户信息</th>
            <th>积分</th>
            <th>联系方式</th>
            <th>注册时间</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in filteredUsers" :key="user.id">
            <td>#{{ user.id }}</td>
            <td>
              <div class="user-info">
                <div class="avatar">{{ user.nickname.charAt(0) }}</div>
                <div class="details">
                  <div class="nickname">{{ user.nickname }}</div>
                  <div class="username">@{{ user.username }}</div>
                </div>
              </div>
            </td>
            <td class="points">{{ user.points }}</td>
            <td>
              <div class="contact">
                <i class="ri-phone-line"></i> {{ user.phone }}
              </div>
              <div class="contact">
                <i class="ri-mail-line"></i> {{ user.email }}
              </div>
            </td>
            <td class="date">{{ user.created_at }}</td>
            <td>
              <span class="status-dot" :class="{ active: user.status === 1 }"></span>
              {{ user.status === 1 ? '正常' : '禁用' }}
            </td>
            <td class="actions">
              <button class="icon-btn" title="编辑" @click="editUser(user)">
                <i class="ri-edit-line"></i>
              </button>
              <button class="icon-btn" :title="user.status === 1 ? '禁用' : '启用'" @click="toggleStatus(user)">
                <i :class="user.status === 1 ? 'ri-prohibited-line' : 'ri-checkbox-circle-line'"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Edit User Modal -->
    <div class="modal-overlay" v-if="showModal" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <h2>{{ form.id ? '编辑用户' : '新增用户' }}</h2>
          <button class="close-btn" @click="closeModal"><i class="ri-close-line"></i></button>
        </div>
        
        <div class="modal-tabs">
          <div 
            class="tab-item" 
            :class="{ active: currentTab === 'info' }"
            @click="currentTab = 'info'"
          >
            基本信息
          </div>
          <div 
            class="tab-item" 
            :class="{ active: currentTab === 'address' }"
            @click="currentTab = 'address'"
          >
            收货地址
          </div>
        </div>

        <div class="modal-body" v-if="currentTab === 'info'">
          <div class="form-row">
            <div class="form-group half">
              <label>用户名</label>
              <input type="text" v-model="form.username" :disabled="!!form.id" :class="form.id ? 'disabled-input' : ''">
            </div>
            <div class="form-group half">
              <label>昵称</label>
              <input type="text" v-model="form.nickname">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group half">
              <label>手机号</label>
              <input type="text" v-model="form.phone">
            </div>
            <div class="form-group half">
              <label>邮箱</label>
              <input type="email" v-model="form.email">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group half">
              <label>{{ form.id ? '重置密码（留空不修改）' : '密码' }}</label>
              <input type="password" v-model="form.password" :placeholder="form.id ? '留空则不修改' : '请输入密码'">
            </div>
            <div class="form-group half">
              <label>确认密码</label>
              <input type="password" v-model="form.confirm_password" :placeholder="form.id ? '与上方一致（留空不修改）' : '请再次输入密码'">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group half">
              <label>积分</label>
              <input type="number" v-model="form.points">
            </div>
            <div class="form-group half">
              <label>状态</label>
              <div class="status-toggle">
                <label class="radio-label" :class="{ active: form.status === 1 }">
                  <input type="radio" v-model="form.status" :value="1"> 
                  <span>正常</span>
                </label>
                <label class="radio-label" :class="{ active: form.status === 0 }">
                  <input type="radio" v-model="form.status" :value="0"> 
                  <span>禁用</span>
                </label>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-body" v-if="currentTab === 'address'">
          <div class="address-actions">
             <button class="btn-small" @click="addAddress">
               <i class="ri-add-line"></i> 新增地址
             </button>
          </div>
          <div class="address-list">
            <div class="address-item" v-for="addr in userAddresses" :key="addr.id">
              <div class="addr-header">
                <span class="addr-name">{{ addr.name }}</span>
                <span class="addr-phone">{{ addr.phone }}</span>
                <span class="default-tag" v-if="addr.is_default">默认</span>
              </div>
              <div class="addr-detail">
                {{ addr.province }}{{ addr.city }}{{ addr.district }} {{ addr.detail }}
              </div>
              <div class="addr-actions">
                <button class="text-btn" @click="editAddress(addr)">编辑</button>
                <button class="text-btn danger" @click="deleteAddress(addr.id)">删除</button>
              </div>
            </div>
            <div class="empty-state" v-if="userAddresses.length === 0">
              暂无收货地址
            </div>
          </div>

          <!-- Address Edit Form (Nested) -->
          <div class="nested-form" v-if="editingAddress">
            <h3>{{ addressForm.id ? '编辑地址' : '新增地址' }}</h3>
            <div class="form-row">
              <div class="form-group half">
                <label>收货人</label>
                <input type="text" v-model="addressForm.name">
              </div>
              <div class="form-group half">
                <label>手机号</label>
                <input type="text" v-model="addressForm.phone">
              </div>
            </div>
            <div class="form-row">
              <div class="form-group third">
                <label>省</label>
                <input type="text" v-model="addressForm.province">
              </div>
              <div class="form-group third">
                <label>市</label>
                <input type="text" v-model="addressForm.city">
              </div>
              <div class="form-group third">
                <label>区/县</label>
                <input type="text" v-model="addressForm.district">
              </div>
            </div>
            <div class="form-group">
              <label>详细地址</label>
              <input type="text" v-model="addressForm.detail">
            </div>
            <div class="form-group">
              <label class="checkbox-label">
                <input type="checkbox" v-model="addressForm.is_default" :true-value="1" :false-value="0"> 设为默认地址
              </label>
            </div>
            <div class="nested-actions">
              <button class="btn-secondary small" @click="cancelAddressEdit">取消</button>
              <button class="btn-primary small" @click="saveAddress">保存地址</button>
            </div>
          </div>
        </div>

        <div class="modal-footer" v-if="currentTab === 'info'">
          <button class="btn-secondary" @click="closeModal">取消</button>
          <button class="btn-primary" @click="saveUser">保存修改</button>
        </div>
        <div class="modal-footer" v-if="currentTab === 'address'">
           <button class="btn-secondary" @click="closeModal">关闭</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'

const users = ref([])
const searchQuery = ref('')
const showModal = ref(false)
const currentTab = ref('info')
const form = ref({})
const userAddresses = ref([])
const editingAddress = ref(false)
const addressForm = ref({})

const filteredUsers = computed(() => {
  return users.value.filter(user => {
    const query = searchQuery.value.toLowerCase()
    return user.username.toLowerCase().includes(query) || 
           user.nickname.toLowerCase().includes(query) ||
           user.phone.includes(query)
  })
})

const loadUsers = async () => {
  const res = await api.getUsers()
  if (res.code === 0) {
    users.value = res.data.data || res.data
  }
}

const loadAddresses = async (userId) => {
  const res = await api.getUserAddresses(userId)
  if (res.code === 0) {
    userAddresses.value = res.data
  }
}

const editUser = async (user) => {
  form.value = { ...user }
  form.value.password = ''
  form.value.confirm_password = ''
  currentTab.value = 'info'
  editingAddress.value = false
  await loadAddresses(user.id)
  showModal.value = true
}

const createUser = () => {
  form.value = {
    id: null,
    username: '',
    nickname: '',
    phone: '',
    email: '',
    points: 0,
    status: 1,
    password: '',
    confirm_password: ''
  }
  currentTab.value = 'info'
  editingAddress.value = false
  userAddresses.value = []
  showModal.value = true
}

const toggleStatus = async (user) => {
  const newUser = { ...user, status: user.status === 1 ? 0 : 1 }
  const res = await api.saveUser(newUser)
  if (res.code === 0) {
    loadUsers()
  }
}

const closeModal = () => {
  showModal.value = false
}

const saveUser = async () => {
  const payload = { ...form.value }
  if (!payload.id) {
    if (!payload.username) {
      toast.warning('请填写用户名')
      return
    }
    if (!payload.password) {
      toast.warning('请填写密码')
      return
    }
    if (payload.password !== payload.confirm_password) {
      toast.error('两次输入的密码不一致')
      return
    }
  } else {
    if (payload.password || payload.confirm_password) {
      if (payload.password !== payload.confirm_password) {
        toast.error('两次输入的密码不一致')
        return
      }
    } else {
      delete payload.password
    }
  }
  delete payload.confirm_password
  const res = await api.saveUser(payload)
  if (res.code === 0) {
    toast.success('保存成功')
    closeModal()
    loadUsers()
  } else {
    toast.error(res.msg || '保存失败')
  }
}

// Address Logic
const addAddress = () => {
  addressForm.value = {
    user_id: form.value.id,
    name: '',
    phone: '',
    province: '',
    city: '',
    district: '',
    detail: '',
    is_default: 0
  }
  editingAddress.value = true
}

const editAddress = (addr) => {
  addressForm.value = { ...addr }
  editingAddress.value = true
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

  const res = await api.deleteUserAddress(id)
  if (res.code === 0) {
    toast.success('地址已删除')
    loadAddresses(form.value.id)
  } else {
    toast.error(res.msg || '删除失败')
  }
}

const cancelAddressEdit = () => {
  editingAddress.value = false
}

const saveAddress = async () => {
  if (!addressForm.value.name || !addressForm.value.phone || !addressForm.value.detail) {
    toast.warning('请填写完整地址信息')
    return
  }
  const res = await api.saveUserAddress(addressForm.value)
  if (res.code === 0) {
    toast.success('地址保存成功')
    editingAddress.value = false
    loadAddresses(form.value.id)
  }
}

onMounted(() => {
  loadUsers()
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

.user-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.avatar {
  width: 40px;
  height: 40px;
  background: var(--color-primary);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
}

.details {
  display: flex;
  flex-direction: column;
}

.nickname {
  font-weight: 500;
  color: #111827;
}

.username {
  font-size: 0.8rem;
  color: #6b7280;
}

.points {
  font-family: monospace;
  font-weight: 600;
  color: var(--color-accent);
}

.contact {
  font-size: 0.85rem;
  color: #6b7280;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.date {
  color: #6b7280;
  font-size: 0.875rem;
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
  width: 700px;
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

.modal-tabs {
  display: flex;
  padding: 0 2rem;
  border-bottom: 1px solid #e5e7eb;
  background: #fff;
}

.tab-item {
  padding: 1rem 0.5rem;
  margin-right: 2rem;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  color: #6b7280;
  font-weight: 500;
  transition: all 0.2s;
  font-size: 0.95rem;
}

.tab-item:hover {
  color: #374151;
}

.tab-item.active {
  color: var(--color-primary);
  border-bottom-color: var(--color-primary);
}

.modal-body {
  padding: 2rem;
  overflow-y: auto;
  flex: 1;
}

.form-row {
  display: flex;
  gap: 2rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group.half {
  flex: 1;
}

.form-group.third {
  flex: 1;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
  font-size: 0.9rem;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: all 0.2s ease;
  background: #f9fafb;
  color: #1f2937;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: var(--color-primary);
  background: white;
  box-shadow: 0 0 0 4px rgba(var(--color-primary-rgb, 16, 185, 129), 0.1); /* Fallback RGB if var not set */
}

.disabled-input {
  background: #f3f4f6 !important;
  color: #9ca3af !important;
  cursor: not-allowed;
  border-color: #e5e7eb !important;
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
  padding: 0.5rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #6b7280;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  user-select: none;
}

.radio-label input {
  display: none;
}

.radio-label.active {
  background: white;
  color: var(--color-primary);
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  font-weight: 600;
}

.modal-footer {
  padding: 1.5rem 2rem;
  background: #f9fafb;
  border-top: 1px solid #f3f4f6;
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.btn-primary {
  background: var(--color-primary);
  color: white;
  border: none;
  padding: 0.6rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
  box-shadow: 0 4px 6px -1px rgba(var(--color-primary-rgb, 16, 185, 129), 0.2);
}

.btn-primary:hover {
  transform: translateY(-1px);
  filter: brightness(110%);
  box-shadow: 0 6px 8px -1px rgba(var(--color-primary-rgb, 16, 185, 129), 0.3);
}

.btn-secondary {
  background: white;
  border: 1px solid #e5e7eb;
  color: #4b5563;
  padding: 0.6rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: #f9fafb;
  color: #111827;
  border-color: #d1d5db;
}

.btn-small {
  padding: 0.4rem 0.8rem;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.4rem;
  background: var(--color-primary);
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.address-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 1rem;
}

.address-item {
  border: 1px solid #e5e7eb;
  padding: 1rem;
  border-radius: 8px;
  position: relative;
}

.addr-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}

.addr-name {
  font-weight: 600;
}

.default-tag {
  background: #fee2e2;
  color: #991b1b;
  font-size: 0.75rem;
  padding: 2px 6px;
  border-radius: 4px;
}

.addr-detail {
  color: #6b7280;
  font-size: 0.9rem;
}

.addr-actions {
  margin-top: 0.5rem;
  display: flex;
  gap: 1rem;
}

.text-btn {
  background: none;
  border: none;
  color: var(--color-primary);
  cursor: pointer;
  padding: 0;
  font-size: 0.9rem;
}

.text-btn.danger {
  color: #ef4444;
}

.nested-form {
  margin-top: 1.5rem;
  background: #f9fafb;
  padding: 1.5rem;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.nested-form h3 {
  margin-top: 0;
  margin-bottom: 1rem;
  font-size: 1.1rem;
}

.nested-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1rem;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}
</style>
