<template>
  <div class="app-container">
    <header class="header" :class="{ 'scrolled': isScrolled }">
      <div class="header-inner">
        <div class="logo">
          <img src="/logo.svg?v=7" alt="CocoBrite" class="logo-icon" />
          <div class="logo-titles">
          
          </div>
        </div>
        
        <div class="mobile-menu-overlay" :class="{ 'active': isMenuOpen }" @click="closeMenu"></div>
        <nav class="nav" :class="{ 'mobile-active': isMenuOpen }">
          <button class="menu-close-btn" @click="closeMenu">
            <i class="ri-close-line"></i>
          </button>
          <router-link to="/" @click="closeMenu">{{ $t('nav.home') }}</router-link>
          <div class="nav-dropdown" :class="{ 'is-open': productsNavOpen }">
            <router-link
              to="/products"
              class="nav-dropdown-root"
              :aria-expanded="productsNavOpen ? 'true' : 'false'"
              aria-haspopup="true"
              @click="onProductsRootClick"
            >{{ $t('nav.allProducts') }}</router-link>
            <div class="nav-dropdown-panel" role="menu">
              <router-link
                class="nav-dropdown-all"
                :to="{ path: '/products' }"
                role="menuitem"
                @click="onProductsSubnavClick"
              >{{ $t('nav.viewAllProducts') }}</router-link>
              <router-link
                v-for="c in productCategories"
                :key="categoryFilterKey(c)"
                role="menuitem"
                :to="{ path: '/products', query: { category: categoryFilterKey(c) } }"
                @click="onProductsSubnavClick"
              >{{ categoryDisplayName(locale, c) }}</router-link>
            </div>
          </div>
          <router-link to="/news" @click="closeMenu">{{ $t('nav.news') }}</router-link>
          <router-link to="/knowledge" @click="closeMenu">{{ $t('nav.knowledge') }}</router-link>
          <router-link to="/contact" @click="closeMenu">{{ $t('nav.contact') }}</router-link>
          <router-link to="/user" @click="closeMenu">{{ $t('nav.member') }}</router-link>
          <a v-if="user.loggedIn" class="nav-logout" @click="handleLogoutAndClose">{{ $t('nav.logout') }}</a>
        </nav>
        <div class="header-lang">
          <LanguageSwitcher />
        </div>
        <div class="header-actions">
          <button class="mobile-menu-btn" @click="toggleMenu">
            <i class="ri-menu-line"></i>
          </button>
          <button type="button" class="icon-btn header-search-btn" @click="openSearch"><i class="ri-search-line"></i></button>
          <button class="icon-btn cart-btn" @click="goToCart">
            <i class="ri-shopping-cart-2-line"></i>
            <span v-if="cartCount > 0" class="cart-badge">{{ cartCount }}</span>
          </button>
          <router-link v-if="!user.loggedIn" to="/login" class="auth-link">{{ $t('nav.login') }}</router-link>
          <button
            v-else
            type="button"
            class="user-chip"
            :title="user.name"
            :aria-label="user.name"
            @click="goToUser"
          >
            <i class="ri-user-3-line user-chip-icon" aria-hidden="true"></i>
            <span class="user-chip-label">{{ user.name }}</span>
          </button>
          <button v-if="user.loggedIn" class="icon-btn logout-btn-desktop" @click="handleLogout"><i class="ri-logout-box-line"></i></button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <router-view></router-view>
    </main>

    
  </div>
  <footer class="footer">
      <div class="footer-content">
        <div class="footer-logo">CocoBrite</div>
        <div class="footer-links">
          <router-link to="/privacy">{{ $t('footer.privacy') }}</router-link>
          <span class="divider">/</span>
          <router-link to="/terms">{{ $t('footer.terms') }}</router-link>
          <span class="divider">/</span>
          <router-link to="/about">{{ $t('footer.about') }}</router-link>
        </div>
        <p class="copyright">{{ $t('footer.copyright') }}</p>
        <div class="footer-lang">
          <LanguageSwitcher theme="dark" />
        </div>
      </div>
    </footer>

    <!-- Search Modal -->
    <div v-if="isSearchOpen" class="search-overlay" @click.self="closeSearch">
      <div class="search-modal">
        <div class="search-header">
          <input 
            v-model="searchQuery" 
            type="text" 
            class="search-input" 
            :placeholder="$t('search.placeholder')" 
            @keyup.enter="handleSearch"
          />
          <button class="search-action-btn" @click="handleSearch">
            <i class="ri-search-line"></i>
          </button>
          <button class="close-search-btn" @click="closeSearch">
            <i class="ri-close-line"></i>
          </button>
        </div>
        <div class="search-body">
          <div v-if="isSearching" class="search-loading">{{ $t('search.searching') }}</div>
          <div v-else-if="searchResults.length > 0" class="search-results">
            <div 
              v-for="item in searchResults" 
              :key="item.id" 
              class="search-item"
              @click="goToProductFromSearch(item.id)"
            >
              <img :src="item.image" :alt="item.name" class="search-item-img" />
              <div class="search-item-info">
                <h4>{{ item.name }}</h4>
                <p>¥{{ item.price }}</p>
              </div>
            </div>
          </div>
          <div v-else-if="searchQuery && !isSearching" class="search-empty">
            {{ $t('search.empty') }}
          </div>
        </div>
      </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useCart, useUser } from './store'
