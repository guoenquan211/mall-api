<template>
  <div v-if="isLoginPage">
    <router-view></router-view>
  </div>
  <div v-else class="admin-layout">
    <aside class="sidebar">
      <div class="logo-area">
        <div class="logo-icon">C</div>
        <div class="logo-text">CocoBrite<span class="logo-subtitle">{{ $t('admin.logoSubtitle') }}</span></div>
      </div>
      <nav class="nav">
        <router-link to="/" class="nav-item">
          <i class="ri-dashboard-line"></i>
          <span>{{ $t('admin.nav.dashboard') }}</span>
        </router-link>
        <router-link to="/products" class="nav-item">
          <i class="ri-store-2-line"></i>
          <span>{{ $t('admin.nav.products') }}</span>
        </router-link>
        <router-link to="/product-categories" class="nav-item">
          <i class="ri-price-tag-3-line"></i>
          <span>{{ $t('admin.nav.categories') }}</span>
        </router-link>
        <router-link to="/affiliate" class="nav-item">
          <i class="ri-share-line"></i>
          <span>{{ $t('admin.nav.affiliate') }}</span>
        </router-link>
        <router-link to="/wallet-flows" class="nav-item">
          <i class="ri-wallet-3-line"></i>
          <span>{{ $t('admin.nav.walletFlows') }}</span>
        </router-link>
        <router-link to="/orders" class="nav-item">
          <i class="ri-list-check"></i>
          <span>{{ $t('admin.nav.orders') }}</span>
        </router-link>
        <router-link to="/gcash" class="nav-item">
          <i class="ri-qr-code-line"></i>
          <span>GCash</span>
        </router-link>
        <router-link to="/users" class="nav-item">
          <i class="ri-user-star-line"></i>
          <span>{{ $t('admin.nav.users') }}</span>
        </router-link>
        <router-link to="/admins" class="nav-item">
          <i class="ri-admin-line"></i>
          <span>{{ $t('admin.nav.admins') }}</span>
        </router-link>
        <router-link to="/content" class="nav-item">
          <i class="ri-article-line"></i>
          <span>{{ $t('admin.nav.content') }}</span>
        </router-link>
        <router-link to="/home-settings" class="nav-item">
          <i class="ri-image-edit-line"></i>
          <span>{{ $t('admin.nav.homeSettings') }}</span>
        </router-link>
        <router-link to="/contact-messages" class="nav-item">
          <i class="ri-mail-line"></i>
          <span>{{ $t('admin.nav.contactMessages') }}</span>
        </router-link>
        <router-link to="/logs" class="nav-item">
          <i class="ri-file-list-3-line"></i>
          <span>{{ $t('admin.nav.logs') }}</span>
        </router-link>
      </nav>
      <div class="sidebar-footer">
        <div class="version">v1.0.0</div>
      </div>
    </aside>
    
    <main class="main-wrapper">
      <header class="top-bar">
        <div class="breadcrumbs">
          <span class="current-path">{{ currentRouteName }}</span>
        </div>
        <div class="user-actions">
          <LanguageSwitcher />
          <button class="icon-btn">
            <i class="ri-notification-3-line"></i>
            <span class="badge"></span>
          </button>
          <div class="user-profile">
            <div class="avatar">A</div>
            <span class="username">Admin</span>
            <i class="ri-arrow-down-s-line"></i>
          </div>
          <button class="logout-btn" @click="handleLogout">
            <i class="ri-logout-box-r-line"></i>
          </button>
        </div>
      </header>
      <div class="content-area">
        <router-view></router-view>
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { api } from './api'
import LanguageSwitcher from './components/LanguageSwitcher.vue'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const isLoginPage = computed(() => route.path === '/login')

const currentRouteName = computed(() => {
  switch (route.path) {
    case '/': return t('admin.routes.dashboard')
    case '/products': return t('admin.routes.products')
    case '/product-categories': return t('admin.routes.categories')
    case '/affiliate': return t('admin.routes.affiliate')
    case '/wallet-flows': return t('admin.routes.walletFlows')
    case '/orders': return t('admin.routes.orders')
    case '/users': return t('admin.routes.users')
    case '/admins': return t('admin.routes.admins')
    case '/content': return t('admin.routes.content')
    case '/home-settings': return t('admin.routes.homeSettings')
    case '/contact-messages': return t('admin.routes.contactMessages')
    case '/logs': return t('admin.routes.logs')
    default: return t('admin.routes.default')
  }
})

