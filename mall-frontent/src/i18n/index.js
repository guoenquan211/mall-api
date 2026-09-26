import { createI18n } from 'vue-i18n'
import zhTW from '../locales/zh-TW.json'
import en from '../locales/en.json'
import { getStoredLocale } from './localeStorage.js'

export const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: getStoredLocale(),
  fallbackLocale: 'en',
  messages: {
    'zh-TW': zhTW,
    en,
  },
})
