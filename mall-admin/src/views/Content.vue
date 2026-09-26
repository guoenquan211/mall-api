<template>
  <div class="content-view">
    <div class="header-action">
      <div class="page-title">
        <h1>内容管理</h1>
        <span class="subtitle">发布与维护网站资讯及知识库</span>
      </div>
      <button class="btn-primary" @click="openModal()">
        <i class="ri-add-line"></i> 发布{{ activeTab === 'news' ? '资讯' : '知识' }}
      </button>
    </div>

    <div class="card main-card">
      <div class="tabs-header">
        <button 
          :class="['tab-btn', {active: activeTab === 'news'}]" 
          @click="activeTab = 'news'"
        >
          <i class="ri-newspaper-line"></i> 资讯新闻
        </button>
        <button 
          :class="['tab-btn', {active: activeTab === 'knowledge'}]" 
          @click="activeTab = 'knowledge'"
        >
          <i class="ri-book-open-line"></i> 科普知识
        </button>
      </div>
      
      <div class="content-list">
        <div v-if="loading" class="loading-state">
          <div class="spinner"></div>
          <p>加载中...</p>
        </div>
        
        <div v-else-if="list.length === 0" class="empty-state">
          <i class="ri-inbox-line"></i>
          <p>暂无数据</p>
        </div>

        <div v-else class="list-item" v-for="item in list" :key="item.id" :class="{ 'is-unpublished': isPublished(item) === false }">
          <div class="item-content">
            <div class="item-icon" v-if="activeTab === 'knowledge'">
              <img v-if="iconPreview(item.icon).type === 'image'" :src="iconPreview(item.icon).src" alt="" class="icon-img" />
              <i v-else :class="iconPreview(item.icon).class"></i>
            </div>
            <div class="item-thumb" v-else-if="item.image || item.cover_image">
              <img :src="item.image || item.cover_image" alt="cover" />
            </div>
            
            <div class="item-details">
              <h3>{{ item.title }}</h3>
              <p class="meta">
                <template v-if="activeTab === 'news'">
                  <span class="badge">{{ item.category }}</span>
                  <span class="date"><i class="ri-calendar-line"></i> {{ item.date }}</span>
                  <span class="source" v-if="item.source"><i class="ri-links-line"></i> {{ item.source }}</span>
                </template>
                <template v-else>
                  <span class="icon-class">{{ iconPreview(item.icon).type === 'image' ? '自定义图片图标' : item.icon }}</span>
                  <span class="source" v-if="item.source"><i class="ri-links-line"></i> {{ item.source }}</span>
                </template>
                <span class="status-badge" :class="isPublished(item) ? 'on' : 'off'">
                  {{ isPublished(item) ? '已上架' : '已下架' }}
                </span>
              </p>
              <p class="excerpt">{{ activeTab === 'news' ? (item.summary || item.excerpt) : (item.summary || item.desc) }}</p>
            </div>
          </div>

          <div class="publish-toggle" :title="isPublished(item) ? '点击下架' : '点击上架'">
            <label class="switch">
              <input
                type="checkbox"
                :checked="isPublished(item)"
                :disabled="togglingId === item.id"
                @change="toggleStatus(item)"
              />
              <span class="slider"></span>
            </label>
            <span class="toggle-label">{{ isPublished(item) ? '上架' : '下架' }}</span>
          </div>
          
          <div class="actions">
            <button class="btn-icon" @click="openModal(item)" title="编辑">
              <i class="ri-edit-line"></i>
            </button>
            <button class="btn-icon danger" @click="handleDelete(item.id)" title="删除">
              <i class="ri-delete-bin-line"></i>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal card">
        <div class="modal-header">
          <h3>{{ isEdit ? '编辑' : '发布' }}{{ activeTab === 'news' ? '资讯' : '知识' }}</h3>
          <button class="close-btn" @click="closeModal"><i class="ri-close-line"></i></button>
        </div>
        
        <div class="modal-body">
          <div class="form-group">
            <label>标题（繁體）</label>
            <input v-model="form.title" placeholder="繁體標題" />
          </div>
          <div class="form-group">
            <label>标题（English）</label>
            <input v-model="form.title_en" placeholder="English title (optional)" />
          </div>

          <!-- News Specific Fields -->
          <template v-if="activeTab === 'news'">
            <div class="form-row">
              <div class="form-group half">
                <label>分类</label>
                <input v-model="form.category" placeholder="例如：展会信息" />
              </div>
              <div class="form-group half">
                <label>日期</label>
                <input v-model="form.date" placeholder="YYYY.MM.DD" />
              </div>
            </div>
            <div class="form-group">
              <label>来源 (转载出处)</label>
              <input v-model="form.source" placeholder="例如：品牌官方 / 原创" />
            </div>

            <div class="form-group">
              <label>摘要（繁體）</label>
              <textarea v-model="form.summary" rows="3" placeholder="繁體摘要…"></textarea>
            </div>
            <div class="form-group">
              <label>摘要（English）</label>
              <textarea v-model="form.summary_en" rows="3" placeholder="English summary (optional)"></textarea>
            </div>
            <div class="form-group">
              <label>封面图片</label>
              <div class="image-upload-box">
                <div class="preview-area" v-if="form.image">
                  <img :src="form.image" alt="Preview" />
                  <label class="replace-img">
                    <input type="file" @change="handleImageUpload" accept="image/*" hidden />
                    <i class="ri-image-edit-line"></i> 更换图片
                  </label>
                  <button type="button" class="remove-img" @click="form.image = ''"><i class="ri-close-circle-fill"></i></button>
                </div>
                <label class="upload-btn" v-else>
                  <input type="file" @change="handleImageUpload" accept="image/*" hidden />
                  <i class="ri-image-add-line"></i>
                  <span>点击上传图片</span>
                </label>
              </div>
            </div>
            <div class="form-group">
              <label>详细内容（繁體）</label>
              <div class="editor-wrapper">
                <RichTextEditor v-model="form.content" />
              </div>
            </div>
            <div class="form-group">
              <label>详细内容（English）</label>
              <div class="editor-wrapper">
                <RichTextEditor v-model="form.content_en" />
              </div>
            </div>
          </template>

          <!-- Knowledge Specific Fields -->
          <template v-if="activeTab === 'knowledge'">
            <div class="form-group">
              <label>图标</label>
              <IconPicker v-model="form.icon" />
            </div>
            <div class="form-group">
              <label>来源 (转载出处)</label>
              <input v-model="form.source" placeholder="例如：植物病理学报 / 原创" />
            </div>

            <div class="form-group">
              <label>简述（繁體）</label>
              <textarea v-model="form.summary" rows="3" placeholder="繁體簡述…"></textarea>
            </div>
            <div class="form-group">
              <label>简述（English）</label>
              <textarea v-model="form.summary_en" rows="3" placeholder="English summary (optional)"></textarea>
            </div>
            <div class="form-group">
              <label>详细内容（繁體）</label>
              <div class="editor-wrapper">
                <RichTextEditor v-model="form.content" />
              </div>
            </div>
            <div class="form-group">
              <label>详细内容（English）</label>
              <div class="editor-wrapper">
                <RichTextEditor v-model="form.content_en" />
              </div>
            </div>
          </template>
        </div>

        <div class="modal-footer">
          <button class="btn-secondary" @click="closeModal">取消</button>
          <button class="btn-primary" @click="handleSave">
            <i class="ri-save-line"></i> 保存
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'
import RichTextEditor from '../components/RichTextEditor.vue'
import IconPicker from '../components/IconPicker.vue'
import { resolveContentIcon } from '../utils/contentIcon.js'
import { normalizeRichHtmlStorage } from '../utils/richHtml.js'

