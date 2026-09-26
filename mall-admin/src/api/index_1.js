import {
  DEFAULT_PRODUCTS,
  DEFAULT_NEWS_ADMIN,
  DEFAULT_KNOWLEDGE,
  DEFAULT_USERS,
  DEFAULT_ORDERS,
  DEFAULT_LOGS,
  DEFAULT_ADMINS,
  DEFAULT_ADDRESSES,
  LS_PRODUCTS,
  LS_NEWS,
  LS_KNOWLEDGE,
  LS_USERS,
  LS_ADDRESSES,
  LS_ADMINS,
  LS_ORDERS,
  LS_LOGS,
} from './cocobrite-data.js'

/** 后台资讯列表（含 content） */
const DEFAULT_NEWS = DEFAULT_NEWS_ADMIN

const TRAFFIC_STATS = [
  { name: '身體護理', value: 42000 },
  { name: '香氛身體乳', value: 28000 },
  { name: '手足護理', value: 12000 },
  { name: '沐浴', value: 9600 },
  { name: '禮盒', value: 6200 },
];

const TRAFFIC_TRENDS = (() => {
  const out = [];
  for (let i = 13; i >= 0; i--) {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() - i);
    const ymd = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    out.push({
      date: ymd,
      revenue: 800 + i * 120 + (i % 3) * 200,
      orders: 1 + (i % 5),
      activity: 5 + (i % 7) * 2,
    });
  }
  return out;
})();

const getLocalData = (key, defaultData) => {
  const stored = localStorage.getItem(key);
  return stored ? JSON.parse(stored) : defaultData;
};

const setLocalData = (key, data) => {
  localStorage.setItem(key, JSON.stringify(data));
};

const USE_MOCK = false;
const API_BASE = import.meta.env.VITE_API_BASE || '/api';

