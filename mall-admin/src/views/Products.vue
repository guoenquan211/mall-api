<template>
  <div class="products-view">
    <div class="header-action">
      <div class="page-title">
        <h1>商品管理</h1>
        <span class="subtitle">管理您的商品库存与价格</span>
      </div>
      <button class="btn-primary" type="button" @click="openModal()">
        <i class="ri-add-line"></i> 发布新商品
      </button>
    </div>
    
    <div class="card table-container">
      <table class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>商品信息</th>
            <th>分类</th>
            <th>价格</th>
            <th>库存</th>
            <th>首页</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="product in products" :key="product.id">
            <td class="text-muted">#{{ product.id }}</td>
            <td>
              <div class="product-cell">
                <div class="thumb-wrapper">
                  <img :src="product.image" class="thumb" :alt="product.name" />
                </div>
                <div class="product-info-col">
                  <span class="product-name">{{ product.name }}</span>
                  <span v-if="product.name_en" class="product-name-en">{{ product.name_en }}</span>
                  <span class="product-specs-hint" v-if="product.variants && product.variants.length">
                    {{ product.variants.length }}种规格
                  </span>
                </div>
              </div>
            </td>
            <td><span class="badge">{{ product.category }}</span></td>
            <td class="price">
              <span v-if="product.variants && product.variants.length">
                <span class="text-xs">起</span> ₱ {{ getMinPrice(product) }}
              </span>
              <span v-else>₱ {{ product.price }}</span>
            </td>
            <td>
              <span :class="['stock-status', product.stock < 10 ? 'low' : 'normal']">
                {{ product.stock }}
              </span>
            </td>
            <td>
              <span class="badge muted" v-if="Number(product.show_on_home) !== 1">否</span>
              <span class="badge" v-else>是</span>
            </td>
            <td>
              <div class="action-group">
                <button class="btn-icon" type="button" @click.stop="openModal(product)" title="编辑">
                  <i class="ri-edit-line"></i>
                </button>
                <button class="btn-icon danger" type="button" @click.stop="handleDelete(product.id)" title="删除">
                  <i class="ri-delete-bin-line"></i>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal：Teleport 避免被主布局层叠/裁剪挡住；Quill 用 key 强制重挂载避免编辑态卡死 -->
    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay admin-product-dialog-overlay" @click.self="closeModal">
        <div class="modal card admin-product-dialog-panel" @click.stop>
        <div class="modal-header">
          <h3>{{ isEdit ? '编辑商品' : '发布新商品' }}</h3>
          <button class="close-btn" @click="closeModal"><i class="ri-close-line"></i></button>
        </div>
        
        <div class="modal-body">
          <div class="form-row">
            <div class="form-group half">
              <label>商品名称（繁體）</label>
              <input v-model="form.name" placeholder="繁體中文品名" />
            </div>
            <div class="form-group half">
              <label>品名（English）</label>
              <input v-model="form.name_en" placeholder="English name (optional)" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group half">
              <label>分类</label>
              <select v-model="form.category" class="category-select">
                <option value="">请选择分类</option>
                <option
                  v-if="legacyCategoryOption"
                  :value="legacyCategoryOption"
                >{{ legacyCategoryOption }}（未在分类管理中，保存前请到「商品分类」添加或改选）</option>
                <option v-for="c in productCategories" :key="c.id ?? c.name" :value="c.name">
                  {{ c.name }}<template v-if="c.name_en"> — {{ c.name_en }}</template>
                </option>
              </select>
            </div>
            <div class="form-group half"></div>
          </div>
          
          <div class="form-row">
            <div class="form-group half">
              <label>展示价格 (₱) <span v-if="hasVariants" class="hint-text">(自动计算最低价)</span></label>
              <input type="number" v-model="form.price" :readonly="hasVariants" :class="{readonly: hasVariants}" />
            </div>
            <div class="form-group half">
              <label>总库存 <span v-if="hasVariants" class="hint-text">(自动计算)</span></label>
              <input type="number" v-model="form.stock" :readonly="hasVariants" :class="{readonly: hasVariants}" />
            </div>
          </div>

          <div class="form-group checkbox-row">
            <label class="inline-check">
              <input type="checkbox" :checked="Number(form.show_on_home) === 1" @change="form.show_on_home = $event.target.checked ? 1 : 0" />
              在首页「本季主推」展示
            </label>
            <p class="hint-text">仅勾选且上架的商品会出现在前台首页主推区；默认不勾选。</p>
          </div>

          <div class="form-group">
            <label>商品详情（繁體）</label>
            <div class="editor-wrapper">
              <RichTextEditor
                :key="quillEditorKey"
                v-model="form.description"
              />
            </div>
          </div>
          <div class="form-group">
            <label>商品详情（English）</label>
            <div class="editor-wrapper">
              <RichTextEditor
                :key="`${quillEditorKey}-en`"
                v-model="form.description_en"
              />
            </div>
          </div>

          <!-- Variants Section -->
          <div class="variants-section">
            <div class="section-header">
              <label>多规格管理 (SKU)</label>
              <button class="btn-text" @click="addVariant">
                <i class="ri-add-circle-line"></i> 添加规格
              </button>
            </div>
            
            <div class="variants-list" v-if="form.variants && form.variants.length > 0">
              <div class="variant-item" v-for="(variant, index) in form.variants" :key="index">
                <div class="v-img-wrapper" @click="triggerVariantUpload(index)" title="上传规格图">
                  <img v-if="variant.image" :src="variant.image" class="v-img" />
                  <div v-else class="v-img-placeholder">
                    <i class="ri-image-add-line"></i>
                  </div>
                  <input
                    type="file"
                    :ref="setVariantFileInputRef(index)"
                    @change="(e) => handleVariantImage(e, index)"
                    hidden
                    accept="image/*"
                  />
                </div>
                <div class="v-input-group name">
                  <input v-model="variant.name" placeholder="规格名 (如: 2苗带花)" />
                </div>
                <div class="v-input-group price">
                  <span class="prefix">₱</span>
                  <input type="number" v-model="variant.price" placeholder="价格" @input="updateTotals" />
                </div>
                <div class="v-input-group stock">
                  <span class="prefix">库</span>
                  <input type="number" v-model="variant.stock" placeholder="库存" @input="updateTotals" />
                </div>
                <button class="btn-icon danger sm" @click="removeVariant(index)">
                  <i class="ri-delete-bin-line"></i>
                </button>
              </div>
            </div>
            <div class="empty-variants" v-else>
              暂无规格，将使用上方统一价格和库存
            </div>
          </div>
          
          <div class="form-group">
            <label>商品图片 <span class="hint-text">(第一张为主图，支持多张)</span></label>
            <div class="images-grid">
              <!-- Existing Images -->
              <div class="image-item" v-for="(img, index) in form.images" :key="index">
                <img :src="img" alt="Product Image" />
                <div class="image-actions">
                  <span v-if="index === 0" class="main-tag">主图</span>
                  <button class="remove-btn" @click="removeImage(index)">
                    <i class="ri-delete-bin-line"></i>
                  </button>
                </div>
              </div>
              
              <!-- Upload Button -->
              <label class="image-upload-btn">
                <input type="file" @change="handleImageUpload" accept="image/*" multiple hidden />
                <i class="ri-add-line"></i>
                <span>添加图片</span>
              </label>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-secondary" @click="closeModal">取消</button>
          <button class="btn-primary" @click="handleSave">
            <i class="ri-save-line"></i> 保存
          </button>
        </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'
