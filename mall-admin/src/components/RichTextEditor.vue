<template>
  <div class="rich-text-editor">
    <QuillEditor
      :key="editorKey"
      theme="snow"
      :content="modelValue"
      content-type="html"
      :toolbar="toolbar"
      :placeholder="placeholder"
      @update:content="onContentUpdate"
      @ready="onReady"
    />
  </div>
</template>

<script setup>
import { nextTick, watch } from 'vue'
import { QuillEditor } from '@vueup/vue-quill'
import '@vueup/vue-quill/dist/vue-quill.snow.css'
import { api } from '../api'
import { toast } from './Toast'
import { normalizeStoragePath, resolveRichHtml } from '../utils/richHtml.js'

const props = defineProps({
  modelValue: { type: String, default: '' },
  editorKey: { type: [String, Number], default: 0 },
  placeholder: { type: String, default: '' },
})

const emit = defineEmits(['update:modelValue'])

const toolbar = [
  [{ header: [1, 2, false] }],
  ['bold', 'italic', 'underline'],
  [{ list: 'ordered' }, { list: 'bullet' }],
  [{ align: [] }],
  ['link', 'image'],
  ['clean'],
]

let quillInstance = null

function fixImagesInEditor(quill) {
  quill.root.querySelectorAll('img').forEach((img) => {
    const src = img.getAttribute('src')
    if (!src) return
    const resolved = resolveRichHtml(`<img src="${src}">`)
    const match = resolved.match(/src="([^"]+)"/)
    if (match) {
      img.setAttribute('src', match[1])
    }
  })
}

function onReady(quill) {
  quillInstance = quill
  quill.getModule('toolbar').addHandler('image', () => pickAndUploadImage(quill))
  fixImagesInEditor(quill)
}

function pickAndUploadImage(quill) {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/jpeg,image/png,image/gif,image/webp'
  input.onchange = async () => {
    const file = input.files?.[0]
    if (!file) return
    try {
      const res = await api.uploadImage(file)
      if (res.code !== 0) {
        toast.error(res.msg || '图片上传失败')
        return
      }
      const path = normalizeStoragePath(res.data.url)
      const displayUrl = resolveRichHtml(`<img src="${path}">`).match(/src="([^"]+)"/)?.[1] || path
      const range = quill.getSelection(true)
      const index = range?.index ?? quill.getLength()
      quill.insertEmbed(index, 'image', displayUrl)
      quill.setSelection(index + 1)
    } catch (e) {
      console.error(e)
      toast.error('图片上传失败')
    }
  }
  input.click()
}

function onContentUpdate(content) {
  emit('update:modelValue', content === '<p><br></p>' ? '' : content)
}

watch(
  () => props.modelValue,
  () => {
    nextTick(() => {
      if (quillInstance) fixImagesInEditor(quillInstance)
    })
  }
)
</script>

<style scoped>
.rich-text-editor :deep(.ql-container) {
  min-height: 180px;
  font-size: 0.95rem;
}

.rich-text-editor :deep(.ql-editor img) {
  max-width: 100%;
  height: auto;
  display: block;
  margin: 0.5rem 0;
  border-radius: 4px;
}
</style>
