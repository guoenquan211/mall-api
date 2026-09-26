<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">管理员管理</h1>
      <div class="header-actions">
        <button class="btn-primary" @click="openModal()">
          <i class="ri-add-line"></i> 新增管理员
        </button>
      </div>
    </div>

    <div class="data-table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>管理员信息</th>
            <th>角色</th>
            <th>最后登录</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="admin in admins" :key="admin.id">
            <td>#{{ admin.id }}</td>
            <td>
              <div class="user-info">
                <div class="avatar">{{ admin.nickname.charAt(0) }}</div>
                <div class="details">
                  <div class="nickname">{{ admin.nickname }}</div>
                  <div class="username">@{{ admin.username }}</div>
                </div>
              </div>
            </td>
            <td>
              <span class="role-badge" :class="admin.role">{{ formatRole(admin.role) }}</span>
            </td>
            <td class="date">{{ admin.last_login }}</td>
            <td>
              <span class="status-dot" :class="{ active: admin.status === 1 }"></span>
              {{ admin.status === 1 ? '正常' : '禁用' }}
            </td>
            <td class="actions">
              <button class="icon-btn" title="编辑" @click="openModal(admin)">
                <i class="ri-edit-line"></i>
              </button>
              <button class="icon-btn delete" title="删除" @click="deleteAdmin(admin)" v-if="admin.id !== 1">
                <i class="ri-delete-bin-line"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Edit/Add Modal -->
    <div class="modal-overlay" v-if="showModal" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <h2>{{ editingAdmin ? '编辑管理员' : '新增管理员' }}</h2>
          <button class="close-btn" @click="closeModal"><i class="ri-close-line"></i></button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>用户名</label>
            <input type="text" v-model="form.username" :disabled="editingAdmin">
          </div>
          <div class="form-group">
            <label>昵称</label>
            <input type="text" v-model="form.nickname">
          </div>
          <div class="form-group">
            <label>角色</label>
            <select v-model="form.role">
              <option value="super_admin">超级管理员</option>
              <option value="editor">内容编辑</option>
              <option value="service">客服专员</option>
            </select>
          </div>
          <div class="form-group">
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
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeModal">取消</button>
          <button class="btn-primary" @click="saveAdmin">保存</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'

const admins = ref([])
const showModal = ref(false)
const editingAdmin = ref(null)
const form = ref({
  username: '',
  nickname: '',
  role: 'editor',
  status: 1
})

const loadAdmins = async () => {
  const res = await api.getAdmins()
  if (res.code === 0) {
    admins.value = res.data.data || res.data
  }
}

const formatRole = (role) => {
  const map = {
    'super_admin': '超级管理员',
    'editor': '内容编辑',
    'service': '客服专员'
  }
  return map[role] || role
}

const openModal = (admin = null) => {
  editingAdmin.value = admin
  if (admin) {
    form.value = { ...admin }
  } else {
    form.value = {
      username: '',
      nickname: '',
      role: 'editor',
      status: 1
    }
  }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
  editingAdmin.value = null
}

const saveAdmin = async () => {
  if (!form.value.username || !form.value.nickname) {
    toast.warning('请填写完整信息')
    return
  }
  
  const res = await api.saveAdmin(form.value)
  if (res.code === 0) {
    toast.success('保存成功')
    closeModal()
    loadAdmins()
  } else {
    toast.error(res.msg)
  }
}

const deleteAdmin = async (admin) => {
  if (confirm(`确定要删除管理员 ${admin.nickname} 吗？`)) {
    const res = await api.deleteAdmin(admin.id)
    if (res.code === 0) {
      loadAdmins()
    }
  }
}

onMounted(() => {
  loadAdmins()
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
  font-size: 0.9rem;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
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

.role-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: 500;
}

.role-badge.super_admin {
  background: #fee2e2;
  color: #991b1b;
}

.role-badge.editor {
  background: #dbeafe;
  color: #1e40af;
}

.role-badge.service {
  background: #d1fae5;
  color: #065f46;
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

.icon-btn.delete:hover {
  background: #fee2e2;
  color: #ef4444;
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
  width: 500px;
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

.form-group {
  margin-bottom: 1.5rem;
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
  box-shadow: 0 0 0 4px rgba(var(--color-primary-rgb, 16, 185, 129), 0.1);
}

.form-group input:disabled {
  background: #f3f4f6;
  color: #9ca3af;
  cursor: not-allowed;
  border-color: #e5e7eb;
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
  display: flex;
  align-items: center;
  gap: 0.5rem;
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