const handleLogout = async () => {
  await api.addLog({ action: '登出', target: '系统', detail: '用户退出登录' })
  localStorage.removeItem('admin_token')
  localStorage.removeItem('admin_user')
  router.push('/login')
}
</script>

<style scoped>
.admin-layout {
  display: flex;
  height: 100vh;
  background-color: var(--color-bg-main);
}

/* Sidebar */
.sidebar {
  width: var(--sidebar-width);
  background: var(--color-primary-dark);
  color: white;
  display: flex;
  flex-direction: column;
  box-shadow: 4px 0 10px rgba(0,0,0,0.05);
  z-index: 10;
  transition: width 0.3s ease;
}

.logo-area {
  height: var(--header-height);
  display: flex;
  align-items: center;
  padding: 0 1.5rem;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.logo-icon {
  width: 32px;
  height: 32px;
  background: var(--color-accent);
  color: var(--color-primary-dark);
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-serif);
  font-weight: bold;
  font-size: 1.2rem;
  margin-right: 12px;
}

.logo-text {
  font-family: var(--font-serif);
  font-size: 1.2rem;
  font-weight: 600;
  letter-spacing: 0.5px;
  display: flex;
  flex-direction: column;
  line-height: 1.1;
}

.logo-subtitle {
  font-family: var(--font-sans);
  font-size: 0.7rem;
  opacity: 0.6;
  font-weight: 400;
  letter-spacing: 2px;
  margin-top: 2px;
}

.nav {
  flex: 1;
  padding: 1.5rem 1rem;
}

.nav-item {
  display: flex;
  align-items: center;
  padding: 0.8rem 1rem;
  color: rgba(255,255,255,0.7);
  text-decoration: none;
  margin-bottom: 0.5rem;
  border-radius: 8px;
  transition: all 0.3s ease;
  font-size: 0.95rem;
}

.nav-item i {
  font-size: 1.2rem;
  margin-right: 12px;
  opacity: 0.8;
}

.nav-item:hover {
  background: rgba(255,255,255,0.05);
  color: white;
}

.nav-item.router-link-active {
  background: linear-gradient(90deg, var(--color-accent) 0%, #a3864d 100%);
  color: var(--color-primary-dark);
  font-weight: 500;
  box-shadow: 0 4px 12px rgba(193, 163, 102, 0.3);
}

.nav-item.router-link-active i {
  opacity: 1;
}

.sidebar-footer {
  padding: 1.5rem;
  border-top: 1px solid rgba(255,255,255,0.05);
  font-size: 0.8rem;
  color: rgba(255,255,255,0.3);
  text-align: center;
}

/* Main Content */
.main-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.top-bar {
  height: var(--header-height);
  background: var(--color-surface);
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: var(--shadow-sm);
  z-index: 5;
}

.current-path {
  font-family: var(--font-serif);
  font-size: 1.1rem;
  color: var(--color-primary-dark);
  font-weight: 600;
}

.user-actions {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.icon-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  color: var(--color-text-muted);
  cursor: pointer;
  position: relative;
  padding: 8px;
  border-radius: 50%;
  transition: background 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-btn:hover {
  background: rgba(0,0,0,0.05);
  color: var(--color-primary-dark);
}

.badge {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 8px;
  height: 8px;
  background: #cf1322;
  border-radius: 50%;
  border: 2px solid white;
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 20px;
  transition: background 0.2s;
}

.user-profile:hover {
  background: rgba(0,0,0,0.03);
}

.avatar {
  width: 36px;
  height: 36px;
  background: var(--color-primary-light);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-family: var(--font-serif);
}

.username {
  font-weight: 500;
  font-size: 0.95rem;
}

.logout-btn {
  background: none;
  border: none;
  color: var(--color-text-muted);
  cursor: pointer;
  font-size: 1.2rem;
  padding: 8px;
  transition: color 0.2s;
}

.logout-btn:hover {
  color: #cf1322;
}

.content-area {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
  background-color: var(--color-bg-main);
}
</style>
