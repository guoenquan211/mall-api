import { reactive, watch } from 'vue';
import { LS_CART, LS_USER, LS_TOKEN } from './api/cocobrite-data';

const LEGACY_CART = 'lanhua_cart';
const LEGACY_USER = 'lanhua_user';
const LEGACY_TOKEN = 'lanhua_token';

function readCartFromStorage() {
  const next = localStorage.getItem(LS_CART);
  const prev = localStorage.getItem(LEGACY_CART);
  if (next) return JSON.parse(next);
  if (prev) {
    localStorage.setItem(LS_CART, prev);
    localStorage.removeItem(LEGACY_CART);
    return JSON.parse(prev);
  }
  return [];
}

function readUserFromStorage() {
  const next = localStorage.getItem(LS_USER);
  const prev = localStorage.getItem(LEGACY_USER);
  const raw = next || prev;
  if (prev && !next) {
    localStorage.setItem(LS_USER, prev);
    localStorage.removeItem(LEGACY_USER);
  }
  return raw ? JSON.parse(raw) : null;
}

const cart = reactive(readCartFromStorage());

// Migration for existing cart items to have _cartId
cart.forEach(item => {
  if (!item._cartId) {
    item._cartId = Date.now() + Math.random().toString(36).substr(2, 9);
  }
});

watch(cart, (newCart) => {
  localStorage.setItem(LS_CART, JSON.stringify(newCart));
}, { deep: true });

export const useCart = () => {
  const addToCart = (product, quantity = 1) => {
    const existing = cart.find(item => {
      const sameId = item.id === product.id;
      const sameVariant = (item.selectedVariant?.id === product.selectedVariant?.id);
      return sameId && sameVariant;
    });
    
    if (existing) {
      existing.quantity += quantity;
    } else {
      cart.push({ 
        ...product, 
        quantity: quantity,
        _cartId: Date.now() + Math.random().toString(36).substr(2, 9)
      });
    }
  };

  const removeFromCart = (cartId) => {
    const index = cart.findIndex(item => item._cartId === cartId);
    if (index !== -1) cart.splice(index, 1);
  };

  const updateQuantity = (cartId, quantity) => {
    const item = cart.find(item => item._cartId === cartId);
    if (item) {
      item.quantity = parseInt(quantity);
      if (item.quantity <= 0) removeFromCart(cartId);
    }
  };

  const clearCart = () => {
    cart.length = 0;
  };

  const getCount = () => {
    return cart.reduce((sum, item) => sum + item.quantity, 0);
  };

  const getTotal = () => {
    return cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  };

  return { cart, addToCart, removeFromCart, updateQuantity, clearCart, getCount, getTotal };
};

const user = reactive(readUserFromStorage() || {
  name: '会员',
  avatar: '',
  email: '',
  loggedIn: false,
  points: 0,
  addresses: [],
  favorites: [],
  invite_code: '',
  affiliate_level: 0,
  username: '',
  nickname: '',
});

watch(user, (newUser) => {
  localStorage.setItem(LS_USER, JSON.stringify(newUser));
}, { deep: true });

export const useUser = () => {
  const addPoints = (amount) => {
    user.points += Math.floor(amount);
  };
  
  const toggleFavorite = (product) => {
    const pid = product?.id;
    if (pid == null) return false;
    const idx = user.favorites.findIndex((id) => String(id) === String(pid));
    if (idx > -1) {
      user.favorites.splice(idx, 1);
      return false;
    }
    user.favorites.push(pid);
    return true;
  };

  const removeFavorite = (productId) => {
    const idx = user.favorites.findIndex((id) => String(id) === String(productId));
    if (idx > -1) {
      user.favorites.splice(idx, 1);
    }
  };

  const isFavorite = (productId) =>
    user.favorites.some((id) => String(id) === String(productId));
  
  const addAddress = (address) => {
    // Deprecated: Addresses should be managed via API
    user.addresses.push({ id: Date.now(), ...address });
  };
  
  const removeAddress = (id) => {
    // Deprecated
    const idx = user.addresses.findIndex(a => a.id === id);
    if (idx !== -1) user.addresses.splice(idx, 1);
  };
  
  const login = async (credentials) => {
    try {
      const { api } = await import('./api');
      const res = await api.login(credentials);
      if (res.code === 0) {
        user.loggedIn = true;
        user.id = res.data.user.id;
        user.name = res.data.user.nickname || res.data.user.username;
        user.email = res.data.user.email;
        user.phone = res.data.user.phone;
        user.points = res.data.user.points || 0;
        user.username = res.data.user.username;
        user.nickname = res.data.user.nickname || res.data.user.username;
        user.invite_code = res.data.user.invite_code || '';
        user.affiliate_level = res.data.user.affiliate_level != null ? Number(res.data.user.affiliate_level) : 0;
        localStorage.setItem(LS_TOKEN, res.data.token);
        localStorage.removeItem(LEGACY_TOKEN);
        return true;
      }
    } catch (e) {
      console.error(e);
    }
    return false;
  };
  
  const register = async (data) => {
    try {
        const { api } = await import('./api');
        const { LS_INVITE_REF } = await import('./api/cocobrite-data.js');
        const invite = typeof localStorage !== 'undefined' ? localStorage.getItem(LS_INVITE_REF) : '';
        const payload = { ...data };
        if (invite) {
          payload.invite_code = invite;
        }
        const res = await api.register(payload);
        if (res.code === 0) {
            return await login({ username: data.username, password: data.password });
        }
    } catch (e) {
        console.error(e);
    }
    return false;
  };

  const logout = () => {
    user.loggedIn = false;
    user.name = '会员';
    user.email = '';
    user.phone = '';
    user.points = 0;
    user.username = '';
    user.nickname = '';
    user.invite_code = '';
    user.affiliate_level = 0;
    user.addresses = [];
    user.favorites = [];
    localStorage.removeItem(LS_TOKEN);
    localStorage.removeItem(LEGACY_TOKEN);
  };
  
  const updateProfile = (data) => {
    Object.assign(user, data);
  };

  return { 
    user, 
    addPoints, 
    toggleFavorite, 
    removeFavorite, 
    isFavorite, 
    addAddress, 
    removeAddress, 
    login, 
    register, 
    logout, 
    updateProfile 
  };
};
