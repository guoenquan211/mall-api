import {
  DEFAULT_PRODUCTS,
  DEFAULT_NEWS,
  DEFAULT_KNOWLEDGE,
  LS_PRODUCTS,
  LS_NEWS,
  LS_KNOWLEDGE,
  PRODUCT_CATEGORY_LIST,
} from './cocobrite-data.js'
import { getApiLocale } from '../i18n/localeStorage.js'

function localeFetch(url, init = {}) {
  const headers = new Headers(init.headers || {})
  headers.set('X-Locale', getApiLocale())
  return fetch(url, { credentials: 'include', ...init, headers })
}

const getLocalData = (key, defaultData) => {
  const stored = localStorage.getItem(key);
  return stored ? JSON.parse(stored) : defaultData;
};

/** 若后端误返回分页列表（历史上 products 路由顺序问题），从中取出对应 id 的商品 */
function normalizeProductDetailResponse(body, id) {
  if (!body || Number(body.code) !== 0) return body
  const d = body.data
  if (d && typeof d === 'object' && Array.isArray(d.data) && d.total !== undefined && d.id === undefined) {
    const row = d.data.find((p) => String(p?.id) === String(id))
    if (row) return { ...body, data: row }
  }
  return body
}

const USE_MOCK = false;
const API_BASE = (() => {
  const envBase = import.meta.env?.VITE_API_BASE;
  if (envBase) return envBase;
  if (import.meta.env?.DEV) return '/api';
  if (typeof window !== 'undefined' && window.location?.origin) {
    return `${window.location.origin}/api`;
  }
  return '/api';
})();

