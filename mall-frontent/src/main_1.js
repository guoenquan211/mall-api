import { createApp } from 'vue'
import { createHead } from '@unhead/vue/client'
import './style.css'
import App from './App.vue'
import router from './router'
import { LS_INVITE_REF } from './api/cocobrite-data.js'

const app = createApp(App)
const head = createHead()

app.use(router)
router.afterEach((to) => {
  const raw = to.query.ref ?? to.query.invite
  const code = typeof raw === 'string' ? raw.trim().toUpperCase() : Array.isArray(raw) ? String(raw[0] || '').trim().toUpperCase() : ''
  if (code) {
    try {
      localStorage.setItem(LS_INVITE_REF, code)
    } catch (_) {}
  }
})
app.use(head)
app.mount('#app')
