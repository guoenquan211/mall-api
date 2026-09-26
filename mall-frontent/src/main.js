import { createApp } from 'vue'
import { createHead } from '@unhead/vue/client'
import './style.css'
import App from './App.vue'
import router from './router'
import { LS_INVITE_REF } from './api/cocobrite-data.js'
import { api } from './api'
import { i18n } from './i18n'
import { getStoredLocale } from './i18n/localeStorage.js'

const app = createApp(App)
const head = createHead()

try {
  document.documentElement.lang = getStoredLocale() === 'en' ? 'en' : 'zh-Hant'
} catch (_) {}

app.use(i18n)
app.use(router)
router.afterEach((to) => {
  const raw = to.query.ref ?? to.query.invite
  const code = typeof raw === 'string' ? raw.trim().toUpperCase() : Array.isArray(raw) ? String(raw[0] || '').trim().toUpperCase() : ''
  if (code) {
    try {
      localStorage.setItem(LS_INVITE_REF, code)
    } catch (_) {}
    const pathMatch = to.path.match(/^\/product\/(\d+)/)
    const productId = pathMatch ? Number(pathMatch[1]) : 0
    const trackKey = `aff_click_${code}_${productId || 0}`
    try {
      if (!sessionStorage.getItem(trackKey)) {
        sessionStorage.setItem(trackKey, '1')
        api.trackAffiliateClick(code, Number.isFinite(productId) && productId > 0 ? productId : 0).catch(() => {})
      }
    } catch (_) {}
  }
})
app.use(head)
app.mount('#app')
