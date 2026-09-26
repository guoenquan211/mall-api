export const LOCALE_KEY = 'admin_locale'
export const SUPPORTED_LOCALES = ['zh-TW', 'en']

export function getStoredLocale() {
  try {
    const v = localStorage.getItem(LOCALE_KEY)
    if (v === 'en' || v === 'zh-TW') return v
  } catch (_) {}
  return 'en'
}

export function setStoredLocale(locale) {
  try {
    localStorage.setItem(LOCALE_KEY, locale)
  } catch (_) {}
}

export function getApiLocale() {
  return getStoredLocale() === 'en' ? 'en' : 'zh-TW'
}
