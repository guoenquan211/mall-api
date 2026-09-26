<script setup>
import { useCart } from '../store';
import { useUser } from '../store';
import { useRouter } from 'vue-router';
import { api } from '../api';
import { toast } from '../components/Toast';

const { cart, removeFromCart, updateQuantity, getTotal, clearCart } = useCart();
const { user, addPoints } = useUser();
const router = useRouter();

const handleQuantityChange = (id, event) => {
  const qty = parseInt(event.target.value);
  updateQuantity(id, qty);
};

const handleCheckout = async () => {
  if (cart.length === 0) return;
  
  if (!user.loggedIn) {
    toast.warning('请先登录');
    router.push('/login');
    return;
  }

  const amount = getTotal();
  // if (!confirm(`确认支付 ¥${amount} 吗？`)) return;

  try {
    const orderData = {
      user_id: user.id,
      total_amount: amount,
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
      addPoints(amount); // Keep frontend points for immediate feedback, though backend should ideally handle it
      clearCart();
      toast.success(`支付成功！订单号: ${res.data.order_no}`);
      router.push('/user');
    } else {
      toast.error(res.msg || '下单失败');
    }
  } catch (e) {
    console.error(e);
    toast.error('系统错误');
  }
};
</script>

<template>
  <div class="page-container">
    <h1 class="page-title">购物车</h1>
    
    <div v-if="cart.length === 0" class="empty-cart">
      <i class="ri-shopping-cart-2-line icon"></i>
      <p>购物车还是空的，去看看光感美白身体乳吧</p>
      <router-link to="/" class="go-shop-btn">去逛逛</router-link>
    </div>
    
    <div v-else class="cart-content">
      <div class="cart-list">
        <div class="cart-item" v-for="item in cart" :key="item._cartId || item.id">
          <img :src="item.image" :alt="item.name" class="item-img" />
          <div class="item-info">
            <h3>{{ item.name }}</h3>
            <p v-if="item.selectedVariant" class="variant-info">{{ item.selectedVariant.name }}</p>
            <p class="item-price">¥{{ item.price }}</p>
          </div>
          <div class="item-actions">
            <input 
              type="number" 
              min="1" 
              :value="item.quantity" 
              @change="e => handleQuantityChange(item._cartId, e)"
              class="qty-input"
            />
            <button class="remove-btn" @click="removeFromCart(item._cartId)">删除</button>
          </div>
        </div>
      </div>
      
      <div class="cart-summary">
        <div class="summary-row">
          <span>商品总计：</span>
          <span class="price">¥{{ getTotal() }}</span>
        </div>
        <button class="checkout-btn" @click="handleCheckout">立即结算</button>
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