export const api = {
  getCaptchaUrl: () => {
    const base = API_BASE.replace(/\/api\/?$/, '');
    return `${base}/captcha`;
  },

  // Auth
  login: async (data) => {
    if (USE_MOCK) return { code: 0, data: { token: 'mock', user: { id: 1, username: 'mock', nickname: 'MockUser' } } };
    const res = await localeFetch(`${API_BASE}/user/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...data, locale: getApiLocale() })
    });
    return res.json();
  },

  register: async (data) => {
    if (USE_MOCK) return { code: 0, msg: 'success' };
    const res = await localeFetch(`${API_BASE}/user/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...data, locale: getApiLocale() })
    });
    return res.json();
  },

  getAffiliatePublicConfig: async () => {
    const res = await localeFetch(`${API_BASE}/affiliate/public-config`);
    return res.json();
  },

  getUserAffiliateSummary: async (userId) => {
    const res = await localeFetch(`${API_BASE}/user/affiliate-summary?user_id=${encodeURIComponent(userId)}`);
    return res.json();
  },

  trackAffiliateClick: async (ref, productId = 0) => {
    const qs = new URLSearchParams({
      ref: String(ref),
      product_id: String(productId),
    });
    const res = await localeFetch(`${API_BASE}/affiliate/track-click`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: qs.toString(),
    });
    return res.json();
  },

  getUserWalletFlows: async (userId, params = {}) => {
    const qs = new URLSearchParams({ user_id: String(userId), ...params });
    const res = await localeFetch(`${API_BASE}/user/wallet-flows?${qs}`);
    return res.json();
  },

  getUserInfo: async (userId) => {
    const res = await localeFetch(`${API_BASE}/user/info/${encodeURIComponent(userId)}`);
    return res.json();
  },

  updateUserProfile: async (payload) => {
    const res = await localeFetch(`${API_BASE}/user/profile`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    return res.json();
  },

  getHomeConfig: async () => {
    const res = await localeFetch(`${API_BASE}/home/public-config`);
    return res.json();
  },
  
  // Products
  getProducts: async (params = {}) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        let allProducts = getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS);
        
        // Filter by keyword if provided
        if (params && params.keyword) {
          const keyword = params.keyword.toLowerCase();
          allProducts = allProducts.filter(p => 
            p.name.toLowerCase().includes(keyword) || 
            p.description.toLowerCase().includes(keyword) ||
            p.category.toLowerCase().includes(keyword)
          );
        }

        if (params && params.category) {
          allProducts = allProducts.filter((p) => p.category === params.category);
        }

        if (params && params.status !== undefined && params.status !== null && params.status !== '') {
          const st = Number(params.status);
          allProducts = allProducts.filter((p) => Number(p.status ?? 1) === st);
        }

        if (params && params.show_on_home !== undefined && params.show_on_home !== null && params.show_on_home !== '') {
          const want = Number(params.show_on_home) === 1 ? 1 : 0;
          allProducts = allProducts.filter((p) => Number(p.show_on_home ?? 0) === want);
        }

        if (params && params.page && params.limit) {
          const page = parseInt(params.page);
          const limit = parseInt(params.limit);
          const start = (page - 1) * limit;
          const end = start + limit;
          const list = allProducts.slice(start, end);
          
          setTimeout(() => resolve({ 
            code: 0, 
            data: {
              list,
              total: allProducts.length
            }
          }), 500);
          return;
        }

        setTimeout(() => resolve({ code: 0, data: allProducts }), 500);
      });
    }
    const qs = new URLSearchParams();
    if (params) {
      Object.keys(params).forEach((key) => {
        const v = params[key];
        if (v !== undefined && v !== null) qs.append(key, v);
      });
    }
    const query = qs.toString();
    const res = await localeFetch(`${API_BASE}/products${query ? `?${query}` : ''}`);
    return res.json();
  },

  getProductCategories: async () => {
    if (USE_MOCK) {
      return new Promise((resolve) => {
        const fromLs = getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS);
        const list = [...new Set(fromLs.map((p) => p.category).filter(Boolean))];
        const raw = list.length ? list : [...PRODUCT_CATEGORY_LIST];
        const data = raw.map((c) =>
          typeof c === 'string' ? { key: c, name: c, name_en: null } : c
        );
        setTimeout(() => resolve({ code: 0, data }), 80);
      });
    }
    const res = await localeFetch(`${API_BASE}/products/categories`);
    const body = await res.json();
    if (body.code === 0 && Array.isArray(body.data)) {
      body.data = body.data.map((c) =>
        typeof c === 'string' ? { key: c, name: c, name_en: null } : c
      );
    }
    return body;
  },

  getProduct: async (id) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const products = getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS);
        const product = products.find(p => p.id == id);
        setTimeout(() => resolve({ code: 0, data: product }), 300);
      });
    }
    const res = await localeFetch(`${API_BASE}/products/${id}`);
    const body = await res.json();
    return normalizeProductDetailResponse(body, id);
  },

  getNews: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_NEWS, DEFAULT_NEWS) }), 400);
      });
    }
    const res = await localeFetch(`${API_BASE}/news?type=news&status=1&limit=200`);
    return res.json();
  },

  getKnowledge: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_KNOWLEDGE, DEFAULT_KNOWLEDGE) }), 400);
      });
    }
    const res = await localeFetch(`${API_BASE}/news?type=knowledge&status=1&limit=200`);
    return res.json();
  },

  submitContact: async (payload) => {
    const res = await localeFetch(`${API_BASE}/contact/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    return res.json();
  },

  // User Addresses
  getUserAddresses: async (userId) => {
    if (USE_MOCK) return { code: 0, data: [] };
    const res = await localeFetch(`${API_BASE}/users/${userId}/addresses`);
    return res.json();
  },

  saveUserAddress: async (address) => {
    if (USE_MOCK) return { code: 0 };
    const res = await localeFetch(`${API_BASE}/addresses/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(address)
    });
    return res.json();
  },

  deleteUserAddress: async (id) => {
    if (USE_MOCK) return { code: 0 };
    const res = await localeFetch(`${API_BASE}/addresses/${id}`, { method: 'DELETE' });
    return res.json();
  },
  
  // Orders
  createOrder: async (orderData) => {
    if (USE_MOCK) return { code: 0, data: { order_no: 'MOCK-' + Date.now() } };
    const res = await localeFetch(`${API_BASE}/orders/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData)
    });
    return res.json();
  },

  getOrders: async (params = {}) => {
    if (USE_MOCK) return { code: 0, data: [] };
    const qs = new URLSearchParams();
    Object.keys(params).forEach((key) => {
      const v = params[key];
      if (v !== undefined && v !== null) qs.append(key, v);
    });
    const query = qs.toString();
    const res = await localeFetch(`${API_BASE}/orders${query ? `?${query}` : ''}`);
    return res.json();
  },

  deleteUserOrder: async (userId, orderId) => {
    const res = await localeFetch(`${API_BASE}/user/delete-order`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: userId, order_id: orderId }),
    });
    return res.json();
  },

  getOrderPaymentInfo: async (orderId, userId) => {
    const qs = new URLSearchParams({ user_id: String(userId) });
    const res = await localeFetch(`${API_BASE}/gcash/order-payment/${orderId}?${qs}`);
    return res.json();
  },

  markOrderPaid: async (payload) => {
    const res = await localeFetch(`${API_BASE}/gcash/mark-order-paid`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    return res.json();
  },

  getGcashWalletSummary: async (userId) => {
    const res = await localeFetch(`${API_BASE}/gcash/wallet-summary?user_id=${encodeURIComponent(userId)}`);
    return res.json();
  },

  bindGcash: async (payload) => {
    const res = await localeFetch(`${API_BASE}/gcash/bind`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    return res.json();
  },

  createWithdrawal: async (payload) => {
    const res = await localeFetch(`${API_BASE}/gcash/withdraw`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    return res.json();
  },

  getMyWithdrawals: async (userId) => {
    const res = await localeFetch(`${API_BASE}/gcash/my-withdrawals?user_id=${encodeURIComponent(userId)}`);
    return res.json();
  },

  uploadImage: async (file) => {
    const formData = new FormData();
    formData.append('file', file);
    const res = await localeFetch(`${API_BASE}/upload/image`, {
      method: 'POST',
      body: formData,
    });
    return res.json();
  },
};
