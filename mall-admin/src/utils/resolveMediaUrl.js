/** 上传文件、GCash 二维码等静态资源所在的后端根地址 */
export function getBackendOrigin() {
  const media = import.meta.env.VITE_MEDIA_ORIGIN
  if (media) {
    return String(media).replace(/\/$/, '')
  }

  const apiBase = import.meta.env.VITE_API_BASE || ''
  if (/^https?:\/\//i.test(apiBase)) {
    return apiBase.replace(/\/api\/?$/i, '')
  }

  if (import.meta.env.DEV) {
    return 'http://127.0.0.1:8000'
  }

  if (typeof window !== 'undefined' && window.location?.origin) {
    return window.location.origin
  }

  return ''
}

/** 将 /storage、/uploads 等后端路径转为浏览器可请求的完整 URL */
export function resolveMediaUrl(url) {
  if (!url) return ''
  const v = String(url).trim()
  if (!v) return ''
  if (/^https?:\/\//i.test(v) || v.startsWith('data:') || v.startsWith('blob:')) {
    return v
  }

  const path = v.startsWith('/') ? v : `/${v}`

  if (path.startsWith('/storage/') || path.startsWith('/uploads/')) {
    const origin = getBackendOrigin()
    if (origin) {
      return `${origin}${path}`
    }
  }

  return path
}
