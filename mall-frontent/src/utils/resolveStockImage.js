import { IMAGE_BY_PUBLIC_PATH, IMG_FALLBACK_PRODUCT } from '../assets/stock-images.js'

/** 将数据库里遗留的 Unsplash 外链映射为本地素材 */
const UNSPLASH_TO_PATH = [
  ['photo-1620916566398', '/images/stock/lotion.jpg'],
  ['photo-1612817288484', '/images/stock/tube.jpg'],
  ['photo-1570172619644', '/images/stock/spa.jpg'],
  ['photo-1556228578', '/images/stock/hero.jpg'],
  ['photo-1525331282665', '/images/stock/news.jpg'],
  ['photo-1598528652309', '/images/stock/admin-login.jpg'],
]

function mapPublicPath(path) {
  if (!path) return ''
  const normalized = path.startsWith('/') ? path : `/${path}`
  return IMAGE_BY_PUBLIC_PATH[normalized] || IMAGE_BY_PUBLIC_PATH[path] || ''
}

export function resolveStockImage(url, fallback = IMG_FALLBACK_PRODUCT) {
  if (!url || typeof url !== 'string') return fallback
  const trimmed = url.trim()
  if (!trimmed) return fallback

  if (trimmed.includes('unsplash.com')) {
    for (const [needle, localPath] of UNSPLASH_TO_PATH) {
      if (trimmed.includes(needle)) {
        return mapPublicPath(localPath) || fallback
      }
    }
    return fallback
  }

  if (trimmed.startsWith('/storage/') || trimmed.startsWith('/uploads/') || /^https?:\/\//i.test(trimmed)) {
    return trimmed
  }

  if (trimmed.startsWith('/images/')) {
    return mapPublicPath(trimmed) || fallback
  }

  return trimmed
}