import { api } from './api'
import { PRODUCT_CATEGORY_LIST } from './api/cocobrite-data'
import { categoryFilterKey, categoryDisplayName } from './utils/localeDisplay.js'
import LanguageSwitcher from './components/LanguageSwitcher.vue'

const router = useRouter()
const { locale } = useI18n()
const { cart } = useCart()
const { user, logout } = useUser()

const cartCount = computed(() => cart.reduce((sum, item) => sum + item.quantity, 0))

const productCategories = ref([...PRODUCT_CATEGORY_LIST])

const isScrolled = ref(false)
const isMenuOpen = ref(false)
/** 移动端侧栏：「全部产品」子导航手风琴展开 */
const productsNavOpen = ref(false)
const isSearchOpen = ref(false)
const searchQuery = ref('')
const searchResults = ref([])
const isSearching = ref(false)

const handleScroll = () => {
  isScrolled.value = window.scrollY > 50
}

const toggleMenu = () => {
  const opening = !isMenuOpen.value
  isMenuOpen.value = opening
  if (opening) {
    productsNavOpen.value = false
  }
}

const openSearch = () => {
  isSearchOpen.value = true
  document.body.style.overflow = 'hidden'
  setTimeout(() => document.querySelector('.search-input')?.focus(), 100)
}

const closeSearch = () => {
  isSearchOpen.value = false
  searchQuery.value = ''
  searchResults.value = []
  document.body.style.overflow = ''
}

const handleSearch = async () => {
  if (!searchQuery.value.trim()) return
  
  isSearching.value = true
  try {
    const res = await api.getProducts({ keyword: searchQuery.value })
    if (res.code === 0) {
      // API returns { list: [], total: ... } if paginated, or [] if not.
      // Our modified mock returns { list: ..., total: ... } ONLY if page/limit passed.
      // But wait, my modified code in api/index.js returns `allProducts` (array) if NO page/limit passed.
      // Let's double check api/index.js logic.
      // Yes: if (params && params.page && params.limit) ... else resolve({ code: 0, data: allProducts })
      // So it returns array directly.
      searchResults.value = Array.isArray(res.data) ? res.data : (res.data.list || [])
    }
  } catch (e) {
    console.error(e)
  } finally {
    isSearching.value = false
  }
}

const goToProductFromSearch = (id) => {
  router.push(`/product/${id}`)
  closeSearch()
}

const closeMenu = () => {
  isMenuOpen.value = false
  productsNavOpen.value = false
}

const MOBILE_NAV_BREAKPOINT = 1024

const onProductsRootClick = (e) => {
  if (typeof window !== 'undefined' && window.innerWidth <= MOBILE_NAV_BREAKPOINT) {
    e.preventDefault()
    productsNavOpen.value = !productsNavOpen.value
  } else {
    closeMenu()
  }
}

const onProductsSubnavClick = () => {
  productsNavOpen.value = false
  closeMenu()
}

const goToCart = () => {
  router.push('/cart')
}

const goToLogin = () => {
  router.push('/login')
}

const goToUser = () => {
  router.push('/user')
}

