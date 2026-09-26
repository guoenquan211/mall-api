<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from '@unhead/vue';
import { useI18n } from 'vue-i18n';
import { api } from '../api';
import { useCart, useUser } from '../store';
import { toast } from '../components/Toast';
import { pickLocalized } from '../utils/localeDisplay.js';

const route = useRoute();
const router = useRouter();
const { locale, t } = useI18n();
const { addToCart } = useCart();
const { user } = useUser();

const product = ref(null);
const loading = ref(true);
const mainImage = ref('');
const selectedVariant = ref(null);
const purchaseQuantity = ref(1);
const fallbackImg = 'https://images.unsplash.com/photo-1525331282665-08c7bb35f7d0?q=80&w=1200&auto=format&fit=crop';

const currentPrice = computed(() => {
  if (selectedVariant.value) return selectedVariant.value.price;
  return product.value?.price || 0;
});

const currentStock = computed(() => {
  if (selectedVariant.value) return selectedVariant.value.stock;
  return product.value?.stock || 0;
});

const updatePurchaseQuantity = (delta) => {
  const newValue = purchaseQuantity.value + delta;
  if (newValue >= 1 && newValue <= currentStock.value) {
    purchaseQuantity.value = newValue;
  }
};

watch(purchaseQuantity, (newVal) => {
  if (newVal < 1) purchaseQuantity.value = 1;
  if (currentStock.value > 0 && newVal > currentStock.value) purchaseQuantity.value = currentStock.value;
});

const displayName = computed(() =>
  product.value ? pickLocalized(locale.value, product.value.name, product.value.name_en) : ''
);
const displayCategory = computed(() => {
  if (!product.value) return '';
  return pickLocalized(locale.value, product.value.category, product.value.category_name_en);
});
const displayDescription = computed(() =>
  product.value ? pickLocalized(locale.value, product.value.description, product.value.description_en) : ''
);

useHead({
  title: () => (displayName.value ? `${displayName.value} | CocoBrite` : 'Product | CocoBrite'),
  meta: [
    {
      name: 'description',
      content: () =>
        displayDescription.value
          ? String(displayDescription.value).replace(/<[^>]+>/g, ' ').slice(0, 280)
          : 'Shop CocoBrite body care — product details and options.'
    }
  ]
})

onMounted(async () => {
  const id = route.params.id;
  try {
    const res = await api.getProduct(id);
    if (res.code === 0) {
      product.value = res.data;
      // Initialize images array if not present or empty
      if (!product.value.images || product.value.images.length === 0) {
        product.value.images = [product.value.image];
      }
      
      mainImage.value = res.data.image;
      
      // Auto-select first variant if available
      if (res.data.variants && res.data.variants.length > 0) {
        selectedVariant.value = res.data.variants[0];
        if (selectedVariant.value.image) {
          mainImage.value = selectedVariant.value.image;
        }
      }
    }
  } catch (e) {
    console.error(e);
  } finally {
    loading.value = false;
  }
});

watch(selectedVariant, (newVal) => {
  purchaseQuantity.value = 1;
  if (newVal && newVal.image) {
    mainImage.value = newVal.image;
  } else if (product.value) {
    mainImage.value = product.value.image;
  }
});

const selectVariant = (variant) => {
  selectedVariant.value = variant;
};

const handleAddToCart = () => {
  if (product.value) {
    if (currentStock.value <= 0) {
      toast.warning(t('productDetail.stockWarn'));
      return;
    }
    
    const itemToAdd = {
      ...product.value,
      price: currentPrice.value,
      selectedVariant: selectedVariant.value,
      quantity: purchaseQuantity.value
    };
    
    addToCart(itemToAdd);
    toast.success('已加入购物车');
  }
};

const handleBuyNow = () => {
  if (product.value) {
     if (currentStock.value <= 0) {
      toast.warning(t('productDetail.stockWarn'));
      return;
    }

    const itemToAdd = {
      ...product.value,
      price: currentPrice.value,
      selectedVariant: selectedVariant.value,
      quantity: purchaseQuantity.value
    };
    
    addToCart(itemToAdd);
    // Directly go to cart (which acts as checkout)
    router.push('/cart');
  }
};

const handleMainImgError = (e) => {
  const img = e.target
  if (img.dataset.retry) {
    img.src = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxIDEiPjxyZWN0IHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFQkU2RDgiLz48L3N2Zz4='
    return
  }
  img.dataset.retry = 'true'
  img.src = fallbackImg
};

