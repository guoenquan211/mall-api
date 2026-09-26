export function isContentIconUrl(value) {
  if (!value || typeof value !== 'string') return false
  const v = value.trim()
  return /^https?:\/\//i.test(v) || v.startsWith('/storage/') || v.startsWith('/uploads/')
}

export function resolveContentIcon(value) {
  const v = (value || '').trim()
  if (isContentIconUrl(v)) {
    return { type: 'image', src: v, class: '' }
  }
  const cls = v || 'ri-sparkling-line'
  return { type: 'class', src: '', class: cls }
}
