<script setup>
import { useI18n } from 'vue-i18n'
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHead } from '@unhead/vue'
import { api } from '../api'
import { PRODUCT_CATEGORY_LIST } from '../api/cocobrite-data'
import ProductListEmptyFlowDiagram from '../components/ProductListEmptyFlowDiagram.vue'
import { productListEmptyFlowLabels } from '../locales/productListEmpty'
import { pickLocalized, categoryFilterKey, categoryDisplayName } from '../utils/localeDisplay.js'

const { locale } = useI18n()
const emptyFlow = computed(() => productListEmptyFlowLabels(locale.value))

const route = useRoute()
const router = useRouter()

const categories = ref(
  PRODUCT_CATEGORY_LIST.map((name) => ({ key: name, name, name_en: null }))
)

const categoryLabelForKey = (key) => {
  const k = String(key || '')
  const row = categories.value.find((c) => categoryFilterKey(c) === k)
  return row ? categoryDisplayName(locale.value, row) : k
}
const products = ref([])
const loading = ref(false)
/** 接口失败（与「空列表」区分） */
const fetchError = ref(false)
const currentPage = ref(1)
const pageSize = ref(12)
const total = ref(0)
const fallbackImg = 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800&q=80&auto=format&fit=crop'

const activeCategory = computed(() => {
  const c = route.query.category
  return typeof c === 'string' && c ? c : ''
})

useHead({
  title: () =>
    (activeCategory.value ? `${categoryLabelForKey(activeCategory.value)} | Shop` : 'Shop All') + ' | CocoBrite',
  meta: [
    {
      name: 'description',
      content: 'Browse CocoBrite body care by category — lotions, bath, hands, and gift sets for customers worldwide.',
    },
  ],
})

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / pageSize.value)))

/** 列表主区域 UI：加载 / 失败 / 空 / 有数据（互斥） */
const listUiState = computed(() => {
  if (loading.value) return 'loading'
  if (fetchError.value) return 'error'
  if (products.value.length === 0) return 'empty'
  return 'ready'
})

const loadCategories = async () => {
  try {
    const res = await api.getProductCategories()
    if (res.code === 0 && Array.isArray(res.data) && res.data.length) {
      categories.value = res.data
    }
  } catch (_) {
    /* 使用默认 PRODUCT_CATEGORY_LIST */
  }
}

