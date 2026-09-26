/** CocoBrite 演示数据 — 美白身体乳为主打（与 admin 同源文案） */
export const LS_PRODUCTS = 'cocobrite_products_v1'
export const LS_NEWS = 'cocobrite_news_v1'
export const LS_KNOWLEDGE = 'cocobrite_knowledge_v1'
export const LS_MESSAGES = 'cocobrite_contact_messages_v1'
export const LS_CART = 'cocobrite_cart_v1'
export const LS_USER = 'cocobrite_user_v1'
export const LS_TOKEN = 'cocobrite_token_v1'
export const LS_INVITE_REF = 'cocobrite_invite_ref_v1'

import { IMG_HERO, IMG_LOTION, IMG_TUBE, IMG_SPA } from '../assets/stock-images.js'

export { IMG_HERO, IMG_LOTION, IMG_TUBE, IMG_SPA }

export const DEFAULT_PRODUCTS = [
  {
    id: 1,
    name: 'CocoBrite 光感美白身体乳',
    description: '烟酰胺 + 透明质酸，轻盈乳液质地，易吸收不假滑。实际效果因人而异。',
    price: 168,
    image: IMG_LOTION,
    category: '身体护理',
    stock: 200,
    status: 1,
    show_on_home: 1,
    variants: [
      { id: 101, name: '400ml 家庭装', price: 168, stock: 120, image: IMG_LOTION },
      { id: 102, name: '200ml 便携装', price: 98, stock: 80, image: IMG_LOTION },
    ],
  },
  {
    id: 2,
    name: 'CocoBrite 栀子花香氛身体乳',
    description: '淡雅花香，保湿润泽，适合日常浴后护理。',
    price: 128,
    image: IMG_TUBE,
    category: '香氛身体乳',
    stock: 150,
    status: 1,
    show_on_home: 1,
    variants: [
      { id: 201, name: '300ml', price: 128, stock: 100 },
      { id: 202, name: '300ml 双支礼盒', price: 238, stock: 50 },
    ],
  },
  { id: 3, name: 'CocoBrite 果酸柔滑身体乳', description: '温和果酸，帮助改善粗糙角质（敏感肌请先局部测试）。', price: 158, image: IMG_SPA, category: '身体护理', stock: 90, status: 1, show_on_home: 1, variants: [] },
  { id: 4, name: 'CocoBrite 维C亮采护手霜', description: '小巧便携，手部保湿提亮。', price: 48, image: IMG_TUBE, category: '手足护理', stock: 300, status: 1, show_on_home: 0, variants: [] },
  { id: 5, name: 'CocoBrite 身体精华油', description: '以油养肤，浴后按摩使用，滋润不黏腻。', price: 188, image: IMG_LOTION, category: '身体护理', stock: 60, status: 1, show_on_home: 0, variants: [] },
  { id: 6, name: 'CocoBrite 沐浴慕斯', description: '绵密泡沫，温和清洁，洗后不紧绷。', price: 88, image: IMG_SPA, category: '沐浴', stock: 120, status: 1, show_on_home: 0, variants: [] },
  { id: 7, name: 'CocoBrite 磨砂膏（椰奶香）', description: '细腻颗粒，关节暗沉部位轻柔打圈使用。', price: 118, image: IMG_SPA, category: '身体护理', stock: 75, status: 1, show_on_home: 0, variants: [] },
  { id: 8, name: 'CocoBrite 旅行装四件套', description: '身体乳 + 沐浴 + 手霜 + 发膜小样，出差旅行常备。', price: 99, image: IMG_TUBE, category: '礼盒', stock: 200, status: 1, show_on_home: 0, variants: [] },
]

export const DEFAULT_NEWS = [
  { id: 1, title: 'CocoBrite 光感系列全新升级上市', date: '2026.03.15', category: '品牌动态', image: IMG_LOTION, excerpt: '在保留经典配方的基础上，优化乳化体系与肤感，带来更轻盈的涂抹体验。产品信息以包装标注为准。', source: 'CocoBrite 品牌部' },
  { id: 2, title: '「以光养肤」主题快闪店登陆马尼拉 BGC', date: '2026.03.10', category: '线下活动', image: IMG_HERO, excerpt: '现场可体验身体乳质地测试、香氛小课堂，完成打卡即可获得小样礼赠。', source: '市场部' },
  { id: 3, title: '春季身体护理：浴后黄金 3 分钟', date: '2026.03.05', category: '美护课堂', image: IMG_SPA, excerpt: '浴后毛孔微张时涂抹身体乳，有助于提升保湿感受。干性肌肤可叠加精华油。', source: '护肤顾问团' },
  { id: 4, title: 'CocoBrite 携手皮肤科顾问发布《身体美白护理白皮书》', date: '2026.02.28', category: '行业合作', image: IMG_TUBE, excerpt: '从角质管理、保湿、防晒协同等维度，科普理性护理观念（非医疗建议）。', source: '品牌合作媒体' },
  { id: 5, title: '会员日预告：满赠身体乳中样', date: '2026.02.20', category: '促销预告', image: IMG_LOTION, excerpt: '每月 18 日会员专享，具体规则以活动页公示为准。', source: '电商运营' },
]