import RichTextEditor from '../components/RichTextEditor.vue'
import { normalizeRichHtmlStorage } from '../utils/richHtml.js'

const products = ref([])
const productCategories = ref([])
const showModal = ref(false)
const isEdit = ref(false)
/** 每次打开弹窗递增，强制 Quill 重挂载，避免详情加载后编辑器不更新/报错导致整页异常 */
const quillEditorKey = ref(0)
const form = reactive({
  id: null,
  name: '',
  name_en: '',
  category: '',
  description: '',
  description_en: '',
  price: 0,
  stock: 0,
  show_on_home: 0,
  images: [],
  variants: []
})

const hasVariants = computed(() => form.variants && form.variants.length > 0)
const mainImage = computed(() => form.images && form.images.length > 0 ? form.images[0] : '')

const legacyCategoryOption = computed(() => {
  const names = new Set(productCategories.value.map((c) => c.name))
  const cur = String(form.category || '').trim()
  if (!cur || names.has(cur)) return ''
  return cur
})

const fetchProducts = async () => {
  const res = await api.getProducts()
  if (res.code === 0) {
    products.value = res.data.data ? res.data.data : res.data // Handle pagination response
  }
}

const loadProductCategories = async () => {
  try {
    const res = await api.listProductCategories()
    if (res.code === 0) {
      productCategories.value = Array.isArray(res.data) ? res.data : []
    }
  } catch (_) {
    /* 弹窗仍应能打开，分类下拉稍后重试或为空 */
  }
}

