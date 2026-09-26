export const CURRENCY_SYMBOL = '₱'

export function formatPrice(amount) {
  if (amount == null || amount === '') return `${CURRENCY_SYMBOL}0`
  const n = Number(amount)
  if (Number.isNaN(n)) return `${CURRENCY_SYMBOL}${amount}`
  const fixed = Number.isInteger(n) ? String(n) : n.toFixed(2)
  return `${CURRENCY_SYMBOL}${fixed}`
}