const shareProductUrl = computed(() => {
  if (!product.value?.id || !user.loggedIn || !user.invite_code) return ''
  if (typeof window === 'undefined') return ''
  return `${window.location.origin}/product/${product.value.id}?ref=${encodeURIComponent(user.invite_code)}`
})

const shareCopied = ref(false)
const copyProductShare = async () => {
  if (!shareProductUrl.value) {
    toast.warning('请先登录，系统将为您生成带邀请码的推广链接')
    router.push('/login')
    return
  }
  try {
    await navigator.clipboard.writeText(shareProductUrl.value)
    shareCopied.value = true
    toast.success('推广链接已复制')
    setTimeout(() => { shareCopied.value = false }, 2000)
  } catch {
    toast.error('复制失败')
  }
}
</script>

<template>
  <div class="page-container">
    <div v-if="loading" class="loading">加载中...</div>
    <div v-else-if="!product" class="not-found">商品未找到</div>
    <div v-else class="product-detail">
      <div class="image-gallery">
        <div class="main-image-wrapper">
          <img :src="mainImage" class="main-image" :alt="displayName" @error="handleMainImgError" loading="lazy" />
        </div>
        <div class="thumbnails" v-if="product.images && product.images.length > 1">
          <div 
            v-for="(img, index) in product.images" 
            :key="index"
            class="thumbnail-item"
            :class="{ active: mainImage === img }"
            @click="mainImage = img"
          >
            <img :src="img" :alt="`${displayName} ${index + 1}`" @error="handleMainImgError" />
          </div>
        </div>
      </div>
      
      <section class="product-info">
        <h1 class="product-title">{{ displayName }}</h1>
        <p class="product-price">¥{{ currentPrice }}</p>
        <p class="product-category">{{ $t('productDetail.categoryLine') }} {{ displayCategory }}</p>
        
        <div class="divider"></div>
        
        <!-- Variants Selection -->
        <div v-if="product.variants && product.variants.length > 0" class="variants-selection">
          <p class="section-label">规格选择</p>
          <div class="variant-tags">
            <button 
              v-for="v in product.variants" 
              :key="v.id"
              :class="['variant-tag', { active: selectedVariant && selectedVariant.id === v.id }]"
              @click="selectVariant(v)"
            >
              {{ v.name }}
            </button>
          </div>
        </div>

        <!-- Quantity Selection -->
        <div class="quantity-section">
          <p class="section-label">购买数量</p>
          <div class="quantity-control">
            <button class="qty-btn" @click="updatePurchaseQuantity(-1)" :disabled="purchaseQuantity <= 1">-</button>
            <input type="number" v-model.number="purchaseQuantity" class="qty-input" :max="currentStock" min="1">
            <button class="qty-btn" @click="updatePurchaseQuantity(1)" :disabled="purchaseQuantity >= currentStock">+</button>
          </div>
        </div>

        <p class="stock-info" :class="{ 'out-of-stock': currentStock <= 0 }">
          {{ $t('productDetail.stockLabel') }}: {{ currentStock > 0 ? currentStock : $t('productDetail.outOfStock') }}
        </p>

        <div class="product-desc-content" v-html="displayDescription"></div>

        <div class="share-strip" v-if="product">
          <span class="share-label">推广分享</span>
          <button type="button" class="share-link-btn" @click="copyProductShare">
            {{ shareCopied ? '已复制' : '复制带邀请码的商品链接' }}
          </button>
          <span v-if="!user.loggedIn" class="share-hint">登录后自动附带您的邀请码</span>
        </div>
        
        <div class="actions">
          <button 
            class="add-btn" 
            @click="handleAddToCart" 
            :disabled="currentStock <= 0"
            :class="{ disabled: currentStock <= 0 }"
          >
            {{ currentStock > 0 ? '加入购物车' : '缺货' }}
          </button>
          <button class="buy-btn" :disabled="currentStock <= 0" @click="handleBuyNow">立即购买</button>
        </div>
        
        <div class="service-tags">
          <span><i class="ri-plant-line"></i> {{ $t('productDetail.service1') }}</span>
          <span><i class="ri-truck-line"></i> {{ $t('productDetail.service2') }}</span>
          <span><i class="ri-shield-check-line"></i> {{ $t('productDetail.service3') }}</span>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 4rem 2rem;
  max-width: 1280px;
  margin: 0 auto;
}

.product-detail {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4rem;
}

.main-image-wrapper {
  width: 100%;
  height: 500px;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--border-color);
  margin-bottom: 1rem;
}

.main-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s;
}