const iconPreview = (value) => resolveContentIcon(value)

const activeTab = ref('news')
const list = ref([])
const loading = ref(false)
const saving = ref(false)
const togglingId = ref(null)
const showModal = ref(false)
const isEdit = ref(false)

const isPublished = (item) => Number(item?.status ?? 1) === 1

const form = reactive({
  id: null,
  title: '',
  title_en: '',
  source: '',
  // News fields
  category: '',
  date: '',
  summary: '',
  summary_en: '',
  image: '',
  status: 1,
  // Knowledge fields
  icon: '',
  content: '',
  content_en: '',
})

const fetchData = async () => {
  loading.value = true
  try {
    const res = activeTab.value === 'news' ? await api.getNews() : await api.getKnowledge()
    if (res.code === 0) {
      const rows = res.data.data || res.data
      list.value = (rows || []).map((row) => ({
        ...row,
        status: row.status === undefined || row.status === null ? 1 : Number(row.status),
      }))
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const openModal = (item = null) => {
  if (item) {
    isEdit.value = true
      const mapped = { ...item }
    if (activeTab.value === 'news') {
      mapped.summary = item.summary || item.excerpt || ''
      mapped.summary_en = item.summary_en || ''
      mapped.title_en = item.title_en || ''
      mapped.content_en = item.content_en || ''
      mapped.image = item.image || item.cover_image || ''
      mapped.status = item.status === undefined || item.status === null ? 1 : Number(item.status)
    } else {
      mapped.summary = item.summary || item.desc || ''
      mapped.summary_en = item.summary_en || ''
      mapped.title_en = item.title_en || ''
      mapped.content_en = item.content_en || ''
      mapped.status = item.status === undefined || item.status === null ? 1 : Number(item.status)
    }
      Object.assign(form, mapped)
  } else {
    isEdit.value = false
    // Reset form
    Object.assign(form, {
      id: null,
      title: '',
      title_en: '',
      source: '',
      category: '',
      date: new Date().toLocaleDateString('zh-CN').replace(/\//g, '.'),
      summary: '',
      summary_en: '',
      image: '',
      status: 1,
      icon: 'ri-sparkling-line',
      content: '',
      content_en: '',
    })
  }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

const handleImageUpload = async (e) => {
  const file = e.target.files[0]
  if (!file) return
  
  try {
    const res = await api.uploadImage(file)
    if (res.code === 0) {
      form.image = res.data.url
    }
  } catch (e) {
    console.error('Upload failed', e)
    toast.error('图片上传失败')
  }
}

const handleSave = async () => {
  try {
      const data = {
        ...form,
        content: normalizeRichHtmlStorage(form.content),
        content_en: normalizeRichHtmlStorage(form.content_en),
      }
      if (activeTab.value === 'knowledge') {
        data.type = 'knowledge'
      } else {
        data.type = 'news'
        data.cover_image = form.image || ''
      }
      data.status = Number(form.status) === 0 ? 0 : 1
    let res
    if (activeTab.value === 'news') {
      res = await api.saveNews(data)
    } else {
      res = await api.saveKnowledge(data)
    }
    
    if (res.code === 0) {
      toast.success('保存成功')
      closeModal()
      fetchData()
    } else {
      toast.error(res.msg || '保存失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('保存失败: ' + (e.message || '未知错误'))
  } finally {
    saving.value = false
  }
}

const confirmingDelete = ref(null)

const toggleStatus = async (item) => {
  const nextStatus = isPublished(item) ? 0 : 1
  togglingId.value = item.id
  try {
    const res = activeTab.value === 'news'
      ? await api.setNewsStatus(item.id, nextStatus)
      : await api.setKnowledgeStatus(item.id, nextStatus)
    if (res.code === 0) {
      item.status = nextStatus
      toast.success(nextStatus === 1 ? '已上架' : '已下架')
    } else {
      toast.error(res.msg || '操作失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('操作失败')
  } finally {
    togglingId.value = null
  }
}

const handleDelete = async (id) => {
  if (confirmingDelete.value !== id) {
    confirmingDelete.value = id
    toast.info('再次点击以确认删除')
    setTimeout(() => confirmingDelete.value = null, 3000)
    return
  }
  confirmingDelete.value = null
  
  try {
    let res
    if (activeTab.value === 'news') {
      res = await api.deleteNews(id)
    } else {
      res = await api.deleteKnowledge(id)
    }
    
    if (res.code === 0) {
      toast.success('删除成功')
      fetchData()
    }
  } catch (e) {
    console.error(e)
    toast.error('删除失败')
  }
}

watch(activeTab, fetchData)

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.content-view {
  animation: fadeIn 0.5s ease;
}

.header-action {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-title h1 {
  font-size: 1.8rem;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: var(--color-text-muted);
  font-size: 0.9rem;
}

.main-card {
  padding: 0;
  overflow: hidden;
}

.tabs-header {
  display: flex;
  border-bottom: 1px solid var(--color-border);
  background: #fafafa;
}

.tab-btn {
  background: none;
  border: none;
  padding: 1rem 2rem;
  font-size: 0.95rem;
  cursor: pointer;
  color: var(--color-text-muted);
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border-right: 1px solid var(--color-border);
  transition: all 0.2s;
}

.tab-btn:hover {
  background: #f0f0f0;
  color: var(--color-primary-dark);
}

.tab-btn.active {
  background: white;
  color: var(--color-accent);
  border-bottom: 2px solid transparent; /* Hide bottom border to merge with content */
  position: relative;
}

.tab-btn.active::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--color-accent);
}

.content-list {
  padding: 0;
}

.list-item {
  padding: 1.5rem;
  border-bottom: 1px solid var(--color-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: background 0.2s;
}

.list-item:last-child {
  border-bottom: none;
}

.list-item:hover {
  background-color: #fafafa;
}

.list-item.is-unpublished {
  opacity: 0.72;
}

.list-item.is-unpublished .item-details h3 {
  color: #6b7280;
}

.item-content {
  display: flex;
  align-items: flex-start;
  gap: 1.5rem;
  flex: 1;
}

.item-thumb {
  width: 80px;
  height: 60px;
  border-radius: 6px;
  overflow: hidden;
  background: #f0f0f0;
  flex-shrink: 0;
}

.item-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-icon {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: #f0f7f4;
  color: var(--color-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  flex-shrink: 0;
  overflow: hidden;
}

.item-icon .icon-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.item-details h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.1rem;
  color: var(--color-primary-dark);
}

.meta {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
  font-size: 0.85rem;
}

.badge {
  background: #eef2f5;
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
  color: var(--color-text-muted);
}

.date {
  color: #999;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.icon-class {
  font-family: monospace;
  background: #f5f5f5;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  color: #666;
}

.source {
  color: #999;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.8rem;
}

.excerpt {
  margin: 0;
  color: var(--color-text-muted);
  font-size: 0.9rem;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  max-width: 600px;
}

.status-badge {
  padding: 0.15rem 0.55rem;
  border-radius: 999px;
  font-size: 0.75rem;
  font-weight: 500;
}

.status-badge.on {
  background: #ecfdf5;
  color: #059669;
}

.status-badge.off {
  background: #f3f4f6;
  color: #6b7280;
}

.publish-toggle {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.35rem;
  margin: 0 1rem;
  flex-shrink: 0;
}

.toggle-label {
  font-size: 0.75rem;
  color: #6b7280;
  white-space: nowrap;
}

.switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  inset: 0;
  background-color: #d1d5db;
  transition: 0.2s;
  border-radius: 999px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.2s;
  border-radius: 50%;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.15);
}

.switch input:checked + .slider {
  background-color: var(--color-primary, #10b981);
}

.switch input:checked + .slider:before {
  transform: translateX(20px);
}

.switch input:disabled + .slider {
  opacity: 0.6;
  cursor: not-allowed;
}

.actions {
  display: flex;
  gap: 0.5rem;
  margin-left: 1rem;
}

.btn-icon {
  background: none;
  border: none;
  width: 36px;
  height: 36px;
  border-radius: 6px;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
}

.btn-icon:hover {
  background: #f0f0f0;
  color: var(--color-primary-dark);
}

.btn-icon.danger:hover {
  background: #fff1f0;
  color: #cf1322;
}

.loading-state, .empty-state {
  padding: 4rem;
  text-align: center;
  color: var(--color-text-muted);
}

.spinner {
  width: 30px;
  height: 30px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid var(--color-accent);
  border-radius: 50%;
  margin: 0 auto 1rem;
  animation: spin 1s linear infinite;
}

.empty-state i {
  font-size: 3rem;
  color: #ddd;
  margin-bottom: 1rem;
  display: block;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Form Styles */
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
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: all 0.2s ease;
  background: #f9fafb;
  color: #1f2937;
  font-family: inherit;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: var(--color-primary);
  background: white;
  box-shadow: 0 0 0 4px rgba(var(--color-primary-rgb, 16, 185, 129), 0.1);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  margin-bottom: 1.5rem;
}

/* Image Upload */
.image-upload-box {
  border: 2px dashed #e5e7eb;
  border-radius: 12px;
  padding: 2rem;
  text-align: center;
  transition: all 0.2s;
  background: #f9fafb;
  cursor: pointer;
  position: relative;
  overflow: hidden;
}

.image-upload-box:hover {
  border-color: var(--color-primary);
  background: #f0fdf4;
}

.upload-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  color: #6b7280;
  cursor: pointer;
}

.upload-btn i {
  font-size: 2.5rem;
  color: #d1d5db;
  transition: color 0.2s;
}

.image-upload-box:hover .upload-btn i {
  color: var(--color-primary);
}

.preview-area {
  width: 100%;
  height: 200px;
  position: relative;
}

.preview-area img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  border-radius: 8px;
}

.remove-img {
  position: absolute;
  top: 10px;
  right: 10px;
  background: white;
  border: none;
  border-radius: 50%;
  color: #ef4444;
  cursor: pointer;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: all 0.2s;
}

.remove-img:hover {
  transform: scale(1.1);
  background: #fee2e2;
}

.replace-img {
  position: absolute;
  bottom: 10px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 0.4rem 0.85rem;
  font-size: 0.85rem;
  color: #374151;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.35rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.08);
  transition: all 0.2s;
}

.replace-img:hover {
  border-color: var(--color-primary);
  color: var(--color-primary);
}

/* Editor */
.editor-wrapper {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #e5e7eb;
}

:deep(.ql-toolbar) {
  border: none !important;
  border-bottom: 1px solid #e5e7eb !important;
  background: #f9fafb;
  padding: 8px !important;
}

:deep(.ql-container) {
  border: none !important;
  font-size: 1rem;
  min-height: 200px;
}

:deep(.ql-editor) {
  min-height: 200px;
  padding: 1rem;
}

/* Modal Animation */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  transition: all 0.3s ease;
}

.modal {
  width: 600px;
  max-width: 90%;
  max-height: 90vh;
  border-radius: 16px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  flex-direction: column;
}

.modal-header {
  padding: 1.25rem 2rem;
  background: white;
  border-bottom: 1px solid #f3f4f6;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
}

.modal-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
}

.modal-body {
  padding: 2rem;
  background: white;
  overflow-y: auto;
  flex: 1;
}

.modal-footer {
  padding: 1.25rem 2rem;
  background: #f9fafb;
  border-top: 1px solid #f3f4f6;
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  flex-shrink: 0;
  border-bottom-left-radius: 16px;
  border-bottom-right-radius: 16px;
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

.close-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s;
  background: transparent;
  border: none;
  cursor: pointer;
  color: #9ca3af;
}

.close-btn i {
  font-size: 1.5rem;
}

.close-btn:hover {
  background: #f3f4f6;
  color: #374151;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
@keyframes spin {
  to { transform: rotate(360deg); }
}

.spinner-sm {
  width: 1rem;
  height: 1rem;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  display: inline-block;
  margin-right: 0.5rem;
  vertical-align: middle;
}
</style>