/** 规格行隐藏 file input 的 ref（模板中曾用未定义的 variantInputs，会导致带规格商品无法渲染弹窗） */
const variantFileInputs = ref({})
const setVariantFileInputRef = (index) => (el) => {
  if (el) variantFileInputs.value[index] = el
  else delete variantFileInputs.value[index]
}

const triggerVariantUpload = (index) => {
  variantFileInputs.value[index]?.click()
}

const handleVariantImage = async (e, index) => {
  const input = e.target
  const file = input?.files?.[0]
  if (input) input.value = ''
  if (!file || !form.variants[index]) return
  try {
    const res = await api.uploadImage(file)
    if (res.code === 0 && res.data?.url) {
      form.variants[index].image = res.data.url
    } else {
      toast.error(res?.msg || '规格图上传失败')
    }
  } catch (err) {
    console.error(err)
    toast.error('规格图上传失败')
  }
}

const getMinPrice = (product) => {
  if (!product.variants || product.variants.length === 0) return product.price
  return Math.min(...product.variants.map(v => v.price))
}

const isOk = (res) => res && (Number(res.code) === 0 || res.code === 0)

const openModal = async (product = null) => {
  try {
    /* 不阻塞弹窗：分类接口慢/挂起时，原先 await 会导致按钮「完全无反应」 */
    loadProductCategories().catch(() => {})
    if (product) {
      isEdit.value = true
      const res = await api.getProduct(product.id)
      if (!isOk(res)) {
        toast.error(res?.msg || '加载商品详情失败')
        return
      }
      const data = res.data
      if (!data || typeof data !== 'object') {
        toast.error('商品详情数据异常')
        return
      }
      // 多图：可能是 { image: url } 行记录
      if (data.images && data.images.length > 0 && typeof data.images[0] === 'object') {
        data.images = data.images.map((img) => (img && typeof img === 'object' ? img.image : img)).filter(Boolean)
      } else if (!data.images || data.images.length === 0) {
        data.images = data.image ? [data.image] : []
      }
      if (!data.variants) data.variants = []
      if (data.description == null) data.description = ''
      if (data.description_en == null) data.description_en = ''
      Object.assign(form, data)
      form.show_on_home = Number(data.show_on_home) === 1 ? 1 : 0
      quillEditorKey.value++
    } else {
      isEdit.value = false
      Object.assign(form, {
        id: null,
        name: '',
        name_en: '',
        category: '',
        description: '',
        description_en: '',
        price: 0,
        stock: 0,
        show_on_home: 0,
        image: '',
        images: [],
        variants: []
      })
      quillEditorKey.value++
    }
    showModal.value = true
  } catch (e) {
    console.error(e)
    toast.error(e?.message || '打开编辑窗口失败')
  }
}

const closeModal = () => {
  showModal.value = false
}

const addVariant = () => {
  form.variants.push({
    name: '',
    price: form.price || 0,
    stock: 1
  })
  updateTotals()
}

const removeVariant = (index) => {
  form.variants.splice(index, 1)
  updateTotals()
}

const updateTotals = () => {
  if (form.variants.length > 0) {
    // Auto calculate total stock and min price
    form.stock = form.variants.reduce((sum, v) => sum + Number(v.stock || 0), 0)
    // Find min price greater than 0, or just 0
    const prices = form.variants.map(v => Number(v.price || 0))
    form.price = Math.min(...prices)
  }
}

const removeImage = (index) => {
  form.images.splice(index, 1)
}

const handleImageUpload = async (e) => {
  const files = Array.from(e.target.files)
  if (files.length === 0) return
  
  for (const file of files) {
    try {
      const res = await api.uploadImage(file)
      if (res.code === 0) {
        form.images.push(res.data.url)
      }
    } catch (e) {
      console.error('Upload failed', e)
      // Continue uploading other files even if one fails
    }
  }
}

