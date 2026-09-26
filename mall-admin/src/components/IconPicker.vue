<template>
  <div class="icon-picker">
    <div class="picker-preview">
      <div class="preview-box">
        <img v-if="preview.type === 'image'" :src="preview.src" alt="" />
        <i v-else :class="preview.class" aria-hidden="true"></i>
      </div>
      <div class="preview-meta">
        <span class="preview-label">{{ mode === 'image' ? '自定义图片' : '系统图标' }}</span>
        <code v-if="modelValue" class="preview-value">{{ displayValue }}</code>
        <span v-else class="preview-empty">未选择</span>
      </div>
      <button v-if="modelValue" type="button" class="btn-clear" @click="clear">清除</button>
    </div>

    <div class="picker-tabs">
      <button type="button" :class="{ active: mode === 'system' }" @click="mode = 'system'">系统图标</button>
      <button type="button" :class="{ active: mode === 'image' }" @click="mode = 'image'">上传图片</button>
    </div>

    <div v-if="mode === 'system'" class="picker-panel">
      <input
        v-model="search"
        type="search"
        class="icon-search"
        placeholder="搜索美妆图标，如：精华、彩妆、沐浴、礼盒…"
      />
      <div class="category-chips">
        <button
          v-for="cat in REMIX_ICON_CATEGORIES"
          :key="cat.id"
          type="button"
          class="chip"
          :class="{ active: activeCategory === cat.id }"
          @click="activeCategory = cat.id"
        >
          {{ cat.label }}
        </button>
      </div>
      <div class="icon-grid">
        <button
          v-for="opt in filteredIcons"
          :key="opt.class"
          type="button"
          class="icon-cell"
          :class="{ selected: modelValue === opt.class }"
          :title="opt.label"
          @click="selectClass(opt.class)"
        >
          <i :class="opt.class" aria-hidden="true"></i>
          <span>{{ opt.label }}</span>
        </button>
      </div>
      <p v-if="!filteredIcons.length" class="hint">无匹配图标</p>
    </div>

    <div v-else class="picker-panel">
      <div v-if="preview.type === 'image'" class="upload-preview">
        <img :src="preview.src" alt="" />
        <button type="button" class="btn-remove-img" @click="clear">移除图片</button>
      </div>
      <label class="upload-zone" :class="{ uploading }">
        <input type="file" accept="image/*" hidden :disabled="uploading" @change="onFileChange" />
        <i class="ri-upload-cloud-2-line"></i>
        <span>{{ uploading ? '上传中…' : '点击上传图标图片（PNG/SVG/JPG）' }}</span>
      </label>
      <p class="hint">建议正方形小图，前台将按图标尺寸显示</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { REMIX_ICON_OPTIONS, REMIX_ICON_CATEGORIES } from '../data/remixIcons.js'
import { resolveContentIcon, isContentIconUrl } from '../utils/contentIcon.js'
import { api } from '../api'
import { toast } from './Toast'

const props = defineProps({
  modelValue: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])

const mode = ref('system')
const search = ref('')
const activeCategory = ref('all')
const uploading = ref(false)

const preview = computed(() => resolveContentIcon(props.modelValue))
const displayValue = computed(() => {
  const v = props.modelValue || ''
  return v.length > 48 ? v.slice(0, 48) + '…' : v
})

const filteredIcons = computed(() => {
  let list = REMIX_ICON_OPTIONS
  if (activeCategory.value !== 'all') {
    list = list.filter((o) => o.category === activeCategory.value)
  }
  const q = search.value.trim().toLowerCase()
  if (!q) return list
  return list.filter(
    (o) => o.label.includes(q) || o.class.toLowerCase().includes(q)
  )
})

watch(
  () => props.modelValue,
  (v) => {
    mode.value = isContentIconUrl(v) ? 'image' : 'system'
  },
  { immediate: true }
)

function selectClass(cls) {
  emit('update:modelValue', cls)
}

function clear() {
  emit('update:modelValue', '')
}