const handleLogout = () => {
  logout()
}

const handleLogoutAndClose = () => {
  logout()
  closeMenu()
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll)
  api.getProductCategories().then((res) => {
    if (res.code === 0 && Array.isArray(res.data) && res.data.length) {
      productCategories.value = res.data
    }
  }).catch(() => {})
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;1,400&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;1,9..40,400&family=Noto+Serif+SC:wght@300;400;500;600;700&display=swap');
@import './assets/mobile.css';

:root {
  /* 时尚美护：柔和粉雾底 + 梅子色主字 + 玫瑰金点缀 */
  --primary-color: #3a2a32;
  --accent-color: #c995a0;
  --accent-secondary: #d4b896;

  --bg-color: #fbf6f8;
  --bg-gradient: linear-gradient(165deg, #fdf9fb 0%, #f8f0f4 38%, #faf6f1 100%);
  --surface-color: #ffffff;
  --surface-muted: rgba(255, 255, 255, 0.78);
  --text-primary: #30262b;
  --text-secondary: #7a656f;
  --text-light: #a8949e;
  --border-color: #ecd8df;
  --radius: 12px;
  --radius-pill: 999px;
  --shadow-soft: 0 12px 40px rgba(58, 42, 50, 0.07);
  --shadow-hover: 0 24px 56px rgba(58, 42, 50, 0.12);
  --shadow-glow-accent: 0 10px 36px rgba(201, 149, 160, 0.32);

  --font-serif: 'Noto Serif SC', 'Songti SC', 'PingFang SC', serif;
  --font-sans: 'DM Sans', 'Helvetica Neue', system-ui, sans-serif;
  --font-display: 'Cormorant Garamond', 'Noto Serif SC', serif;
}

/* Default (Desktop) Styles for Header Elements */
.nav-logout {
  display: none;
}

body {
  margin: 0;
  font-family: var(--font-sans);
  background: var(--bg-gradient);
  background-color: var(--bg-color);
  background-attachment: fixed;
  color: var(--text-primary);
  -webkit-font-smoothing: antialiased;
  line-height: 1.65;
  letter-spacing: 0.01em;
  overflow-x: hidden;
}

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-serif);
  font-weight: 500;
  margin-top: 0;
  color: var(--text-primary);
  letter-spacing: 0.05em;
}

.app-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  width: 100%;
}

.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background-color: transparent;
  transition: all 0.4s ease;
  border-bottom: 1px solid transparent;
}

.header.scrolled {
  background-color: var(--surface-muted);
  backdrop-filter: blur(14px) saturate(1.2);
  -webkit-backdrop-filter: blur(14px) saturate(1.2);
  box-shadow: 0 8px 32px rgba(58, 42, 50, 0.06);
  border-bottom: 1px solid rgba(236, 216, 223, 0.85);
}