const handleSave = async () => {
  if (!String(form.name || '').trim() && !String(form.name_en || '').trim()) {
    toast.warning('请填写繁體中文品名或英文品名至少一项')
    return
  }
  if (!String(form.category || '').trim()) {
    toast.warning('请选择商品分类')
    return
  }
  // Final validation or cleanup
  if (hasVariants.value) {
    updateTotals()
  }
  
  // Sync first image to main image field for compatibility
  form.image = form.images.length > 0 ? form.images[0] : ''
  
  const res = await api.saveProduct({
    ...form,
    description: normalizeRichHtmlStorage(form.description),
    description_en: normalizeRichHtmlStorage(form.description_en),
  })
  if (res.code === 0) {
    closeModal()
    fetchProducts()
  } else {
    toast.error(res.msg || '保存失败')
  }
}

const handleDelete = async (id) => {
  if (confirm('确定要删除吗？')) {
    const res = await api.deleteProduct(id)
    if (res.code === 0) {
      fetchProducts()
    }
  }
}

onMounted(() => {
  fetchProducts()
})
</script>

<style scoped>
.products-view {
  animation: fadeIn 0.5s ease;
}

.header-action {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
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

.table-container {
  overflow-x: auto;
  padding: 0; /* Let table fill the card */
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th {
  background: #f8f9fa;
  padding: 1rem 1.5rem;
  text-align: left;
  font-weight: 600;
  color: var(--color-text-muted);
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.data-table td {
  padding: 1rem 1.5rem;
  border-bottom: 1px solid var(--color-border);
  vertical-align: middle;
}

.data-table tr:last-child td {
  border-bottom: none;
}

.data-table tr:hover {
  background-color: #fafafa;
}

.product-cell {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.product-info-col {
  display: flex;
  flex-direction: column;
}

.product-specs-hint {
  font-size: 0.75rem;
  color: var(--color-primary);
  background: rgba(30, 71, 58, 0.08);
  padding: 2px 6px;
  border-radius: 4px;
  width: fit-content;
  margin-top: 4px;
}

.thumb-wrapper {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: var(--shadow-sm);
  background: #f0f0f0;
}

.thumb {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-name {
  font-weight: 500;
  color: var(--color-primary-dark);
}

.product-name-en {
  display: block;
  font-size: 0.8rem;
  color: #6b7280;
  font-weight: 400;
  margin-top: 2px;
}

.text-muted {
  color: #999;
  font-size: 0.85rem;
}

.badge {
  background: #eef2f5;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

.badge.muted {
  background: #f3f3f3;
  color: #888;
}

.checkbox-row .inline-check {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 500;
  cursor: pointer;
}

.checkbox-row .inline-check input {
  width: 1rem;
  height: 1rem;
  cursor: pointer;
}

.price {
  font-family: var(--font-sans);
  font-weight: 600;
  color: var(--color-accent);
}

.text-xs {
  font-size: 0.75rem;
  font-weight: 400;
  color: #888;
}

.stock-status {
  font-size: 0.9rem;
}

.stock-status.low {
  color: #cf1322;
  font-weight: 600;
}

.action-group {
  display: flex;
  gap: 0.5rem;
}

.btn-icon {
  background: none;
  border: none;
  width: 32px;
  height: 32px;
  border-radius: 4px;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-icon.sm {
  width: 24px;
  height: 24px;
  font-size: 0.9rem;
}

.btn-icon:hover {
  background: #f0f0f0;
  color: var(--color-primary-dark);
}

.btn-icon.danger:hover {
  background: #fff1f0;
  color: #cf1322;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1100;
  animation: fadeIn 0.2s ease;
}

.modal {
  width: 800px;
  max-width: 95%;
  padding: 0;
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  flex-direction: column;
  max-height: 90vh;
}

.modal-header {
  padding: 1.5rem;
  border-bottom: 1px solid var(--color-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  font-size: 1.25rem;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.25rem;
  color: var(--color-text-muted);
  cursor: pointer;
}

.modal-body {
  padding: 1.5rem;
  overflow-y: auto;
}

.form-row {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group.half {
  flex: 1;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  font-size: 0.9rem;
  color: var(--color-text-main);
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 0.65rem 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  font-size: 0.95rem;
  box-sizing: border-box;
}

.form-group select:focus,
.form-group input:focus {
  outline: none;
  border-color: var(--color-primary);
}

.hint-text {
  font-weight: 400;
  color: var(--color-accent);
  font-size: 0.8rem;
  margin-left: 0.5rem;
}

input.readonly {
  background-color: #f5f5f5;
  color: #888;
  cursor: not-allowed;
}

/* Variants Section Styles */
.variants-section {
  background: #fcfcfc;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 1rem;
  margin-bottom: 1.5rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.section-header label {
  font-weight: 600;
  font-size: 0.95rem;
  color: var(--color-primary-dark);
}

.editor-wrapper {
  background: white;
  border-radius: 8px;
  overflow: hidden;
}

:deep(.ql-container) {
  min-height: 200px;
  font-size: 1rem;
}

:deep(.ql-toolbar) {
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
}

:deep(.ql-container.ql-snow) {
  border-bottom-left-radius: 8px;
  border-bottom-right-radius: 8px;
}

.btn-text {
  background: none;
  border: none;
  color: var(--color-primary);
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.9rem;
}

.btn-text:hover {
  text-decoration: underline;
}

.variants-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.variant-item {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.v-input-group {
  position: relative;
}

.v-input-group.name {
  flex: 2;
}

.v-input-group.price, .v-input-group.stock {
  flex: 1;
}

.v-input-group input {
  width: 100%;
  padding-left: 0.5rem;
}

.v-input-group.price input {
  padding-left: 1.2rem;
}

.v-input-group.stock input {
  padding-left: 1.5rem;
}

.v-input-group .prefix {
  position: absolute;
  left: 0.4rem;
  top: 50%;
  transform: translateY(-50%);
  color: #999;
  font-size: 0.8rem;
}

.empty-variants {
  text-align: center;
  color: #aaa;
  font-size: 0.85rem;
  padding: 1rem 0;
  border: 1px dashed #eee;
  border-radius: 4px;
}

.modal-footer {
  padding: 1rem 1.5rem;
  border-top: 1px solid var(--color-border);
  background: #f9f9f9;
  border-bottom-left-radius: var(--radius-lg);
  border-bottom-right-radius: var(--radius-lg);
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.v-img-wrapper {
  width: 38px;
  height: 38px;
  border-radius: 4px;
  overflow: hidden;
  cursor: pointer;
  border: 1px dashed #ddd;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: white;
  transition: all 0.2s;
}

.v-img-wrapper:hover {
  border-color: var(--color-primary);
  background: #f0f7f4;
}

.v-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.v-img-placeholder {
  color: #ccc;
  font-size: 1.2rem;
}

.v-img-wrapper:hover .v-img-placeholder {
  color: var(--color-primary);
}

.images-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 1rem;
  margin-top: 0.5rem;
}

.image-item {
  position: relative;
  aspect-ratio: 1;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--color-border);
}

.image-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.image-actions {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
}

.image-item:hover .image-actions {
  opacity: 1;
}

.main-tag {
  position: absolute;
  top: 4px;
  left: 4px;
  background: var(--color-primary);
  color: white;
  font-size: 0.7rem;
  padding: 2px 6px;
  border-radius: 4px;
  z-index: 2;
}

.remove-btn {
  background: white;
  border: none;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  color: #cf1322;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.2rem;
  transition: transform 0.2s;
}

.remove-btn:hover {
  transform: scale(1.1);
}

.image-upload-btn {
  aspect-ratio: 1;
  border: 2px dashed var(--color-border);
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: var(--color-text-muted);
  transition: all 0.2s;
  background: #fafafa;
}

.image-upload-btn:hover {
  border-color: var(--color-primary);
  background: #f0f7f4;
  color: var(--color-primary);
}

.image-upload-btn i {
  font-size: 1.5rem;
  margin-bottom: 0.25rem;
}

.image-upload-btn span {
  font-size: 0.8rem;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
</style>

<style>
/* Teleport 到 body：遮罩层级独立于 .content-area，避免被裁剪或压在侧栏之下 */
.admin-product-dialog-overlay {
  position: fixed !important;
  inset: 0 !important;
  z-index: 10050 !important;
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
}

.admin-product-dialog-panel {
  position: relative;
  z-index: 1;
}
</style>
