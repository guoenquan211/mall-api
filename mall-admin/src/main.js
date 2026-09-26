import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'
import { QuillEditor } from '@vueup/vue-quill'
import '@vueup/vue-quill/dist/vue-quill.snow.css'
import { i18n } from './i18n'
import { getStoredLocale } from './i18n/localeStorage.js'

const app = createApp(App)
app.component('QuillEditor', QuillEditor)
try {
  document.documentElement.lang = getStoredLocale() === 'en' ? 'en' : 'zh-Hant'
} catch (_) {}
app.use(i18n)
app.use(router)
app.mount('#app')