.header-inner {
  max-width: 1280px;
  margin: 0 auto;
  padding: 1.2rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-lang {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  margin: 0 0.5rem;
}

.logo {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.logo-titles {
  display: flex;
  flex-direction: column;
  justify-content: center;
  line-height: 1;
}

.logo-text {
  font-family: var(--font-serif);
  font-size: 1.6rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  color: var(--primary-color);
  /* margin-bottom: 4px; */
  line-height: 1.5;
}

.logo-en {
    font-family: var(--font-display);
    font-size: 0.5rem;
    letter-spacing: 0.2em;
    color: var(--accent-color);
    text-transform: uppercase;
  }
  
  /* Search Modal */
  .search-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.6);
    z-index: 1000;
    display: flex;
    justify-content: center;
    align-items: flex-start;
    padding-top: 100px;
    backdrop-filter: blur(8px);
    transition: all 0.3s ease;
  }
  
  .search-modal {
    width: 90%;
    max-width: 680px;
    background: var(--surface-color);
    border-radius: 16px;
    box-shadow: 0 20px 60px rgba(0,0,0,0.15);
    overflow: hidden;
    animation: slideDown 0.4s cubic-bezier(0.16, 1, 0.3, 1);
    border: 1px solid rgba(255,255,255,0.8);
  }
  
  @keyframes slideDown {
    from { transform: translateY(-30px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  
  .search-header {
    display: flex;
    align-items: center;
    padding: 1.5rem 2rem;
    border-bottom: 1px solid var(--border-color);
    background: #fff;
  }
  
  .search-input {
    flex: 1;
    border: none;
    background: transparent;
    font-size: 1.2rem;
    padding: 0.8rem 0;
    color: var(--text-primary);
    outline: none;
    font-family: var(--font-serif);
    border-bottom: 2px solid transparent;
    transition: border-color 0.3s;
    margin: 0 1rem;
  }

  .search-input:focus {
    border-bottom-color: var(--accent-color);
  }
  
  .search-input::placeholder {
    color: #ccc;
    font-family: var(--font-sans);
    font-size: 1rem;
  }
  
  .search-action-btn, .close-search-btn {
    background: none;
    border: none;
    font-size: 1.4rem;
    color: var(--text-secondary);
    cursor: pointer;
    padding: 0.5rem;
    transition: all 0.3s;
    border-radius: 50%;
    width: 44px;
    height: 44px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .search-action-btn:hover, .close-search-btn:hover {
    color: var(--primary-color);
    background-color: rgba(0,0,0,0.03);
  }
  
  .search-body {
    max-height: 500px;
    overflow-y: auto;
    padding: 1rem 0;
    background: #fafafa;
  }
  
  .search-loading, .search-empty {
    text-align: center;
    color: var(--text-secondary);
    padding: 3rem;
    font-size: 0.95rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
  }

  .search-empty::before {
    content: '\eb99'; /* ri-search-line */
    font-family: 'remixicon';
    font-size: 2rem;
    color: #ddd;
    margin-bottom: 0.5rem;
  }
  
  .search-item {
    display: flex;
    align-items: center;
    padding: 1.2rem 2rem;
    cursor: pointer;
    transition: all 0.2s ease;
    border-bottom: 1px solid rgba(0,0,0,0.03);
    margin: 0.5rem 1rem;
    border-radius: 12px;
    background: #fff;
    box-shadow: 0 2px 8px rgba(0,0,0,0.02);
  }
  
  .search-item:last-child {
    border-bottom: none;
  }
  
  .search-item:hover {
    background: #fff;
    box-shadow: var(--shadow-glow-accent);
    transform: translateY(-2px);
    border-color: transparent;
  }
  
  .search-item-img {
    width: 64px;
    height: 64px;
    object-fit: cover;
    border-radius: 8px;
    margin-right: 1.5rem;
    border: 1px solid rgba(0,0,0,0.05);
  }
  
  .search-item-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  
  .search-item-info h4 {
    font-size: 1.1rem;
    margin-bottom: 0.4rem;
    color: var(--text-primary);
    font-family: var(--font-serif);
    font-weight: 600;
  }
  
  .search-item-info p {
    color: var(--accent-color);
    font-weight: bold;
    font-size: 1rem;
    margin: 0;
    font-family: var(--font-sans);
  }

.logo-icon {
  height: 48px;
  object-fit: contain;
  flex-shrink: 0;
}

@media (max-width: 1024px) {
  .logo-icon {
    height: 40px;
  }
}

.nav-dropdown {
  position: relative;
}

/* 下拉箭头独占 ::after，避免与 .nav a::after 下划线混在同个伪元素上（否则会残留 border 画成粗条/怪三角） */
.nav-dropdown-root::after {
  content: '';
  display: inline-block;
  width: 0;
  height: 0;
  margin-left: 0.35rem;
  vertical-align: middle;
  border: none;
  border-left: 3px solid transparent;
  border-right: 3px solid transparent;
  border-top: 4px solid currentColor;
  opacity: 0.45;
  position: static;
  transform: none;
  left: auto;
  bottom: auto;
  background: none;
  transition: opacity 0.2s ease;
}

.nav-dropdown-root::before {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 1px;
  background-color: var(--accent-color);
  transition: width 0.25s ease;
  pointer-events: none;
}

.nav-dropdown-root:hover::before,
.nav-dropdown-root.router-link-active::before {
  width: 100%;
}

@media (min-width: 1025px) {
  .nav-dropdown-panel {
    display: none;
    position: absolute;
    top: 100%;
    left: 50%;
    transform: translateX(-50%);
    min-width: 11rem;
    margin-top: 0.35rem;
    padding: 0.5rem 0;
    background: var(--surface-color);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-soft);
    z-index: 120;
  }

  .nav-dropdown:hover .nav-dropdown-panel,
  .nav-dropdown:focus-within .nav-dropdown-panel {
    display: block;
  }

  .nav-dropdown-panel a {
    display: block;
    padding: 0.55rem 1.25rem;
    font-size: 0.85rem;
    color: var(--text-secondary);
    text-decoration: none;
    letter-spacing: 0.06em;
    white-space: nowrap;
  }

  .nav-dropdown-panel a:hover {
    background: rgba(201, 149, 160, 0.14);
    color: var(--primary-color);
  }

  .nav-dropdown-panel a::after {
    display: none !important;
  }
}

.nav {
  display: flex;
  gap: 2rem;
}

.nav a {
  text-decoration: none;
  color: var(--text-secondary);
  font-size: 0.9rem;
  letter-spacing: 0.1em;
  transition: all 0.3s ease;
  position: relative;
  padding-bottom: 4px;
  font-weight: 500;
}

.nav a:not(.nav-dropdown-root)::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 1px;
  background-color: var(--accent-color);
  transition: width 0.25s ease;
}

.nav a:hover, .nav a.router-link-active {
  color: var(--primary-color);
}

.nav a:not(.nav-dropdown-root):hover::after,
.nav a:not(.nav-dropdown-root).router-link-active::after {
  width: 100%;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.auth-link {
  color: var(--text-primary);
  text-decoration: none;
  font-size: 0.95rem;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  height: 34px;
  padding: 0 8px;
}
.user-chip {
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  padding: 0.4rem 0.95rem;
  border-radius: var(--radius-pill);
  cursor: pointer;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  height: 34px;
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-primary);
  transition: border-color 0.25s ease, box-shadow 0.25s ease, transform 0.2s ease;
}

.user-chip:hover {
  border-color: rgba(201, 149, 160, 0.65);
  box-shadow: var(--shadow-glow-accent);
}

.icon-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  color: var(--text-primary);
  opacity: 0.7;
  transition: opacity 0.3s;
  height: 34px;
  display: inline-flex;
  align-items: center;

  padding: 0.4rem 0.6rem;
}

.icon-btn:hover {
  opacity: 1;
}

.main-content {
  flex: 1;
  width: 100%;
  box-sizing: border-box;
  padding-top: 80px;
}

.footer {
  background: linear-gradient(180deg, #3d2f38 0%, #251c22 100%);
  color: #c9bcc2;
  padding: 4rem 0;
  text-align: center;
  width: 100%;
}

.footer-content {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 2rem;
  box-sizing: border-box;
}

.footer-logo {
  font-family: var(--font-display);
  font-size: 1.65rem;
  color: #fdf8fa;
  margin-bottom: 1.5rem;
  letter-spacing: 0.14em;
  font-weight: 500;
}

.footer-links {
  margin-bottom: 2rem;
  font-size: 0.9rem;
}

.footer-links a {
  color: #e8dce2;
  text-decoration: none;
  transition: color 0.3s;
}

.footer-links a:hover {
  color: #fff;
}

.divider {
  margin: 0 1rem;
  opacity: 0.3;
}

.copyright {
  font-size: 0.82rem;
  color: rgba(255, 255, 255, 0.72);
  letter-spacing: 0.04em;
  line-height: 1.5;
}

.footer-lang {
  display: none;
  justify-content: center;
  margin-top: 1.25rem;
  padding-top: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.15);
}

@media (max-width: 1024px) {
  .header-lang {
    display: none;
  }

  .footer-lang {
    display: flex;
  }
}

@media (max-width: 768px) {
  .header-inner {
    padding: 1rem;
  }

  .logo-text {
    font-size: 1.4rem;
  }

  .logo-en {
    display: none;
  }

  .header-actions {
    gap: 0.5rem;
  }

  .user-chip {
    padding: 0.4rem 0.5rem;
    font-size: 0.85rem;
    max-width: 70px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}

@media (max-width: 1024px) {
  .header-inner {
    padding: 1rem 1.5rem;
  }
  .nav {
    gap: 1.5rem;
  }
  .logo-en {
    display: none;
  }
}
</style>
