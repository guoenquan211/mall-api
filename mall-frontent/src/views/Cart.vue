<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useCart } from '../store';
import { useUser } from '../store';
import { useRouter } from 'vue-router';
import { api } from '../api';
import { toast } from '../components/Toast';
import { formatPrice } from '../utils/formatMoney.js';

const { t } = useI18n()

const { cart, removeFromCart, updateQuantity, getTotal, clearCart } = useCart();
const { user } = useUser();
const router = useRouter();

const addresses = ref([])
const selectedAddressId = ref(null)
const loadingAddresses = ref(false)

const selectedAddress = computed(() =>
  addresses.value.find((a) => a.id === selectedAddressId.value) || null
)

const formatAddressLine = (addr) => {
  if (!addr) return ''
  const region = [addr.province, addr.city, addr.district, addr.detail].filter(Boolean).join(' ')
  return [addr.name, addr.phone, region].filter(Boolean).join(' · ')
}

const loadAddresses = async () => {
  if (!user.loggedIn || !user.id) return
  loadingAddresses.value = true
  try {
    const res = await api.getUserAddresses(user.id)
    if (res.code === 0) {
      addresses.value = res.data || []
      const def = addresses.value.find((a) => a.is_default) || addresses.value[0]
      selectedAddressId.value = def ? def.id : null
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingAddresses.value = false
  }
}

onMounted(() => {
  if (user.loggedIn) loadAddresses()
})

watch(
  () => user.loggedIn,
  (loggedIn) => {
    if (loggedIn) loadAddresses()
  }
)

const handleQuantityChange = (id, event) => {
  const qty = parseInt(event.target.value);
  updateQuantity(id, qty);
};

const handleCheckout = async () => {
  if (cart.length === 0) return;
  
  if (!user.loggedIn) {
    toast.warning(t('cart.needLogin'));
    router.push('/login');
    return;
  }

  if (!selectedAddress.value) {
    toast.warning(addresses.value.length === 0 ? t('cart.noAddress') : t('cart.selectAddress'));
    if (addresses.value.length === 0) {
      router.push({ path: '/user', query: { tab: 'address' } });
    }
    return;
  }

  const amount = getTotal();

  try {
    const addr = selectedAddress.value
    const orderData = {
      user_id: user.id,
      total_amount: amount,
      address: {
        id: addr.id,
        name: addr.name,
        phone: addr.phone,
        province: addr.province,
        city: addr.city,
        district: addr.district,
        detail: addr.detail,
        is_default: !!addr.is_default,
      },
      items: cart.map(item => ({
        id: item.id,
        name: item.name,
        image: item.image,
        price: item.price,
        quantity: item.quantity,
        variant_name: item.selectedVariant ? item.selectedVariant.name : ''
      }))
    };

    const res = await api.createOrder(orderData);
    if (res.code === 0) {
      clearCart();
      toast.success(t('cart.orderCreated', { no: res.data.order_no }));
      router.push(`/order/pay/${res.data.id}`);
    } else {
      toast.error(res.msg || t('cart.orderFail'));
    }
  } catch (e) {
    console.error(e);
    toast.error(t('common.systemError'));
  }
};
</script>

<template>
  <div class="page-container">
    <h1 class="page-title">{{ $t('cart.title') }}</h1>
    
    <div v-if="cart.length === 0" class="empty-cart">
      <i class="ri-shopping-cart-2-line icon"></i>
      <p>{{ $t('cart.empty') }}</p>
      <router-link to="/" class="go-shop-btn">{{ $t('cart.goShop') }}</router-link>
    </div>
    
    <div v-else class="cart-content">
      <div class="cart-list">
        <div class="cart-item" v-for="item in cart" :key="item._cartId || item.id">
          <img :src="item.image" :alt="item.name" class="item-img" />
          <div class="item-info">
            <h3>{{ item.name }}</h3>
            <p v-if="item.selectedVariant" class="variant-info">{{ item.selectedVariant.name }}</p>
            <p class="item-price">{{ formatPrice(item.price) }}</p>
          </div>
          <div class="item-actions">
            <input 
              type="number" 
              min="1" 
              :value="item.quantity" 
              @change="e => handleQuantityChange(item._cartId, e)"
              class="qty-input"
            />
            <button class="remove-btn" @click="removeFromCart(item._cartId)">{{ $t('cart.remove') }}</button>
          </div>
        </div>
      </div>
      
      <div class="cart-summary">
        <div class="address-section">
          <div class="address-section-head">
            <h3>{{ $t('cart.shippingAddress') }}</h3>
            <router-link :to="{ path: '/user', query: { tab: 'address' } }" class="manage-address-link">
              {{ $t('cart.addAddress') }}
            </router-link>
          </div>
          <p v-if="loadingAddresses" class="address-hint">{{ $t('cart.loadingAddress') }}</p>
          <div v-else-if="addresses.length === 0" class="address-empty">
            <p>{{ $t('cart.noAddress') }}</p>
            <router-link :to="{ path: '/user', query: { tab: 'address' } }" class="add-address-btn">
              {{ $t('cart.addAddress') }}
            </router-link>
          </div>
          <div v-else class="address-list">
            <label
              v-for="addr in addresses"
              :key="addr.id"
              class="address-card"
              :class="{ selected: selectedAddressId === addr.id }"
            >
              <input
                type="radio"
                name="checkout-address"
                :value="addr.id"
                v-model="selectedAddressId"
              />
              <div class="address-card-body">
                <div class="address-card-top">
                  <span class="addr-name">{{ addr.name }}</span>
                  <span class="addr-phone">{{ addr.phone }}</span>
                  <span v-if="addr.is_default" class="addr-default">{{ $t('cart.defaultTag') }}</span>
                </div>
                <p class="addr-line">{{ formatAddressLine(addr) }}</p>
              </div>
            </label>
          </div>
        </div>

        <div class="summary-row">
          <span>{{ $t('cart.subtotal') }}</span>
          <span class="price">{{ formatPrice(getTotal()) }}</span>
        </div>
        <button class="checkout-btn" @click="handleCheckout">{{ $t('cart.checkout') }}</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 4rem 2rem;
  max-width: 1280px;
  margin: 0 auto;
  min-height: 60vh;
}