const fetchProducts = async () => {
  loading.value = true
  fetchError.value = false
  try {
    const params = {
      page: currentPage.value,
      limit: pageSize.value,
      status: 1,
    }
    if (activeCategory.value) params.category = activeCategory.value

    const res = await api.getProducts(params)
    if (res.code !== 0) {
      fetchError.value = true
      products.value = []
      total.value = 0
      return
    }

    const payload = res.data
    if (Array.isArray(payload)) {
      products.value = payload
      total.value = payload.length
      return
    }
    if (payload?.list) {
      products.value = payload.list
      total.value = payload.total
      return
    }
    if (payload?.data && Array.isArray(payload.data)) {
      products.value = payload.data
      total.value = payload.total ?? payload.data.length
      return
    }
    if (payload?.data?.data && Array.isArray(payload.data.data)) {
      products.value = payload.data.data
      total.value = payload.data.total
    }
  } catch (e) {
    console.error(e)
    fetchError.value = true
    products.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

const setCategory = (cat) => {
  const q = cat ? { category: cat } : {}
  router.push({ path: '/products', query: q })
}

watch(
  () => route.query.category,
  () => {
    currentPage.value = 1
  }
)

watch([currentPage, () => route.query.category], () => {
  fetchProducts()
}, { immediate: true })

onMounted(() => {
  loadCategories()
})

const goToProduct = (id) => {
  router.push(`/product/${id}`)
}

const changePage = (page) => {
  if (page < 1 || page > totalPages.value) return
  currentPage.value = page
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const handleImgError = (e) => {
  const img = e.target
  if (img.dataset.retry) {
    img.src =
      'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxIDEiPjxyZWN0IHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFQkU2RDgiLz48L3N2Zz4='
    return
  }
  img.dataset.retry = 'true'
  img.src = fallbackImg
}
</script>

<template>
  <div class="page-container product-list-page">
    

    <div v-if="listUiState === 'loading'" class="loading">{{ $t('productList.loading') }}</div>

    <div v-else-if="listUiState === 'error'" class="error-panel" role="alert">
      <p class="error-title">{{ $t('productList.errorTitle') }}</p>
      <p class="error-desc">{{ $t('productList.errorDesc') }}</p>
      <button type="button" class="retry-btn" @click="fetchProducts">{{ $t('productList.retry') }}</button>
    </div>

    <div v-else-if="listUiState === 'empty'" class="empty-state">
      <div class="empty-frame">
        <p class="empty-title">{{ activeCategory ? $t('productList.emptyWithCat', { cat: categoryLabelForKey(activeCategory) }) : $t('productList.emptyNoProducts') }}</p>
        <p class="empty-desc">{{ $t('productList.emptyDesc') }}</p>
        <ProductListEmptyFlowDiagram
          :step1="emptyFlow.step1"
          :step2="emptyFlow.step2"
          :step3="emptyFlow.step3"
          :diagram-aria="emptyFlow.diagramAria"
        />
        <button v-if="activeCategory" type="button" class="empty-action" @click="setCategory('')">
          {{ $t('productList.viewAllCategories') }}
        </button>
      </div>
    </div>

    <div v-else class="product-grid">
      <article v-for="product in products" :key="product.id" class="product-card">
        <div class="card-image-container" @click="goToProduct(product.id)">
          <img
            :src="product.image"
            :alt="pickLocalized(locale, product.name, product.name_en)"
            class="card-image"
            loading="lazy"
            @error="handleImgError"
          />
          <div class="card-overlay">
            <button type="button" class="quick-view-btn" @click.stop="goToProduct(product.id)">{{ $t('productList.viewDetail') }}</button>
          </div>
        </div>
        <div class="card-info">
          <div class="card-category">{{ categoryLabelForKey(product.category) }}</div>
          <h3 class="card-title">{{ pickLocalized(locale, product.name, product.name_en) }}</h3>
          <div class="card-price"><span class="currency">¥</span>{{ product.price }}</div>
        </div>
      </article>
    </div>

    <div v-if="listUiState === 'ready' && totalPages > 1" class="pagination">
      <button type="button" class="page-btn" :disabled="currentPage === 1" @click="changePage(currentPage - 1)">
        <i class="ri-arrow-left-s-line"></i>
      </button>
      <span class="page-info">{{ currentPage }} / {{ totalPages }}</span>
      <button
        type="button"
        class="page-btn"
        :disabled="currentPage === totalPages"
        @click="changePage(currentPage + 1)"
      >
        <i class="ri-arrow-right-s-line"></i>
      </button>
    </div>
  </div>
</template>

<style scoped>
.product-list-page {
  padding-top: 6rem;
  max-width: 1280px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 2rem;
}

.page-title {
  font-size: 2rem;
  letter-spacing: 0.12em;
  margin-bottom: 0.5rem;
}

.page-subtitle {
  color: var(--text-secondary);
  font-size: 0.95rem;
  letter-spacing: 0.06em;
}

.category-bar {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 0.6rem;
  margin-bottom: 2.5rem;
  padding: 0 1rem;
}

.chip {
  border: 1px solid var(--border-color);
  background: var(--surface-color);
  color: var(--text-secondary);
  padding: 0.45rem 1rem;
  border-radius: 999px;
  font-size: 0.85rem;
  letter-spacing: 0.06em;
  cursor: pointer;
  transition: all 0.25s ease;
}

.chip:hover {
  border-color: var(--accent-color);
  color: var(--primary-color);
}

.chip.active {
  background: var(--primary-color);
  color: #fdf8f4;
  border-color: var(--primary-color);
}

.loading {
  text-align: center;
  padding: 3rem;
  color: var(--text-secondary);
}

.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 2rem;
  padding: 0 1.5rem 3rem;
}

.product-card {
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  transition: box-shadow 0.3s ease;
}

.product-card:hover {
  box-shadow: var(--shadow-hover);
}

.card-image-container {
  position: relative;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  cursor: pointer;
}

.card-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.5s ease;
}

.product-card:hover .card-image {
  transform: scale(1.04);
}

.card-overlay {
  position: absolute;
  inset: 0;
  background: rgba(45, 31, 26, 0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.35s ease;
}

.product-card:hover .card-overlay {
  opacity: 1;
}

.quick-view-btn {
  background: transparent;
  color: #fff;
  border: 1px solid #fff;
  padding: 0.6rem 1.4rem;
  letter-spacing: 0.15em;
  font-size: 0.75rem;
  cursor: pointer;
}

.card-info {
  padding: 1.25rem 1rem 1.5rem;
}

.card-category {
  font-size: 0.7rem;
  color: var(--accent-color);
  letter-spacing: 0.15em;
  text-transform: uppercase;
  margin-bottom: 0.35rem;
}

.card-title {
  font-size: 1.05rem;
  margin: 0 0 0.75rem;
  line-height: 1.45;
}

.card-price {
  font-family: var(--font-display);
  color: var(--primary-color);
  font-size: 1.1rem;
}

.currency {
  font-size: 0.85rem;
  margin-right: 0.15rem;
}

.error-panel {
  text-align: center;
  padding: 3rem 1.5rem 4rem;
  max-width: 24rem;
  margin: 0 auto;
}

.error-title {
  font-family: var(--font-serif);
  font-size: 1.15rem;
  color: var(--primary-color);
  margin: 0 0 0.5rem;
}

.error-desc {
  color: var(--text-secondary);
  font-size: 0.9rem;
  margin: 0 0 1.25rem;
}

.retry-btn {
  border: 1px solid var(--primary-color);
  background: var(--surface-color);
  color: var(--primary-color);
  padding: 0.5rem 1.35rem;
  border-radius: 999px;
  font-size: 0.85rem;
  letter-spacing: 0.08em;
  cursor: pointer;
}

.retry-btn:hover {
  background: var(--primary-color);
  color: #fdf8f4;
}

.empty-state {
  display: flex;
  justify-content: center;
  padding: 2rem 1rem 4rem;
}

.empty-frame {
  max-width: 22rem;
  width: 100%;
  text-align: center;
  padding: 2rem 1.5rem;
  border: 1px solid rgba(45, 31, 26, 0.22);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.65);
  box-shadow: 0 8px 28px rgba(45, 31, 26, 0.06);
}

.empty-title {
  font-family: var(--font-serif);
  font-size: 1.05rem;
  color: var(--primary-color);
  margin: 0 0 0.5rem;
  letter-spacing: 0.06em;
}

.empty-desc {
  font-size: 0.88rem;
  color: var(--text-secondary);
  margin: 0 0 0.25rem;
  line-height: 1.55;
}

.empty-action {
  border: 1px solid var(--border-color);
  background: var(--surface-color);
  color: var(--primary-color);
  padding: 0.45rem 1.1rem;
  border-radius: 999px;
  font-size: 0.82rem;
  letter-spacing: 0.1em;
  cursor: pointer;
}

.empty-action:hover {
  border-color: var(--accent-color);
}

.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1.25rem;
  padding-bottom: 4rem;
}

.page-btn {
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  width: 40px;
  height: 40px;
  border-radius: 50%;
  cursor: pointer;
  color: var(--primary-color);
}

.page-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.page-info {
  font-size: 0.9rem;
  color: var(--text-secondary);
  letter-spacing: 0.08em;
}
</style>
