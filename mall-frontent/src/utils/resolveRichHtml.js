import { resolveMediaUrl } from './resolveMediaUrl.js'

function normalizeStoragePath(url) {
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

/** 富文本 HTML 内图片 src 转为可访问 URL（支持 /storage 相对路径） */
export function resolveRichHtml(html) {
  if (!html) return ''
  return String(html).replace(
    /(<img\b[^>]*\ssrc=)(["'])([^"']+)\2/gi,
    (_m, prefix, quote, src) => `${prefix}${quote}${resolveMediaUrl(normalizeStoragePath(src))}${quote}`
  )
}
