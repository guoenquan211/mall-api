/** 前台 zh-TW / en 顯示：英文介面優先英文欄位，缺則回退繁中 */
export function pickLocalized(locale, zhTw, en) {
  const z = zhTw != null ? String(zhTw).trim() : ''
  const e = en != null ? String(en).trim() : ''
  if (locale === 'en') {
    if (e) return e
    return z || e
  }
  if (z) return z
  return e || z
}

/** API 分類導覽項：字串（舊格式）或 { key, name, name_en } */
export function categoryFilterKey(c) {
  if (c != null && typeof c === 'object') {
    const k = c.key != null ? String(c.key).trim() : ''
    if (k) return k
    return String(c.name ?? '').trim()
  }
  return String(c ?? '').trim()
}

export function categoryDisplayName(locale, c) {
  if (c != null && typeof c === 'object') {
    return pickLocalized(locale, c.name, c.name_en)
  }
  return String(c ?? '')
}
