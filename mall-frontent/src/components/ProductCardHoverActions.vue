<script setup>
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useUser } from '../store'
import { toast } from './Toast'

const props = defineProps({
  product: {
    type: Object,
    required: true,
  },
})

const { t } = useI18n()
const router = useRouter()
const { user, toggleFavorite, isFavorite } = useUser()

const favorited = () => isFavorite(props.product?.id)

const handleFavorite = () => {
  if (!props.product?.id) return
  const added = toggleFavorite(props.product)
  toast.success(added ? t('productDetail.favoriteAdded') : t('productDetail.favoriteRemoved'))
}

const copyShare = async () => {
  if (!props.product?.id) return
  if (!user.loggedIn || !user.invite_code) {
    toast.warning(t('productDetail.shareLoginHint'))
    router.push('/login')
    return
  }
  const url = `${window.location.origin}/product/${props.product.id}?ref=${encodeURIComponent(user.invite_code)}`
  try {
    await navigator.clipboard.writeText(url)
    toast.success(t('productDetail.shareCopiedToast'))
  } catch {
    toast.error(t('common.copyFail'))
  }
}
</script>

<template>
  <div class="card-float-actions" @click.stop>
    <button
      type="button"
      class="card-icon-btn favorite-btn"
      :class="{ active: favorited() }"
      :aria-label="favorited() ? t('productDetail.favoriteRemove') : t('productDetail.favoriteAdd')"
      @click="handleFavorite"
    >
      <i :class="favorited() ? 'ri-heart-fill' : 'ri-heart-line'" aria-hidden="true"></i>
    </button>
    <button
      type="button"
      class="card-icon-btn share-btn"
      :aria-label="t('productDetail.shareTagTitle')"
      @click="copyShare"
    >
      <i class="ri-share-forward-line" aria-hidden="true"></i>
    </button>
  </div>
</template>

<style scoped>
.card-float-actions {
  position: absolute;
  right: 0.65rem;
  bottom: 0.65rem;
  display: flex;
  gap: 0.45rem;
  z-index: 2;
}

.card-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2.25rem;
  height: 2.25rem;
  padding: 0;
  flex: none;
  border: none;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.96);
  color: var(--primary-color, #3d2b1f);
  font-size: 1.05rem;
  line-height: 1;
  cursor: pointer;
  box-shadow: 0 2px 10px rgba(45, 31, 26, 0.15);
  transition: transform 0.2s ease, background 0.2s ease, color 0.2s ease;
}

.card-icon-btn:hover {
  transform: scale(1.08);
  background: #fff;
}

.card-icon-btn.favorite-btn.active {
  color: #e11d48;
}

.card-icon-btn.share-btn:hover {
  color: var(--primary-color, #5c4033);
}
</style>
