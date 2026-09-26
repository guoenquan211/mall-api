<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useHead } from '@unhead/vue'
import { useI18n } from 'vue-i18n'
import { api } from '../api'
import { pickLocalized, categoryFilterKey, categoryDisplayName } from '../utils/localeDisplay.js'

const { locale } = useI18n()

const products = ref([])
const currentPage = ref(1)
const pageSize = ref(8)
const total = ref(0)
const loading = ref(false)
const router = useRouter()
const fallbackImg = 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800&q=80&auto=format&fit=crop'
const heroImg = 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=1600&q=80&auto=format&fit=crop'

useHead({
  title: 'Home | CocoBrite',
  meta: [
    {
      name: 'description',
      content: 'CocoBrite body care for a global audience — featuring our radiance body lotion and daily rituals. Thoughtful formulas; results vary by person.'
    }
  ]
})

const totalPages = computed(() => Math.ceil(total.value / pageSize.value))

const fetchProducts = async () => {
  loading.value = true
  try {
    const res = await api.getProducts({
      page: currentPage.value,
      limit: pageSize.value,
      status: 1,
      show_on_home: 1,
    })
    if (res.code === 0) {
      if (res.data.data) {
        products.value = res.data.data
        total.value = res.data.total
      } else if (res.data.list) {
        products.value = res.data.list
        total.value = res.data.total
      } else {
        products.value = res.data
        total.value = res.data.length
      }
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const changePage = (page) => {
  if (page < 1 || page > totalPages.value) return
  currentPage.value = page
  fetchProducts()
  document.querySelector('.section-container')?.scrollIntoView({ behavior: 'smooth' })
}

const navCategories = ref([])
const categoryLabelForKey = (key) => {
  const k = String(key || '')
  const row = navCategories.value.find((c) => categoryFilterKey(c) === k)
  return row ? categoryDisplayName(locale.value, row) : k
}

const loadNavCategories = async () => {
  try {
    const res = await api.getProductCategories()
    if (res.code === 0 && Array.isArray(res.data) && res.data.length) {
      navCategories.value = res.data
    }
  } catch (_) {}
}

const goToProduct = (id) => {
  router.push(`/product/${id}`)
}

onMounted(() => {
  fetchProducts()
  loadNavCategories()
})

const scrollToCollection = () => {
  document.querySelector('.section-container')?.scrollIntoView({ behavior: 'smooth' })
}

const handleImgError = (e) => {
  const img = e.target
  if (img.dataset.retry) {
    img.src = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxIDEiPjxyZWN0IHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFQkU2RDgiLz48L3N2Zz4='
    return
  }
  img.dataset.retry = 'true'
  img.src = fallbackImg
}
</script>

<template>
  <div class="home">
    <section class="hero-section">
      <div class="hero-content">
        <div class="hero-text-vertical">
          <h2 class="vertical-subtitle">{{ $t('home.heroSubtitle') }}</h2>
          <h1 class="vertical-title">CocoBrite</h1>
        </div>
        <div class="hero-main-text">
          <h3>{{ $t('home.heroTitle') }}</h3>
          <p>{{ $t('home.heroText') }}</p>
          <button class="cta-btn" @click="scrollToCollection" :aria-label="$t('home.heroCta')">{{ $t('home.heroCta') }}</button>
        </div>
      </div>
      <div class="hero-image-wrapper">
        <img :src="heroImg" :alt="$t('home.heroImgAlt')" class="hero-image" loading="lazy" />
        <div class="hero-overlay"></div>
      </div>
    </section>

    <section class="trust-strip" :aria-label="$t('home.trustAria')">
      <div class="trust-inner">
        <span><i class="ri-shield-check-line"></i> {{ $t('home.trust1') }}</span>
        <span><i class="ri-truck-line"></i> {{ $t('home.trust2') }}</span>
        <span><i class="ri-customer-service-2-line"></i> {{ $t('home.trust3') }}</span>
      </div>
    </section>

    <section class="section-container">
      <div class="section-header">
        <span class="section-subtitle">Star Product</span>
        <h2 class="section-title">{{ $t('home.collectionTitle') }}</h2>
        <div class="section-line"></div>
        <router-link to="/products" class="section-more">{{ $t('home.viewAllCategories') }}</router-link>
      </div>
      
      <div class="product-grid" v-if="!loading">
        <article class="product-card" v-for="product in products" :key="product.id">
          <div class="card-image-container" @click="goToProduct(product.id)">
            <img :src="product.image" :alt="pickLocalized(locale, product.name, product.name_en)" class="card-image" @error="handleImgError" loading="lazy" />
            <div class="card-overlay">
              <button class="quick-view-btn" @click.stop="goToProduct(product.id)">{{ $t('home.viewDetail') }}</button>
            </div>
          </div>
          <div class="card-info">
            <div class="card-category">{{ categoryLabelForKey(product.category) }}</div>
            <h3 class="card-title">{{ pickLocalized(locale, product.name, product.name_en) }}</h3>
            <div class="card-price">
              <span class="currency">¥</span>{{ product.price }}
            </div>
          </div>
        </article>
      </div>

      <div class="pagination" v-if="totalPages > 1">
        <button 
          class="page-btn prev" 
          :disabled="currentPage === 1"
          @click="changePage(currentPage - 1)"
        >
          <i class="ri-arrow-left-s-line"></i>
        </button>
        
        <div class="page-numbers">
          <button 
            v-for="page in totalPages" 
            :key="page"
            class="page-num"
            :class="{ active: currentPage === page }"
            @click="changePage(page)"
          >
            {{ page }}
          </button>
        </div>

        <button 
          class="page-btn next" 
          :disabled="currentPage === totalPages"
          @click="changePage(currentPage + 1)"
        >
          <i class="ri-arrow-right-s-line"></i>
        </button>
      </div>
    </section>

    <section class="brand-story">
      <div class="story-content">
        <div class="story-text">
          <h2>{{ $t('home.storyTitle') }}</h2>
          <p>{{ $t('home.storyText') }}</p>
          <router-link to="/products" class="read-more">{{ $t('home.storyLink') }}</router-link>
        </div>
        <div class="story-image">
          <img src="https://images.unsplash.com/photo-1612817288484-6f916006741a?w=1200&q=80&auto=format&fit=crop" :alt="$t('home.storyImgAlt')" @error="handleImgError" />
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.hero-section {
  height: 100vh;
  display: flex;
  position: relative;
  overflow: hidden;
  background: linear-gradient(135deg, #3a2a32 0%, #5c4154 45%, #45303c 100%);
}

.hero-image-wrapper {
  position: absolute;
  top: 0;
  right: 0;
  width: 55%;
  height: 100%;
  z-index: 1;
}

.hero-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.9;
}

.hero-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    to right,
    rgba(251, 246, 248, 0.97) 6%,
    rgba(251, 246, 248, 0.4) 52%,
    transparent 100%
  );
}

.hero-content {
  position: relative;
  z-index: 2;
  width: 45%;
  padding: 0 6rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
  background: transparent;
}

.hero-text-vertical {
  position: absolute;
  right: 0;
  top: 15%;
  writing-mode: vertical-rl;
  text-orientation: mixed;
  display: flex;
  gap: 1.5rem;
  opacity: 0.8;
  z-index: 10;
}

.vertical-title {
  font-family: var(--font-serif);
  font-size: 4rem;
  color: rgba(255, 255, 255, 0.15);
  letter-spacing: 0.3em;
  margin: 0;
}

.vertical-subtitle {
  font-family: var(--font-serif);
  font-size: 1.2rem;
  color: var(--accent-color);
  letter-spacing: 0.5em;
  margin: 0;
  text-shadow: 0 0 24px rgba(201, 149, 160, 0.45);
}

.hero-main-text {
  margin-top: 2rem;
}

.hero-main-text h3 {
  font-family: var(--font-display);
  font-size: 3.5rem;
  font-weight: 500;
  margin: 0 0 1.5rem 0;
  color: #fdf2f5;
  letter-spacing: 0.04em;
  text-shadow: 0 4px 28px rgba(0, 0, 0, 0.2);
}

.hero-main-text p {
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 3rem;
  max-width: 400px;
  line-height: 1.8;
}

.cta-btn {
  padding: 1rem 2.75rem;
  background: rgba(255, 255, 255, 0.08);
  color: #fdf2f5;
  border: 1.5px solid rgba(253, 242, 245, 0.85);
  border-radius: var(--radius-pill);
  font-size: 0.88rem;
  letter-spacing: 0.18em;
  cursor: pointer;
  transition: all 0.35s ease;
  font-family: var(--font-sans);
  font-weight: 500;
  text-transform: uppercase;
  backdrop-filter: blur(6px);
}

.cta-btn:hover {
  background: linear-gradient(120deg, var(--accent-color), #e8b8c4);
  color: var(--primary-color);
  border-color: transparent;
  transform: translateY(-3px);
  box-shadow: var(--shadow-glow-accent);
}

.trust-strip {
  background: linear-gradient(90deg, rgba(255, 255, 255, 0.92) 0%, rgba(252, 244, 247, 0.98) 50%, rgba(255, 255, 255, 0.92) 100%);
  border-bottom: 1px solid var(--border-color);
  padding: 1.1rem 2rem;
}

.trust-inner {
  max-width: 1280px;
  margin: 0 auto;
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 2rem 3rem;
  font-size: 0.85rem;
  color: var(--text-secondary);
  letter-spacing: 0.06em;
}

.trust-inner i {
  margin-right: 0.35rem;
  color: var(--accent-color);
  vertical-align: middle;
}

.section-container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 6rem 2rem;
}

.section-header {
  text-align: center;
  margin-bottom: 4rem;
}

.section-subtitle {
  display: block;
  font-family: var(--font-display);
  font-size: 0.9rem;
  color: var(--accent-color);
  letter-spacing: 0.2em;
  text-transform: uppercase;
  margin-bottom: 0.5rem;
}

.section-title {
  font-size: 2.5rem;
  color: var(--text-primary);
  margin: 0 0 1rem 0;
}

.section-line {
  width: 60px;
  height: 2px;
  background-color: var(--accent-color);
  margin: 0 auto;
}

.section-more {
  display: inline-block;
  margin-top: 1.25rem;
  font-size: 0.85rem;
  letter-spacing: 0.12em;
  color: var(--accent-color);
  text-decoration: none;
  border-bottom: 1px solid transparent;
  transition: border-color 0.25s ease, color 0.25s ease;
}

.section-more:hover {
  color: var(--primary-color);
  border-bottom-color: var(--accent-color);
}

.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 3rem;
}