export const DEFAULT_KNOWLEDGE = [
  {
    id: 1,
    title: '身体乳怎么涂才不算「白涂」？',
    icon: 'ri-drop-line',
    desc: '用量、顺序与按摩手法，决定保湿与光泽感。',
    source: 'CocoBrite 美护课堂',
    content: `
      <h3>1. 用量</h3>
      <p>成人单次四肢建议约一元硬币大小的 2～3 倍，干燥季节可适当增加。</p>
      <h3>2. 时机</h3>
      <p>沐浴后轻轻擦干水分，在皮肤仍微润时涂抹，帮助形成保湿膜。</p>
      <h3>3. 顺序</h3>
      <p>先乳液/乳霜，如需使用身体油，可在其后薄涂锁水。</p>
      <h3>4. 按摩</h3>
      <p>由远端向心脏方向轻柔推按，促进吸收即可，不必用力揉搓。</p>
    `,
  },
  {
    id: 2,
    title: '烟酰胺身体乳：建立耐受小贴士',
    icon: 'ri-flask-line',
    desc: '从低频次、小面积开始，观察皮肤状态。',
    content: `
      <h3>1. 先局部测试</h3>
      <p>耳后或前臂内侧连续 2～3 天小面积试用，无刺痛泛红再扩大范围。</p>
      <h3>2. 与其他成分搭配</h3>
      <p>避免与高浓度果酸、A 醇类产品同晚叠涂于同一部位，降低刺激风险。</p>
      <h3>3. 防晒协同</h3>
      <p>日间暴露部位仍建议衣物遮挡或搭配防晒产品，护理效果因人而异。</p>
    `,
  },
  {
    id: 3,
    title: '鸡皮肤（毛周角化）日常护理思路',
    icon: 'ri-hand-heart-line',
    desc: '温和去角质 + 保湿为主，勿过度摩擦。',
    content: `
      <h3>1. 清洁</h3>
      <p>选择温和表活，水温不宜过高，减少皮脂过度流失。</p>
      <h3>2. 角质管理</h3>
      <p>含果酸或尿素类身体乳可帮助平滑肤质，从低浓度、低频次开始。</p>
      <h3>3. 严重情况</h3>
      <p>若红肿瘙痒明显，请咨询专业皮肤科医生。</p>
    `,
  },
  {
    id: 4,
    title: '香氛身体乳：如何让留香更自然？',
    icon: 'ri-leaf-line',
    desc: '叠香与用量控制，避免与香水「打架」。',
    content: `
      <h3>1. 同系列叠香</h3>
      <p>沐浴与身体乳选择相近香调，层次更协调。</p>
      <h3>2. 用量</h3>
      <p>香氛型产品先薄涂，再根据喜好补涂手腕、锁骨等体温较高部位。</p>
    `,
  },
  {
    id: 5,
    title: '美白化妆品合规提示（消费者必读）',
    icon: 'ri-shield-check-line',
    desc: '了解「美白」宣称的监管要求，理性选购。',
    content: `
      <h3>1. 特殊化妆品</h3>
      <p>在欧盟、美国、日本、中国等不同市场，「美白」或肤色相关宣称的监管分类与证据要求各不相同；购买前请查阅销售地的官方指南与产品包装说明。</p>
      <h3>2. 宣称边界</h3>
      <p>个体差异、生活习惯均会影响观感，不存在适用于所有人的承诺效果。</p>
      <h3>3. 选购建议</h3>
      <p>通过正规渠道购买，留存购物凭证，并仔细阅读包装上的全成分表与当地法规要求的标识信息。</p>
    `,
  },
  {
    id: 6,
    title: '旅行装箱：身体护理极简清单',
    icon: 'ri-suitcase-line',
    desc: '小容量与多效合一，减轻行李负担。',
    content: `
      <h3>1. 必备</h3>
      <p>便携装身体乳、防晒（暴露部位）、温和沐浴。</p>
      <h3>2. 加分项</h3>
      <p>迷你手霜、润唇膏、一次性压缩毛巾。</p>
    `,
  },
]

/** 商品分类（与 DEFAULT_PRODUCTS 的 category 一致，用于导航与筛选） */
export const PRODUCT_CATEGORY_LIST = [...new Set(DEFAULT_PRODUCTS.map((p) => p.category).filter(Boolean))]
