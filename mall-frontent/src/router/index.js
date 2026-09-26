import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'

const routes = [
  { path: '/', component: Home },
  { path: '/products', component: () => import('../views/ProductList.vue') },
  { path: '/product/:id', component: () => import('../views/ProductDetail.vue') },
  { path: '/cart', component: () => import('../views/Cart.vue') },
  { path: '/order/pay/:id', component: () => import('../views/OrderPay.vue'), meta: { requiresAuth: true } },
  { path: '/contact', component: () => import('../views/Contact.vue') },
  { path: '/about', component: () => import('../views/About.vue') },
  { path: '/news', component: () => import('../views/News.vue') },
  { path: '/knowledge', component: () => import('../views/Knowledge.vue') },
  { path: '/user', component: () => import('../views/UserCenter.vue') },
  { path: '/login', component: () => import('../views/Login.vue') },
  { path: '/register', component: () => import('../views/Register.vue') },
  { path: '/privacy', component: () => import('../views/Privacy.vue') },
  { path: '/terms', component: () => import('../views/Terms.vue') },
  { path: '/:pathMatch(.*)*', component: () => import('../views/NotFound.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0, behavior: 'smooth' }
    }
  },
})

export default router