.product-card {
  group: 1;
  transition: all 0.5s ease;
  border-radius: var(--radius);
  background: transparent;
}

.product-card:hover {
  transform: translateY(-5px);
}

.card-image-container {
  position: relative;
  overflow: hidden;
  aspect-ratio: 3/4;
  margin-bottom: 1.5rem;
  background-color: #f0f0f0;
  border-radius: var(--radius);
  box-shadow: var(--shadow-soft);
  transition: box-shadow 0.4s ease;
}

.product-card:hover .card-image-container {
  box-shadow: var(--shadow-hover);
}

.card-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.6s ease;
}

.product-card:hover .card-image {
  transform: scale(1.05);
}

.card-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.2);
  display: flex;
  justify-content: center;
  align-items: center;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.product-card:hover .card-overlay {
  opacity: 1;
}

.quick-view-btn {
  padding: 0.75rem 1.75rem;
  background-color: white;
  color: var(--text-primary);
  border: none;
  font-size: 0.88rem;
  font-weight: 500;
  cursor: pointer;
  border-radius: var(--radius-pill);
  transform: translateY(20px);
  transition: all 0.4s ease;
  box-shadow: var(--shadow-soft);
}

.product-card:hover .quick-view-btn {
  transform: translateY(0);
}

.card-info {
  text-align: center;
}

