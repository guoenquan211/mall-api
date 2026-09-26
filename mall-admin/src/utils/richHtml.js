import { resolveMediaUrl } from './resolveMediaUrl.js'

/** 将上传返回的绝对 URL 转为 /storage/... 相对路径，便于跨环境存储 */
export function normalizeStoragePath(url) {
  if (!url) return ''
  const v = String(url).trim()
  if (!v) return ''

  if (/^https?:\/\//i.test(v)) {
    try {
      const u = new URL(v)
      if (u.pathname.startsWith('/storage/') || u.pathname.startsWith('/uploads/')) {
        return u.pathname
      }
    } catch {
      /* ignore */
    }
    return v
  }

  return v.startsWith('/') ? v : `/${v}`
}

/** 保存前：富文本内 img src 统一为相对路径 */
export function normalizeRichHtmlStorage(html) {
  if (!html) return ''
  return String(html).replace(
    /(<img\b[^>]*\ssrc=)(["'])([^"']+)\2/gi,
    (_m, prefix, quote, src) => `${prefix}${quote}${normalizeStoragePath(src)}${quote}`
  )
}

/** 展示时：将 img src 转为可访问的完整 URL */
export function resolveRichHtml(html) {
  if (!html) return ''
  return String(html).replace(
    /(<img\b[^>]*\ssrc=)(["'])([^"']+)\2/gi,
    (_m, prefix, quote, src) => `${prefix}${quote}${resolveMediaUrl(normalizeStoragePath(src))}${quote}`
  )
}
