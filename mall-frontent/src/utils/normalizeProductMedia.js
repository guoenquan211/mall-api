import { resolveStockImage } from './resolveStockImage.js'
import { resolveMediaUrl } from './resolveMediaUrl.js'

function resolveOneImage(url) {
  if (!url) return ''
  return resolveMediaUrl(resolveStockImage(String(url)))
}

/** API 的 product_images 可能是 [{ image, sort }] 或 string[] */
export function extractProductImageUrls(product) {
  if (!product) return []

  let images = product.images
  if (Array.isArray(images) && images.length > 0) {
    if (typeof images[0] === 'object' && images[0] !== null) {
      images = images
        .map((row) => (row && typeof row === 'object' ? row.image : row))
        .filter(Boolean)
    }
  } else if (product.image) {
    images = [product.image]
  } else {
    images = []
  }

  return images.map((url) => resolveOneImage(url)).filter(Boolean)
}

export function normalizeProductForDisplay(product) {
  if (!product) return product

  const images = extractProductImageUrls(product)
  const main = images[0] || resolveOneImage(product.image)

  return {
    ...product,
    image: main,
    images: images.length ? images : (main ? [main] : []),
    variants: (product.variants || []).map((v) => ({
      ...v,
      image: v.image ? resolveOneImage(v.image) : v.image,
    })),
  }
}
