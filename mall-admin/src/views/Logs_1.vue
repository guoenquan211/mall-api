<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">操作日志</h1>
      <div class="header-actions">
        <div class="search-box">
          <i class="ri-search-line"></i>
          <input type="text" placeholder="搜索操作人/内容" v-model="searchQuery">
        </div>
        <button class="btn-secondary" @click="loadLogs">
          <i class="ri-refresh-line"></i> 刷新
        </button>
      </div>
    </div>

    <div class="data-table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>时间</th>
            <th>操作人</th>
            <th>角色</th>
            <th>IP</th>
            <th>操作类型</th>
            <th>操作对象</th>
            <th>详细内容</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="log in filteredLogs" :key="log.id">
            <td class="time">{{ log.created_at }}</td>
            <td class="operator">
              <div class="user-cell">
                <span class="avatar-small">{{ log.operator ? log.operator.charAt(0).toUpperCase() : 'S' }}</span>
                <span>{{ log.operator }}</span>
              </div>
            </td>
            <td>
              <span class="role-badge" :class="log.role">{{ getRoleName(log.role) }}</span>
            </td>
            <td class="ip">{{ log.ip }}</td>
            <td>
              <span class="action-tag" :class="getActionClass(log.action)">{{ log.action }}</span>
            </td>
            <td>{{ log.target }}</td>
            <td class="detail" :title="log.detail">{{ log.detail }}</td>
          </tr>
          <tr v-if="filteredLogs.length === 0">
            <td colspan="7" class="empty-text">暂无日志记录</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { api } from '../api'

const logs = ref([])
const searchQuery = ref('')

const loadLogs = async () => {
  const res = await api.getLogs()
  if (res.code === 0) {
    logs.value = res.data.data || res.data
  }
}

const filteredLogs = computed(() => {
  if (!searchQuery.value) return logs.value
  const q = searchQuery.value.toLowerCase()
  return logs.value.filter(log => 
    (log.operator && log.operator.toLowerCase().includes(q)) ||
    (log.detail && log.detail.toLowerCase().includes(q)) ||
    (log.action && log.action.toLowerCase().includes(q))
  )
})

const getRoleName = (role) => {
  const map = {
    'super_admin': '超级管理员',
    'editor': '内容编辑',
    'service': '客服专员',
    'system': '系统'
  }
  return map[role] || role
}

const getActionClass = (action) => {
  if (['登录', 'Login'].includes(action)) return 'info'
  if (['新增', '发布', 'Create'].includes(action)) return 'success'
  if (['更新', 'Update', 'Edit'].includes(action)) return 'warning'
  if (['删除', 'Delete'].includes(action)) return 'danger'
  return 'default'
}

onMounted(() => {
  loadLogs()
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
  color: #111827;
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

.btn-secondary {
  background: white;
  border: 1px solid #e5e7eb;
  color: #4b5563;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: #f9fafb;
  border-color: #d1d5db;
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

.time {
  color: #6b7280;
  font-size: 0.9rem;
  white-space: nowrap;
}

.user-cell {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 500;
  color: #1f2937;
}

.avatar-small {
  width: 24px;
  height: 24px;
  background: #e5e7eb;
  color: #4b5563;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 600;
}

.role-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
  background: #f3f4f6;
  color: #4b5563;
}

.role-badge.super_admin { background: #fee2e2; color: #991b1b; }
.role-badge.editor { background: #e0f2fe; color: #075985; }
.role-badge.service { background: #dcfce7; color: #166534; }

.ip {
  font-family: monospace;
  color: #6b7280;
  font-size: 0.9rem;
}

.action-tag {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: 500;
}

.action-tag.info { background: #eff6ff; color: #1d4ed8; }
.action-tag.success { background: #f0fdf4; color: #15803d; }
.action-tag.warning { background: #fefce8; color: #a16207; }
.action-tag.danger { background: #fef2f2; color: #b91c1c; }
.action-tag.default { background: #f3f4f6; color: #4b5563; }

.detail {
  max-width: 300px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: #4b5563;
}

.empty-text {
  text-align: center;
  color: #9ca3af;
  padding: 2rem;
}
</style>