.card-category {
  font-size: 0.8rem;
  color: var(--accent-color);
  margin-bottom: 0.5rem;
}

.card-title {
  font-size: 1.2rem;
  font-weight: 500;
  margin: 0 0 0.5rem 0;
  font-family: var(--font-serif);
}

.card-price {
  font-family: var(--font-display);
  font-size: 1.1rem;
  color: var(--text-primary);
}

.currency {
  font-size: 0.8rem;
  margin-right: 2px;
}

.brand-story {
  background-color: var(--bg-color);
  padding: 8rem 0;
  position: relative;
}

.brand-story::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: radial-gradient(var(--border-color) 1px, transparent 1px);
  background-size: 30px 30px;
  opacity: 0.3;
  pointer-events: none;
}

.story-content {
  max-width: 1280px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  padding: 0 2rem;
  gap: 6rem;
  position: relative;
  z-index: 1;
}

.story-text {
  flex: 1;
}

.story-text h2 {
  font-size: 2.8rem;
  margin-bottom: 2rem;
  color: var(--primary-color);
}

.story-text p {
  color: var(--text-secondary);
  line-height: 2;
  margin-bottom: 3rem;
  font-size: 1.05rem;
  text-align: justify;
}

.read-more {
  color: var(--primary-color);
  text-decoration: none;
  font-weight: 600;
  font-size: 0.9rem;
  border-bottom: 1px solid var(--primary-color);
  padding-bottom: 2px;
}

