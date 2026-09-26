/**
 * 本地素材图（位于 src/assets/images，由 Vite 打包）
 * 数据库/API 仍可使用 /images/... 路径，经 resolveStockImage 映射为下方 URL
 */
import hero from './images/hero.jpg'
import story from './images/story.jpg'
import news1 from './images/news1.jpg'
import news2 from './images/news2.jpg'
import news3 from './images/news3.jpg'
import p1 from './images/p1.jpg'
import p2 from './images/p2.jpg'
import p3 from './images/p3.jpg'
import p4 from './images/p4.jpg'
import p5 from './images/p5.jpg'
import p6 from './images/p6.jpg'
import stockHero from './images/stock/hero.jpg'
import stockLotion from './images/stock/lotion.jpg'
import stockTube from './images/stock/tube.jpg'
import stockSpa from './images/stock/spa.jpg'
import stockNews from './images/stock/news.jpg'
import stockAdminLogin from './images/stock/admin-login.jpg'

export const IMG_HERO = stockHero
export const IMG_LOTION = stockLotion
export const IMG_TUBE = stockTube
export const IMG_SPA = stockSpa
export const IMG_NEWS = stockNews
export const IMG_STORY = story
export const IMG_ADMIN_LOGIN = stockAdminLogin

/** 商品/列表缺图时的默认图 */
export const IMG_FALLBACK_PRODUCT = IMG_LOTION

/** 资讯/详情缺图时的默认图 */
export const IMG_FALLBACK_NEWS = IMG_NEWS

/** 将历史 public 路径映射为打包后的资源 URL */
export const IMAGE_BY_PUBLIC_PATH = {
  '/images/hero.jpg': hero,
  '/images/story.jpg': story,
  '/images/news1.jpg': news1,
  '/images/news2.jpg': news2,
  '/images/news3.jpg': news3,
  '/images/p1.jpg': p1,
  '/images/p2.jpg': p2,
  '/images/p3.jpg': p3,
  '/images/p4.jpg': p4,
  '/images/p5.jpg': p5,
  '/images/p6.jpg': p6,
  '/images/stock/hero.jpg': stockHero,
  '/images/stock/lotion.jpg': stockLotion,
  '/images/stock/tube.jpg': stockTube,
  '/images/stock/spa.jpg': stockSpa,
  '/images/stock/news.jpg': stockNews,
  '/images/stock/admin-login.jpg': stockAdminLogin,
}
