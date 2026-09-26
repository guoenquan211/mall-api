<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">首页 Hero 设置</h1>
      <p class="page-subtitle">配置前台首页顶部大图与文案（繁中 / 英文）</p>
    </div>

    <div class="card" v-if="loading">
      <p class="loading-text">加载中…</p>
    </div>

    <div class="card form-card" v-else>
      <div class="form-row">
        <div class="form-group half">
          <label>竖排副标题（繁體）</label>
          <input v-model="form.hero_subtitle_zh" placeholder="光感美白 · 身體護理" />
        </div>
        <div class="form-group half">
          <label>竖排副标题（English）</label>
          <input v-model="form.hero_subtitle_en" placeholder="Radiance body care" />
        </div>
      </div>

      <div class="form-group">
        <label>竖排品牌大字</label>
        <input v-model="form.hero_brand_text" placeholder="CocoBrite" />
      </div>

      <div class="form-row">
        <div class="form-group half">
          <label>主标题（繁體）</label>
          <input v-model="form.hero_title_zh" placeholder="浴見光感肌" />
        </div>
        <div class="form-group half">
          <label>主标题（English）</label>
          <input v-model="form.hero_title_en" placeholder="Glow, head to toe" />
        </div>
      </div>

      <div class="form-row">
        <div class="form-group half">
          <label>描述文案（繁體）</label>
          <textarea v-model="form.hero_text_zh" rows="4"></textarea>
        </div>
        <div class="form-group half">
          <label>描述文案（English）</label>
          <textarea v-model="form.hero_text_en" rows="4"></textarea>
        </div>
      </div>

      <div class="form-group">
        <label>右侧 Hero 大图</label>
        <div class="hero-image-box">
          <img v-if="previewImage" :src="previewImage" alt="Hero preview" class="hero-preview" />
          <label class="upload-btn">
            <input type="file" accept="image/*" hidden @change="onHeroImageUpload" />
            <i class="ri-upload-2-line"></i>
            {{ uploading ? '上传中…' : (previewImage ? '更换图片' : '上传图片') }}
          </label>
          <button v-if="form.hero_image" type="button" class="btn-text danger" @click="clearHeroImage">清除</button>
        </div>
      </div>

      <div class="detail-section">
        <h3 class="section-title">Hero「查看详情」按钮</h3>
        <p class="hint">显示在右侧大图区域。按钮文字固定为前台「查看详情 / View details」，此处只需选择跳转内容。</p>

        <label class="checkbox-row">
          <input v-model="form.hero_detail_show" type="checkbox" :true-value="1" :false-value="0" />
          <span>显示「查看详情」按钮</span>
        </label>

        <template v-if="Number(form.hero_detail_show) === 1">
          <div class="form-group">
            <label>跳转目标</label>
            <select v-model="form.hero_detail_link_type" class="select-input">
              <option value="">请选择</option>
              <option value="product">商品</option>
              <option value="news">品牌资讯</option>
              <option value="knowledge">美护课堂</option>
            </select>
          </div>

          <div v-if="form.hero_detail_link_type === 'product'" class="form-group">
            <label>选择商品</label>
            <select v-model="form.hero_detail_link_value" class="select-input">
              <option value="">请选择商品</option>
              <option v-for="p in productOptions" :key="p.id" :value="String(p.id)">
                {{ p.name }}{{ p.name_en ? ` / ${p.name_en}` : '' }}
              </option>
            </select>
          </div>

          <div v-else-if="form.hero_detail_link_type === 'news'" class="form-group">
            <label>选择资讯</label>
            <select v-model="form.hero_detail_link_value" class="select-input">
              <option value="">请选择资讯</option>
              <option v-for="n in newsOptions" :key="n.id" :value="String(n.id)">
                {{ n.title }}{{ n.title_en ? ` / ${n.title_en}` : '' }}
              </option>
            </select>
          </div>

          <div v-else-if="form.hero_detail_link_type === 'knowledge'" class="form-group">
            <label>选择课堂文章</label>
            <select v-model="form.hero_detail_link_value" class="select-input">
              <option value="">请选择文章</option>
              <option v-for="k in knowledgeOptions" :key="k.id" :value="String(k.id)">
                {{ k.title }}{{ k.title_en ? ` / ${k.title_en}` : '' }}
              </option>
            </select>
          </div>
        </template>
      </div>

      <div class="form-actions">
        <button type="button" class="btn-primary" :disabled="saving" @click="save">
          {{ saving ? '保存中…' : '保存设置' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'
import { resolveMediaUrl } from '../utils/resolveMediaUrl.js'

const loading = ref(true)
const saving = ref(false)
const uploading = ref(false)
const productOptions = ref([])
const newsOptions = ref([])
const knowledgeOptions = ref([])

const form = reactive({
  hero_subtitle_zh: '',
  hero_subtitle_en: '',
  hero_brand_text: 'CocoBrite',
  hero_title_zh: '',
  hero_title_en: '',
  hero_text_zh: '',
  hero_text_en: '',
  hero_image: '',
  hero_detail_show: 0,
  hero_detail_link_type: '',
  hero_detail_link_value: '',
})

const previewImage = computed(() => {
  if (!form.hero_image) return ''
  return resolveMediaUrl(form.hero_image)
})

const linkNeedsPick = (type) => ['product', 'news', 'knowledge'].includes(type)

watch(() => form.hero_detail_link_type, (next, prev) => {
  if (prev && next !== prev) {
    form.hero_detail_link_value = ''
  }
})

const unwrapList = (res) => {
  if (!res || res.code !== 0) return []
  const d = res.data
  if (Array.isArray(d)) return d
  if (Array.isArray(d?.data)) return d.data
  return []
}

const loadLinkOptions = async () => {
  try {
    const [productsRes, newsRes, knowledgeRes] = await Promise.all([
      api.getProducts(),
      api.getNews(),
      api.getKnowledge(),
    ])
    productOptions.value = unwrapList(productsRes).filter((p) => Number(p.status) === 1 || p.status === undefined)
    newsOptions.value = unwrapList(newsRes).filter((n) => Number(n.status) !== 0)
    knowledgeOptions.value = unwrapList(knowledgeRes).filter((n) => Number(n.status) !== 0)
  } catch (e) {
    console.error(e)
  }
}

const loadConfig = async () => {
  loading.value = true
  try {
    const res = await api.getHomeAdminConfig()
    if (res.code === 0 && res.data) {
      Object.assign(form, {
        hero_subtitle_zh: res.data.hero_subtitle_zh || '',
        hero_subtitle_en: res.data.hero_subtitle_en || '',
        hero_brand_text: res.data.hero_brand_text || 'CocoBrite',
        hero_title_zh: res.data.hero_title_zh || '',
        hero_title_en: res.data.hero_title_en || '',
        hero_text_zh: res.data.hero_text_zh || '',
        hero_text_en: res.data.hero_text_en || '',
        hero_image: res.data.hero_image || '',
        hero_detail_show: Number(res.data.hero_detail_show) === 1 ? 1 : 0,
        hero_detail_link_type: res.data.hero_detail_link_type || '',
        hero_detail_link_value: res.data.hero_detail_link_value || '',
      })
    } else {
      toast.error(res.msg || '加载失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('加载失败')
  } finally {
    loading.value = false
  }
}

const onHeroImageUpload = async (e) => {
  const file = e.target.files?.[0]
  e.target.value = ''
  if (!file) return
  uploading.value = true
  try {
    const res = await api.uploadImage(file)
    if (res.code === 0 && res.data?.url) {
      form.hero_image = res.data.url
      toast.success('图片已上传')
    } else {
      toast.error(res.msg || '上传失败')
    }
  } catch (err) {
    console.error(err)
    toast.error('上传失败')
  } finally {
    uploading.value = false
  }
}

const clearHeroImage = () => {
  form.hero_image = ''
}

const save = async () => {
  if (Number(form.hero_detail_show) === 1) {
    if (!form.hero_detail_link_type) {
      toast.error('请选择「查看详情」跳转目标')
      return
    }
    if (!String(form.hero_detail_link_value || '').trim()) {
      toast.error('请选择「查看详情」跳转的具体内容')
      return
    }
  }

  saving.value = true
  try {
    const payload = {
      hero_subtitle_zh: form.hero_subtitle_zh,
      hero_subtitle_en: form.hero_subtitle_en,
      hero_brand_text: form.hero_brand_text,
      hero_title_zh: form.hero_title_zh,
      hero_title_en: form.hero_title_en,
      hero_text_zh: form.hero_text_zh,
      hero_text_en: form.hero_text_en,
      hero_image: form.hero_image,
      hero_detail_show: form.hero_detail_show,
      hero_detail_link_type: form.hero_detail_link_type,
      hero_detail_link_value: form.hero_detail_link_value,
    }
    const res = await api.saveHomeAdminConfig(payload)
    if (res.code === 0) {
      toast.success('保存成功')
      if (res.data) {
        form.hero_image = res.data.hero_image || form.hero_image
      }
    } else {
      toast.error(res.msg || '保存失败')
    }
  } catch (e) {
    console.error(e)
    toast.error('保存失败')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadConfig(), loadLinkOptions()])
})
</script>

<style scoped>
.page-container {
  padding: 2rem;
  max-width: 960px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 1.5rem;
}

.page-title {
  margin: 0 0 0.35rem;
  font-size: 1.5rem;
  color: var(--color-primary-dark);
}

.page-subtitle {
  margin: 0;
  color: #6b7280;
  font-size: 0.92rem;
}

.card {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.08);
  padding: 1.5rem 2rem;
}

.loading-text {
  text-align: center;
  color: #6b7280;
}

.form-row {
  display: flex;
  gap: 1.25rem;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group.half {
  flex: 1;
}

.form-group label {
  display: block;
  margin-bottom: 0.4rem;
  font-weight: 500;
  color: #374151;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.65rem 0.85rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 0.95rem;
}

.hint {
  margin: 0.4rem 0 0;
  font-size: 0.82rem;
  color: #9ca3af;
}

.detail-section {
  margin-top: 1.5rem;
  padding-top: 1.25rem;
  border-top: 1px solid #f0f0f0;
}

.section-title {
  margin: 0 0 0.35rem;
  font-size: 1.05rem;
  color: var(--color-primary-dark);
}

.checkbox-row {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.75rem 0 1rem;
  font-weight: 500;
  color: #374151;
}

.select-input {
  width: 100%;
  padding: 0.65rem 0.85rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 0.95rem;
  background: #fff;
}

.hero-image-box {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 1rem;
}

.hero-preview {
  width: 280px;
  max-width: 100%;
  height: 160px;
  object-fit: cover;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.upload-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.55rem 1rem;
  border: 1px dashed #d1d5db;
  border-radius: 8px;
  cursor: pointer;
  color: #4b5563;
}

.btn-text {
  border: none;
  background: none;
  cursor: pointer;
  color: var(--color-primary);
}

.btn-text.danger {
  color: #dc2626;
}

.form-actions {
  margin-top: 0.5rem;
}

.btn-primary {
  background: var(--color-primary);
  color: #fff;
  border: none;
  padding: 0.65rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .form-row {
    flex-direction: column;
    gap: 0;
  }
}
</style>