export const api = {
  // Products
  getProducts: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS) }), 500);
      });
    }
    const res = await fetch(`${API_BASE}/products`);
    return res.json();
  },

  getProduct: async (id) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const products = getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS);
        const product = products.find(p => p.id === id);
        setTimeout(() => resolve({ code: product ? 0 : 404, data: product }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/products/${id}`);
    return res.json();
  },

  listProductCategories: async () => {
    const res = await fetch(`${API_BASE}/product-categories`);
    return res.json();
  },

  saveProductCategory: async (row) => {
    const res = await fetch(`${API_BASE}/product-categories/save`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(row),
    });
    return res.json();
  },

  deleteProductCategory: async (id) => {
    const res = await fetch(`${API_BASE}/product-categories/${id}`, { method: 'DELETE' });
    return res.json();
  },

  getAffiliateAdminConfig: async () => {
    const res = await fetch(`${API_BASE}/affiliate-admin/config`);
    return res.json();
  },

  saveAffiliateAdminConfig: async (payload) => {
    const res = await fetch(`${API_BASE}/affiliate-admin/config`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    return res.json();
  },

  runAffiliateUnlock: async () => {
    const res = await fetch(`${API_BASE}/affiliate-admin/unlock-commissions`, { method: 'POST' });
    return res.json();
  },

  runAffiliateSettle: async (period) => {
    const qs = period ? `?period=${encodeURIComponent(period)}` : '';
    const res = await fetch(`${API_BASE}/affiliate-admin/settle-commissions${qs}`, { method: 'POST' });
    return res.json();
  },

  saveProduct: async (product) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const products = getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS);
        let actionType = '新增';
        if (product.id) {
            actionType = '更新';
            const index = products.findIndex(p => p.id === product.id);
            if (index !== -1) products[index] = { ...products[index], ...product };
        } else {
            product.id = Date.now();
            products.unshift(product);
        }
        setLocalData(LS_PRODUCTS, products);
        api.addLog({ action: actionType, target: '商品', detail: `${actionType}商品: ${product.name}` });
        setTimeout(() => resolve({ code: 0, msg: '保存成功' }), 500);
      });
    }
    const res = await fetch(`${API_BASE}/products/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(product)
    });
    return res.json();
  },

  deleteProduct: async (id) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const products = getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS);
        const index = products.findIndex(p => p.id === id);
        if (index !== -1) {
            const name = products[index].name;
            products.splice(index, 1);
            setLocalData(LS_PRODUCTS, products);
            api.addLog({ action: '删除', target: '商品', detail: `删除商品: ${name}` });
        }
        setTimeout(() => resolve({ code: 0, msg: '删除成功' }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/products/${id}`, { method: 'DELETE' });
    return res.json();
  },

  // Users
  getUsers: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_USERS, DEFAULT_USERS) }), 400);
      });
    }
    const res = await fetch(`${API_BASE}/users`);
    return res.json();
  },

  saveUser: async (user) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const users = getLocalData(LS_USERS, DEFAULT_USERS);
        const index = users.findIndex(u => u.id === user.id);
        if (index !== -1) {
            users[index] = { ...users[index], ...user };
            setLocalData(LS_USERS, users);
            api.addLog({ action: '更新', target: '用户', detail: `更新用户资料: ${user.username}` });
            resolve({ code: 0, msg: '保存成功' });
        } else {
            resolve({ code: -1, msg: '用户不存在' });
        }
      });
    }
    const res = await fetch(`${API_BASE}/users/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(user)
    });
    return res.json();
  },

  // User Addresses
  getUserAddresses: async (userId) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const addresses = getLocalData(LS_ADDRESSES, DEFAULT_ADDRESSES);
        const userAddresses = addresses.filter(addr => addr.user_id === userId);
        setTimeout(() => resolve({ code: 0, data: userAddresses }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/addresses?user_id=${userId}`);
    return res.json();
  },

  saveUserAddress: async (address) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const addresses = getLocalData(LS_ADDRESSES, DEFAULT_ADDRESSES);
        let action = '新增';
        if (address.id) {
          action = '更新';
          const index = addresses.findIndex(a => a.id === address.id);
          if (index !== -1) addresses[index] = { ...addresses[index], ...address };
        } else {
          address.id = Date.now();
          addresses.push(address);
        }
        
        // Handle default address logic
        if (address.is_default === 1) {
          addresses.forEach(a => {
            if (a.user_id === address.user_id && a.id !== address.id) {
              a.is_default = 0;
            }
          });
        }
        
        setLocalData(LS_ADDRESSES, addresses);
        api.addLog({ action: action, target: '地址', detail: `${action}用户地址` });
        setTimeout(() => resolve({ code: 0, msg: '保存成功' }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/addresses/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(address)
    });
    return res.json();
  },

  deleteUserAddress: async (id) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const addresses = getLocalData(LS_ADDRESSES, DEFAULT_ADDRESSES);
        const index = addresses.findIndex(a => a.id === id);
        if (index !== -1) {
             addresses.splice(index, 1);
             setLocalData(LS_ADDRESSES, addresses);
             api.addLog({ action: '删除', target: '地址', detail: `删除用户地址` });
        }
        setTimeout(() => resolve({ code: 0, msg: '删除成功' }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/addresses/${id}`, { method: 'DELETE' });
    return res.json();
  },

  // Admins
  getAdmins: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_ADMINS, DEFAULT_ADMINS) }), 400);
      });
    }
    const res = await fetch(`${API_BASE}/admins`);
    return res.json();
  },

  saveAdmin: async (admin) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const admins = getLocalData(LS_ADMINS, DEFAULT_ADMINS);
        let action = '新增';
        if (admin.id) {
            action = '更新';
            const index = admins.findIndex(a => a.id === admin.id);
            if (index !== -1) admins[index] = { ...admins[index], ...admin };
        } else {
            admin.id = Date.now();
            admin.last_login = '-';
            admins.push(admin);
        }
        setLocalData(LS_ADMINS, admins);
        api.addLog({ action: action, target: '管理员', detail: `${action}管理员: ${admin.username}` });
        setTimeout(() => resolve({ code: 0, msg: '保存成功' }), 400);
      });
    }
    const res = await fetch(`${API_BASE}/admins/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(admin)
    });
    return res.json();
  },

  deleteAdmin: async (id) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const admins = getLocalData(LS_ADMINS, DEFAULT_ADMINS);
        const index = admins.findIndex(a => a.id === id);
        if (index !== -1) {
            const username = admins[index].username;
            admins.splice(index, 1);
            setLocalData(LS_ADMINS, admins);
            api.addLog({ action: '删除', target: '管理员', detail: `删除管理员: ${username}` });
        }
        setTimeout(() => resolve({ code: 0, msg: '删除成功' }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/admins/${id}`, { method: 'DELETE' });
    return res.json();
  },

  // News
  getNews: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_NEWS, DEFAULT_NEWS) }), 400);
      });
    }
    const res = await fetch(`${API_BASE}/news`);
    return res.json();
  },

  saveNews: async (news) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const newsList = getLocalData(LS_NEWS, DEFAULT_NEWS);
        let action = '新增';
        if (news.id) {
            action = '更新';
            const index = newsList.findIndex(n => n.id === news.id);
            if (index !== -1) newsList[index] = { ...newsList[index], ...news };
        } else {
            news.id = Date.now();
            news.date = new Date().toLocaleDateString('zh-CN').replace(/\//g, '.');
            newsList.unshift(news);
        }
        setLocalData(LS_NEWS, newsList);
        api.addLog({ action: action, target: '资讯', detail: `${action}资讯: ${news.title}` });
        setTimeout(() => resolve({ code: 0, msg: '保存成功' }), 500);
      });
    }
    const res = await fetch(`${API_BASE}/news/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(news)
    });
    return res.json();
  },

  deleteNews: async (id) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const newsList = getLocalData(LS_NEWS, DEFAULT_NEWS);
        const index = newsList.findIndex(n => n.id === id);
        if (index !== -1) {
            const title = newsList[index].title;
            newsList.splice(index, 1);
            setLocalData(LS_NEWS, newsList);
            api.addLog({ action: '删除', target: '资讯', detail: `删除资讯: ${title}` });
        }
        setTimeout(() => resolve({ code: 0, msg: '删除成功' }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/news/${id}`, { method: 'DELETE' });
    return res.json();
  },

  // Knowledge
  getKnowledge: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_KNOWLEDGE, DEFAULT_KNOWLEDGE) }), 400);
      });
    }
    const res = await fetch(`${API_BASE}/knowledge`);
    return res.json();
  },

  saveKnowledge: async (item) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const list = getLocalData(LS_KNOWLEDGE, DEFAULT_KNOWLEDGE);
        let action = '新增';
        if (item.id) {
            action = '更新';
            const index = list.findIndex(k => k.id === item.id);
            if (index !== -1) list[index] = { ...list[index], ...item };
        } else {
            item.id = Date.now();
            list.unshift(item);
        }
        setLocalData(LS_KNOWLEDGE, list);
        api.addLog({ action: action, target: '知识', detail: `${action}知识: ${item.title}` });
        setTimeout(() => resolve({ code: 0, msg: '保存成功' }), 500);
      });
    }
    // Use News API but with type=knowledge
    item.type = 'knowledge';
    const res = await fetch(`${API_BASE}/news/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(item)
    });
    return res.json();
  },

  deleteKnowledge: async (id) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const list = getLocalData(LS_KNOWLEDGE, DEFAULT_KNOWLEDGE);
        const index = list.findIndex(k => k.id === id);
        if (index !== -1) {
            const title = list[index].title;
            list.splice(index, 1);
            setLocalData(LS_KNOWLEDGE, list);
            api.addLog({ action: '删除', target: '知识', detail: `删除知识: ${title}` });
        }
        setTimeout(() => resolve({ code: 0, msg: '删除成功' }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/news/${id}`, { method: 'DELETE' });
    return res.json();
  },

  // Mock Upload
  uploadImage: async (file) => {
    // Check if we can use real upload
    if (!USE_MOCK) {
        try {
            const formData = new FormData();
            formData.append('file', file);
            const res = await fetch(`${API_BASE}/upload/image`, {
                method: 'POST',
                body: formData
            });
            const data = await res.json();
            if (data.code === 0) {
                return data.data.url;
            }
        } catch (e) {
            console.error('Upload failed, fallback to mock', e);
        }
    }

    return new Promise(resolve => {
      // Create a fake URL for the uploaded image
      // In a real app, we would upload to server. 
      // Here we just use FileReader to show it locally or return a static mock image if file too large for localStorage
      const reader = new FileReader();
      reader.onload = (e) => {
        resolve({ code: 0, data: { url: e.target.result } });
      };
      reader.readAsDataURL(file);
    });
  },

  getStats: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({
          code: 0,
          data: {
            products: getLocalData(LS_PRODUCTS, DEFAULT_PRODUCTS).length,
            news: getLocalData(LS_NEWS, DEFAULT_NEWS).length,
            knowledge: getLocalData(LS_KNOWLEDGE, DEFAULT_KNOWLEDGE).length,
            users: getLocalData(LS_USERS, DEFAULT_USERS).length,
            orders: getLocalData(LS_ORDERS, DEFAULT_ORDERS).length,
            sales: {
              revenue_total: 128800,
              revenue_today: 3200,
              revenue_week: 18600,
              revenue_month: 45200,
              orders_pending_pay: 3,
              orders_to_ship: 5,
              orders_shipped: 2,
              orders_completed: 48,
              orders_cancelled: 1,
              avg_order_value: 2680,
              users_week: 4,
            },
          }
        }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/stats`);
    return res.json();
  },

  getTrafficStats: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: TRAFFIC_STATS }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/stats/traffic`);
    return res.json();
  },

  getTrafficTrends: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: TRAFFIC_TRENDS }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/stats/trends`);
    return res.json();
  },

  // Auth
  login: async (username, password) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(async () => {
          if (username === 'admin' && password === 'admin') {
            const token = 'mock_token_' + Date.now();
            const user = {
              id: 1,
              username: 'admin',
              nickname: '超级管理员',
              role: 'super_admin'
            };
            
            // In a real app, these would be set by the client after receiving response
            // But since we are mocking the "backend" here, we return them
            localStorage.setItem('admin_token', token);
            localStorage.setItem('admin_user', JSON.stringify(user));

            // Log is handled "server-side" (here in the mock api)
            await api.addLog({ 
              action: '登录', 
              target: '系统', 
              detail: `Admin 用户登录成功` 
            });

            resolve({ code: 0, msg: '登录成功', data: { token, user } });
          } else {
            resolve({ code: -1, msg: '用户名或密码错误' });
          }
        }, 800);
      });
    }
    
    try {
        const res = await fetch(`${API_BASE}/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        const data = await res.json();
        if (data.code === 0) {
            localStorage.setItem('admin_token', data.data.token);
            localStorage.setItem('admin_user', JSON.stringify(data.data.user));
        }
        return data;
    } catch (e) {
        console.error('Login error:', e);
        return { code: -1, msg: '网络错误或服务器异常' };
    }
  },

  // Orders
  getOrders: async (params = {}) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_ORDERS, DEFAULT_ORDERS) }), 500);
      });
    }
    const qs = new URLSearchParams();
    Object.keys(params).forEach(key => {
        if (params[key] !== null && params[key] !== undefined) {
            qs.append(key, params[key]);
        }
    });
    const query = qs.toString();
    const res = await fetch(`${API_BASE}/orders${query ? `?${query}` : ''}`);
    return res.json();
  },

  shipOrder: async (data) => {
    if (USE_MOCK) {
        return new Promise(resolve => {
            const orders = getLocalData(LS_ORDERS, DEFAULT_ORDERS);
            const index = orders.findIndex(o => o.id === data.id);
            if (index !== -1) {
                orders[index].status = 2;
                orders[index].express_company = data.express_company;
                orders[index].express_no = data.express_no;
                setLocalData(LS_ORDERS, orders);
                api.addLog({ action: '发货', target: '订单', detail: `订单发货: ${orders[index].order_no}` });
                resolve({ code: 0, msg: '发货成功' });
            } else {
                resolve({ code: -1, msg: '订单不存在' });
            }
        });
    }
    const res = await fetch(`${API_BASE}/orders/ship`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    return res.json();
  },

  saveOrder: async (order) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const orders = getLocalData(LS_ORDERS, DEFAULT_ORDERS);
        const index = orders.findIndex(o => o.id === order.id);
        if (index !== -1) {
          orders[index] = { ...orders[index], ...order };
          setLocalData(LS_ORDERS, orders);
          api.addLog({ action: '更新', target: '订单', detail: `更新订单状态: ${order.order_no}` });
          resolve({ code: 0, msg: '保存成功' });
        } else {
          resolve({ code: -1, msg: '订单不存在' });
        }
      });
    }
    return { code: -1, msg: 'API not implemented' };
  },

  uploadImage: async (file) => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        const reader = new FileReader();
        reader.onload = (e) => {
          setTimeout(() => resolve({ code: 0, data: { url: e.target.result } }), 500);
        };
        reader.readAsDataURL(file);
      });
    }
    const formData = new FormData();
    formData.append('file', file);
    const res = await fetch(`${API_BASE}/upload/image`, {
        method: 'POST',
        body: formData
    });
    return res.json();
  },

  // Logs
  getLogs: async () => {
    if (USE_MOCK) {
      return new Promise(resolve => {
        setTimeout(() => resolve({ code: 0, data: getLocalData(LS_LOGS, DEFAULT_LOGS) }), 300);
      });
    }
    const res = await fetch(`${API_BASE}/logs`);
    return res.json();
  },

  addLog: async (log) => {
    if (USE_MOCK) {
       const logs = getLocalData(LS_LOGS, DEFAULT_LOGS);
       const adminUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
       const newLog = {
         id: Date.now(),
         action: log.action,
         target: log.target,
         detail: log.detail,
         operator: adminUser.nickname || adminUser.username || 'System',
         role: adminUser.role || 'system',
         ip: '127.0.0.1',
         created_at: new Date().toLocaleString('zh-CN', { hour12: false }).replace(/\//g, '-')
       };
       logs.unshift(newLog);
       setLocalData(LS_LOGS, logs);
       return Promise.resolve({ code: 0 });
    }
    
    try {
        const userStr = localStorage.getItem('admin_user');
        if (userStr) {
            const user = JSON.parse(userStr);
            log.admin_id = user.id;
        }
        
        await fetch(`${API_BASE}/logs/add`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(log)
        });
    } catch (e) {
        console.error('Failed to add log', e);
    }
    return { code: 0 };
  },

  getContactMessages: async (params = {}) => {
    const qs = new URLSearchParams();
    if (params.page != null) qs.append('page', String(params.page));
    if (params.limit != null) qs.append('limit', String(params.limit));
    const suffix = qs.toString() ? `?${qs.toString()}` : '';
    const res = await fetch(`${API_BASE}/contact-messages${suffix}`);
    return res.json();
  },

  deleteContactMessage: async (id) => {
    const res = await fetch(`${API_BASE}/contact-messages/${id}`, { method: 'DELETE' });
    return res.json();
  },
};