.page-title {
  font-family: var(--font-serif);
  margin-bottom: 3rem;
  text-align: center;
}

.empty-cart {
  text-align: center;
  padding: 4rem 0;
}

.empty-cart .icon {
  font-size: 4rem;
  margin-bottom: 1rem;
  display: block;
}

.go-shop-btn {
  display: inline-block;
  margin-top: 1rem;
  padding: 0.8rem 2rem;
  background: var(--primary-color);
  color: white;
  text-decoration: none;
  border-radius: 4px;
}

.cart-content {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 3rem;
}

.cart-item {
  display: flex;
  gap: 1.5rem;
  padding: 1.5rem;
  background: var(--surface-color);
  margin-bottom: 1rem;
  border: 1px solid var(--border-color);
  align-items: center;
}

.item-img {
  width: 80px;
  height: 80px;
  object-fit: cover;
  border-radius: 4px;
}

.item-info {
  flex: 1;
}

.item-info h3 {
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
}

.variant-info {
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 0.5rem;
  background: #f5f5f5;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  display: inline-block;
}

.item-price {
  color: var(--primary-color);
  font-weight: bold;
}

.qty-input {
  width: 60px;
  padding: 0.5rem;
  border: 1px solid var(--border-color);
  margin-right: 1rem;
}

.remove-btn {
  color: #999;
  background: none;
  border: none;
  cursor: pointer;
}

.remove-btn:hover {
  color: red;
}

.cart-summary {
  background: var(--surface-color);
  padding: 2rem;
  height: fit-content;
  border: 1px solid var(--border-color);
}

.address-section {
  margin-bottom: 1.5rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid var(--border-color);
}

.address-section-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.address-section-head h3 {
  font-size: 1rem;
  margin: 0;
}

.manage-address-link {
  font-size: 0.85rem;
  color: var(--primary-color);
  text-decoration: none;
}

.manage-address-link:hover {
  text-decoration: underline;
}

.address-hint {
  font-size: 0.9rem;
  color: #888;
}

.address-empty {
  text-align: center;
  padding: 0.5rem 0;
}

.address-empty p {
  color: #888;
  margin-bottom: 0.75rem;
}

.add-address-btn {
  display: inline-block;
  padding: 0.5rem 1rem;
  border: 1px solid var(--primary-color);
  color: var(--primary-color);
  text-decoration: none;
  border-radius: 4px;
  font-size: 0.9rem;
}

.address-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 220px;
  overflow-y: auto;
}

.address-card {
  display: flex;
  gap: 0.5rem;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  cursor: pointer;
  transition: border-color 0.15s, background 0.15s;
}

.address-card.selected {
  border-color: var(--primary-color);
  background: rgba(0, 0, 0, 0.02);
}

.address-card input {
  margin-top: 0.25rem;
  flex-shrink: 0;
}

.address-card-body {
  flex: 1;
  min-width: 0;
}

.address-card-top {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  align-items: center;
  margin-bottom: 0.25rem;
}

.addr-name {
  font-weight: 600;
}

.addr-phone {
  color: #666;
  font-size: 0.9rem;
}

.addr-default {
  font-size: 0.7rem;
  padding: 0.1rem 0.4rem;
  background: var(--primary-color);
  color: #fff;
  border-radius: 3px;
}

.addr-line {
  font-size: 0.85rem;
  color: #555;
  line-height: 1.4;
  margin: 0;
  word-break: break-word;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 2rem;
  font-size: 1.2rem;
}

.price {
  color: var(--primary-color);
  font-weight: bold;
}

.checkout-btn {
  width: 100%;
  padding: 1rem;
  background: var(--primary-color);
  color: white;
  border: none;
  font-size: 1.1rem;
  cursor: pointer;
}

@media (max-width: 768px) {
  .page-container {
    padding: 6rem 1.5rem 2rem 1.5rem;
  }
  
  .cart-content {
    grid-template-columns: 1fr;
  }
  
  .cart-item {
    flex-direction: column;
    text-align: center;
  }
}
</style>