.main-image:hover {
  transform: scale(1.05);
}

.thumbnails {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 0.5rem;
}

.thumbnail-item {
  aspect-ratio: 1;
  border-radius: 4px;
  overflow: hidden;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.2s;
}

.thumbnail-item.active {
  border-color: var(--primary-color);
}

.thumbnail-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.thumbnail-item:hover {
  opacity: 0.8;
}

.product-title {
  font-size: 2.5rem;
  margin-bottom: 1rem;
  font-family: var(--font-serif);
}

.product-price {
  font-size: 2rem;
  color: var(--primary-color);
  margin-bottom: 1rem;
  font-family: var(--font-sans);
}

.product-category {
  color: var(--text-secondary);
  margin-bottom: 1rem;
}

.stock-info {
  margin-bottom: 1.5rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.stock-info.out-of-stock {
  color: #cf1322;
}

.divider {
  height: 1px;
  background-color: var(--border-color);
  margin: 1.5rem 0;
}

.variants-selection {
  margin-bottom: 1.5rem;
}

.section-label {
  font-weight: 600;
  margin-bottom: 0.75rem;
  color: var(--text-main);
}

.variant-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.variant-tag {
  padding: 0.5rem 1rem;
  border: 1px solid var(--border-color);
  background: white;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.95rem;
  color: var(--text-main);
  transition: all 0.2s;
  flex: 0 0 auto; /* Prevent stretching */
}

.variant-tag:hover {
  border-color: var(--primary-color);
  color: var(--primary-color);
}

.variant-tag.active {
  background-color: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.quantity-section {
  margin-bottom: 1.5rem;
}

.quantity-control {
  display: flex;
  align-items: center;
  max-width: 150px;
  border: 1px solid var(--border-color);
  border-radius: 4px;
  overflow: hidden;
}

.qty-btn {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f5f5f5;
  border: none;
  cursor: pointer;
  font-size: 1.2rem;
  color: var(--text-main);
  padding: 0;
}

.qty-btn:disabled {
  color: #ccc;
  cursor: not-allowed;
}

.qty-btn:hover:not(:disabled) {
  background: #e5e5e5;
  transform: none; /* Override default button hover transform */
}

.qty-input {
  flex: 1;
  width: 50px;
  height: 40px;
  text-align: center;
  border: none;
  border-left: 1px solid var(--border-color);
  border-right: 1px solid var(--border-color);
  font-size: 1rem;
  -moz-appearance: textfield;
}

.qty-input::-webkit-outer-spin-button,
.qty-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.product-desc-content {
  line-height: 1.8;
  color: var(--text-secondary);
  margin-bottom: 3rem;
}

.product-desc-content :deep(p) {
  margin-bottom: 1rem;
}

.product-desc-content :deep(img) {
  max-width: 100%;
  border-radius: 4px;
  margin: 1rem 0;
}

.share-strip {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  margin: 1.25rem 0;
  padding: 0.75rem 1rem;
  background: var(--surface-color, #fafafa);
  border: 1px solid var(--border-color, #e8ddd4);
}
.share-label { font-size: 0.9rem; color: #666; }
.share-link-btn {
  background: var(--primary-color, #c1a366);
  color: #fff;
  border: none;
  padding: 0.45rem 1rem;
  cursor: pointer;
  font-size: 0.9rem;
}
.share-hint { font-size: 0.8rem; color: #999; }

.actions {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
}

button {
  flex: 1;
  padding: 1rem;
  font-size: 1.1rem;
  cursor: pointer;
  border: none;
  transition: all 0.3s;
}

.add-btn {
  background-color: var(--surface-color);
  border: 1px solid var(--primary-color);
  color: var(--primary-color);
}

.buy-btn {
  background-color: var(--primary-color);
  color: white;
}

button:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-2px);
}

button:disabled, .add-btn.disabled {
  background-color: #f5f5f5;
  color: #ccc;
  border-color: #eee;
  cursor: not-allowed;
  transform: none;
}

.service-tags {
  display: flex;
  gap: 1.5rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.loading, .not-found {
  text-align: center;
  padding: 4rem;
  font-size: 1.2rem;
  color: var(--text-secondary);
}

@media (max-width: 768px) {
  .page-container {
    padding: 6rem 1.5rem 2rem 1.5rem;
  }
  
  .product-detail {
    grid-template-columns: 1fr;
    gap: 2rem;
  }
  
  .main-image {
    height: 350px;
  }
  
  .product-title {
    font-size: 2rem;
  }
}
</style>
