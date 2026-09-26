import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'

import Logs from '../views/Logs.vue'

const routes = [
  { path: '/login', name: 'Login', component: () => import('../views/Login.vue') },
  { path: '/', name: 'Dashboard', component: Dashboard, meta: { requiresAuth: true } },
  { path: '/products', name: 'Products', component: () => import('../views/Products.vue'), meta: { requiresAuth: true } },
  { path: '/product-categories', name: 'ProductCategories', component: () => import('../views/ProductCategories.vue'), meta: { requiresAuth: true } },
  { path: '/affiliate', name: 'AffiliateProgram', component: () => import('../views/AffiliateProgram.vue'), meta: { requiresAuth: true } },
  { path: '/wallet-flows', name: 'WalletFlows', component: () => import('../views/WalletFlows.vue'), meta: { requiresAuth: true } },
  { path: '/orders', name: 'Orders', component: () => import('../views/Orders.vue'), meta: { requiresAuth: true } },
  { path: '/gcash', name: 'GcashManage', component: () => import('../views/GcashManage.vue'), meta: { requiresAuth: true } },
  { path: '/users', name: 'Users', component: () => import('../views/Users.vue'), meta: { requiresAuth: true } },
  { path: '/content', name: 'Content', component: () => import('../views/Content.vue'), meta: { requiresAuth: true } },
  { path: '/home-settings', name: 'HomeSettings', component: () => import('../views/HomeSettings.vue'), meta: { requiresAuth: true } },
  { path: '/contact-messages', name: 'ContactMessages', component: () => import('../views/ContactMessages.vue'), meta: { requiresAuth: true } },
  { path: '/admins', name: 'Admins', component: () => import('../views/Admins.vue'), meta: { requiresAuth: true } },
  { path: '/logs', name: 'Logs', component: Logs, meta: { requiresAuth: true } },
]

const router = createRouter({
  history: createWebHistory('/admin/'),
  routes,
})

router.beforeEach((to, from, next) => {
  const isAuthenticated = localStorage.getItem('admin_token')
  
  if (to.meta.requiresAuth && !isAuthenticated) {
    next('/login')
  } else if (to.path === '/login' && isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router