.story-image {
  flex: 1;
  height: 400px;
}

.story-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: var(--radius);
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 4rem;
  gap: 1rem;
}

.page-btn {
  width: 40px;
  height: 40px;
  display: flex;
  justify-content: center;
  align-items: center;
  border: 1px solid var(--border-color);
  background-color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  color: var(--text-primary);
  border-radius: 50%;
}

.page-btn:hover:not(:disabled) {
  background-color: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.page-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-numbers {
  display: flex;
  gap: 0.5rem;
}

.page-num {
  width: 40px;
  height: 40px;
  border: none;
  background-color: transparent;
  cursor: pointer;
  font-family: var(--font-display);
  font-size: 1rem;
  color: var(--text-secondary);
  transition: all 0.3s ease;
  border-radius: 50%;
}

.page-num.active {
  background-color: var(--primary-color);
  color: white;
}

.page-num:hover:not(.active) {
  background-color: #f5f5f5;
  color: var(--text-primary);
}

@media (max-width: 768px) {
  .hero-section {
    flex-direction: column;
    height: auto;
    min-height: 100vh;
  }

  .hero-image-wrapper {
    position: relative;
    width: 100%;
    height: 50vh;
    order: 1;
  }

  .hero-content {
    width: 100%;
    padding: 3rem 1.5rem;
    order: 2;
    text-align: center;
    background-color: var(--bg-color);
  }

  .hero-text-vertical {
    display: none;
  }

  .hero-main-text h3 {
    font-size: 2.5rem;
  }

  .hero-main-text p {
    margin: 0 auto 2rem auto;
    color: var(--text-secondary);
  }

  .section-container {
    padding: 4rem 1.5rem;
  }

  .product-grid {
    grid-template-columns: 1fr;
    gap: 2rem;
  }

  .brand-story .story-content {
    flex-direction: column;
  }

  .brand-story .story-text,
  .brand-story .story-image {
    width: 100%;
  }

  .brand-story .story-text {
    padding: 0;
    margin-bottom: 2rem;
  }
}
</style>
