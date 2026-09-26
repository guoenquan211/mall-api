/**
 * 商品列表「空态」流程图文案 — 與 vue-i18n 語系一致（zh-TW / en）。
 */
export const PRODUCT_LIST_EMPTY_FLOW = {
  'zh-TW': {
    step1: '選分類',
    step2: '看列表',
    step3: '進詳情',
    diagramAria: '選購流程：選分類、瀏覽列表、進入商品詳情',
  },
  en: {
    step1: 'Category',
    step2: 'Browse',
    step3: 'Details',
    diagramAria: 'Steps: choose a category, browse the list, open product details',
  },
}

const LOCALE_KEY = 'app_locale'

/** @param {string} [locale] vue-i18n locale：zh-TW | en */
export function productListEmptyFlowLabels(locale = 'zh-TW') {
  const raw = String(locale || '').toLowerCase()
  const key = raw === 'en' || raw.startsWith('en') ? 'en' : 'zh-TW'
  return PRODUCT_LIST_EMPTY_FLOW[key] || PRODUCT_LIST_EMPTY_FLOW['zh-TW']
}

export function detectShopLocale() {
  try {
    const v = localStorage.getItem(LOCALE_KEY)
    if (v === 'en' || v === 'zh-TW') return v
  } catch (_) {}
  if (typeof navigator !== 'undefined' && navigator.language) {
    return navigator.language
  }
  return 'zh-TW'
}