async function onFileChange(e) {
  const file = e.target.files?.[0]
  e.target.value = ''
  if (!file) return
  uploading.value = true
  try {
    const res = await api.uploadImage(file)
    if (res.code === 0 && res.data?.url) {
      emit('update:modelValue', res.data.url)
      mode.value = 'image'
      toast.success('图标上传成功')
    } else {
      toast.error(res.msg || '上传失败')
    }
  } catch {
    toast.error('上传失败')
  } finally {
    uploading.value = false
  }
}
</script>

<style scoped>
.icon-picker { border: 1px solid #e5e7eb; border-radius: 10px; padding: 0.85rem; background: #fafafa; }
.picker-preview { display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.75rem; flex-wrap: wrap; }
.preview-box {
  width: 48px; height: 48px; border-radius: 10px; background: #fff; border: 1px solid #e5e7eb;
  display: flex; align-items: center; justify-content: center; font-size: 1.5rem; color: var(--color-primary, #8b6914);
  overflow: hidden;
}
.preview-box img { width: 100%; height: 100%; object-fit: contain; }
.preview-meta { flex: 1; min-width: 120px; }
.preview-label { display: block; font-size: 0.8rem; color: #666; margin-bottom: 0.2rem; }
.preview-value { font-size: 0.75rem; word-break: break-all; color: #374151; }
.preview-empty { font-size: 0.85rem; color: #999; }
.btn-clear { font-size: 0.8rem; padding: 0.35rem 0.65rem; border: 1px solid #e5e7eb; background: #fff; border-radius: 6px; cursor: pointer; }
.picker-tabs { display: flex; gap: 0.35rem; margin-bottom: 0.75rem; }
.picker-tabs button {
  flex: 1; padding: 0.45rem; border: 1px solid #e5e7eb; background: #fff; border-radius: 8px; cursor: pointer; font-size: 0.85rem;
}
.picker-tabs button.active { background: var(--color-primary, #8b6914); color: #fff; border-color: transparent; }
.icon-search { width: 100%; padding: 0.5rem 0.65rem; border: 1px solid #e5e7eb; border-radius: 8px; margin-bottom: 0.5rem; box-sizing: border-box; }
.category-chips {
  display: flex; flex-wrap: wrap; gap: 0.35rem; margin-bottom: 0.65rem;
}
.chip {
  padding: 0.25rem 0.55rem; font-size: 0.72rem; border: 1px solid #e5e7eb;
  background: #fff; border-radius: 999px; cursor: pointer; color: #6b7280;
}
.chip:hover { border-color: var(--color-accent, #c1a366); color: #374151; }
.chip.active {
  background: rgba(16, 185, 129, 0.12); border-color: var(--color-primary, #10b981);
  color: var(--color-primary-dark, #065f46); font-weight: 600;
}
.icon-grid {
  display: grid; grid-template-columns: repeat(auto-fill, minmax(72px, 1fr)); gap: 0.5rem;
  max-height: 220px; overflow-y: auto;
}
.icon-cell {
  display: flex; flex-direction: column; align-items: center; gap: 0.25rem; padding: 0.5rem 0.25rem;
  border: 1px solid #e5e7eb; border-radius: 8px; background: #fff; cursor: pointer; font-size: 0.65rem; color: #666;
}
.icon-cell i { font-size: 1.35rem; color: #374151; }
.icon-cell:hover { border-color: var(--color-primary, #c1a366); }
.icon-cell.selected { border-color: var(--color-primary, #8b6914); background: rgba(193, 163, 102, 0.12); }
.upload-zone {
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 0.5rem;
  padding: 1.5rem; border: 2px dashed #d1d5db; border-radius: 10px; background: #fff; cursor: pointer; text-align: center;
  font-size: 0.85rem; color: #666;
}
.upload-zone i { font-size: 2rem; color: #9ca3af; }
.upload-zone.uploading { opacity: 0.6; pointer-events: none; }
.upload-preview { text-align: center; margin-bottom: 0.75rem; }
.upload-preview img { max-width: 80px; max-height: 80px; object-fit: contain; border-radius: 8px; }
.btn-remove-img { margin-top: 0.5rem; font-size: 0.8rem; color: #b91c1c; background: none; border: none; cursor: pointer; }
.hint { font-size: 0.78rem; color: #9ca3af; margin: 0.5rem 0 0; }
</style>
