<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useHead } from '@unhead/vue';
import { useI18n } from 'vue-i18n';
import { api } from '../api';
import { pickLocalized } from '../utils/localeDisplay.js';
import { resolveRichHtml } from '../utils/resolveRichHtml.js';
import { IMG_FALLBACK_NEWS } from '../assets/stock-images.js';
import { resolveStockImage } from '../utils/resolveStockImage.js';

const { locale, t } = useI18n();
const route = useRoute();
const newsList = ref([]);
const loading = ref(true);
const selectedNews = ref(null);
const fallbackImg = IMG_FALLBACK_NEWS;

useHead({
  title: 'Stories | CocoBrite',
  meta: [
    {
      name: 'description',
      content: 'CocoBrite news, launches, and body-care stories for our international community.'
    }
  ]
})

const openModal = (item) => {
  selectedNews.value = item;
  document.body.style.overflow = 'hidden';
};

const closeModal = () => {
  selectedNews.value = null;
  document.body.style.overflow = '';
};

const displayNewsContent = computed(() => {
  if (!selectedNews.value) return '';
  const raw = pickLocalized(
    locale.value,
    selectedNews.value.content || selectedNews.value.excerpt,
    selectedNews.value.content_en
  );
  return resolveRichHtml(raw);
});

onMounted(async () => {
  try {
    const res = await api.getNews();
    if (res.code === 0) {
      newsList.value = res.data.data || res.data;
      const id = Number(route.query.id);
      if (id > 0) {
        const item = newsList.value.find((n) => Number(n.id) === id);
        if (item) openModal(item);
      }
    }
  } catch (error) {
    console.error('Failed to fetch news:', error);
  } finally {
    loading.value = false;
  }
});

const handleImgError = (e) => {
  const img = e.target
  if (img.dataset.retry) {
    img.src = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxIDEiPjxyZWN0IHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFQkU2RDgiLz48L3N2Zz4='
    return
  }
  img.dataset.retry = 'true'
  img.src = fallbackImg
};
</script>

<template>
  <div class="page-container">
    <header class="page-header">
      <h1 class="page-title">{{ $t('news.title') }}</h1>
      <p class="page-subtitle">{{ $t('news.subtitle') }}</p>
    </header>

    <div class="news-container">
      <div v-if="loading" class="loading">{{ $t('news.loading') }}</div>
      <div v-else class="news-grid">
        <article
          class="news-card"
          v-for="news in newsList"
          :key="news.id"
          tabindex="0"
          @click="openModal(news)"
          @keydown.enter.prevent="openModal(news)"
        >
          <div class="news-image">
            <img :src="resolveStockImage(news.image || news.cover_image, IMG_FALLBACK_NEWS)" :alt="pickLocalized(locale, news.title, news.title_en)" @error="handleImgError" loading="lazy" />
          </div>
          <div class="news-content">
            <div class="news-meta">
              <span class="date">{{ news.date }}</span>
              <span v-if="news.category" class="category">{{ news.category }}</span>
            </div>
            <h3 class="news-title">{{ pickLocalized(locale, news.title, news.title_en) }}</h3>
            <p class="news-excerpt">{{ pickLocalized(locale, news.summary || news.excerpt, news.summary_en) }}</p>
            <span class="read-more">{{ $t('news.readMore') }} <i class="ri-arrow-right-line" aria-hidden="true"></i></span>
          </div>
        </article>
      </div>
    </div>

    <transition name="modal">
      <div v-if="selectedNews" class="modal-overlay" @click="closeModal" role="dialog" aria-modal="true">
        <div class="modal-content" @click.stop>
          <button class="close-btn" @click="closeModal" :aria-label="$t('news.close')">&times;</button>
          <div class="modal-header">
            <h2 class="modal-title">{{ pickLocalized(locale, selectedNews.title, selectedNews.title_en) }}</h2>
            <div class="modal-meta-detail">
              <span class="date">{{ selectedNews.date }}</span>
              <span class="category">{{ selectedNews.category }}</span>
              <span class="source" v-if="selectedNews.source">
                 <span class="source-label">{{ $t('news.sourceLabel') }}:</span> {{ selectedNews.source }}
              </span>
            </div>
          </div>
          <div class="modal-body">
            <div class="modal-image" v-if="selectedNews.image || selectedNews.cover_image">
              <img :src="resolveStockImage(selectedNews.image || selectedNews.cover_image, IMG_FALLBACK_NEWS)" :alt="pickLocalized(locale, selectedNews.title, selectedNews.title_en)" @error="handleImgError" />
            </div>
            <div class="content-text" v-html="displayNewsContent"></div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<style scoped>
.page-container {
  padding: 4rem 1.5rem 3rem;
  max-width: 920px;
  margin: 0 auto;
  --news-cover-ratio: 160 / 138;
}

.page-header {
  text-align: center;
  margin-bottom: 2.5rem;
}

.page-title {
  font-size: 2.25rem;
  margin-bottom: 0.65rem;
  letter-spacing: 0.08em;
}

.page-subtitle {
  color: var(--text-secondary);
  font-family: var(--font-display);
  letter-spacing: 0.14em;
  font-size: 0.82rem;
}

.news-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.news-card {
  display: grid;
  grid-template-columns: 160px minmax(0, 1fr);
  align-items: stretch;
  height: 138px;
  background-color: var(--surface-color);
  border: 1px solid rgba(0, 0, 0, 0.06);
  transition: border-color 0.25s ease, box-shadow 0.25s ease, transform 0.25s ease;
  border-radius: 12px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  overflow: hidden;
  cursor: pointer;
}

.news-card:hover,
.news-card:focus-visible {
  border-color: rgba(92, 64, 51, 0.18);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.07);
  transform: translateY(-2px);
  outline: none;
}

.news-image {
  position: relative;
  overflow: hidden;
  background: #f3f0ec;
  height: 100%;
  min-height: 0;
  aspect-ratio: var(--news-cover-ratio);
}

.news-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.45s ease;
}

.news-card:hover .news-image img {
  transform: scale(1.04);
}

.news-content {
  min-width: 0;
  height: 100%;
  overflow: hidden;
  padding: 0.85rem 1.15rem 0.8rem;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  text-align: left;
  box-sizing: border-box;
}

.news-meta {
  margin-bottom: 0.35rem;
  flex-shrink: 0;
  font-size: 0.72rem;
  color: var(--accent-color);
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-family: var(--font-display);
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem 0.75rem;
}

.category {
  position: relative;
  padding-left: 0.75rem;
}

.category::before {
  content: '';
  display: inline-block;
  width: 1px;
  height: 10px;
  background-color: var(--accent-color);
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0.45;
}

.news-title {
  font-size: 1.05rem;
  margin: 0 0 0.35rem;
  line-height: 1.4;
  font-family: var(--font-serif);
  color: var(--primary-color);
  font-weight: 500;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  flex-shrink: 0;
}

.news-excerpt {
  color: var(--text-secondary);
  margin: 0;
  line-height: 1.55;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  font-size: 0.86rem;
  flex: 1 1 auto;
  min-height: 0;
}

.read-more {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  color: var(--primary-color);
  font-family: var(--font-serif);
  font-size: 0.82rem;
  letter-spacing: 0.06em;
  margin-top: auto;
  flex-shrink: 0;
  transition: color 0.2s ease, gap 0.2s ease;
}

.read-more i {
  font-size: 0.95rem;
  transition: transform 0.2s ease;
}

.news-card:hover .read-more {
  color: var(--accent-color);
}

.news-card:hover .read-more i {
  transform: translateX(2px);
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.6);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  padding: 20px;
  backdrop-filter: blur(4px);
}

.modal-content {
  background-color: var(--surface-color);
  width: 100%;
  max-width: 800px;
  max-height: 90vh;
  border-radius: 8px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  animation: modalFadeIn 0.3s ease;
}

@keyframes modalFadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.close-btn {
  position: absolute;
  top: 15px;
  right: 20px;
  background: none;
  border: none;
  font-size: 2rem;
  cursor: pointer;
  color: var(--text-secondary);
  transition: color 0.3s;
  z-index: 10;
}

.close-btn:hover {
  color: var(--primary-color);
}

.modal-header {
  padding: 2rem 2.5rem 1rem;
  border-bottom: 1px solid var(--border-color);
}

.modal-title {
  font-size: 1.8rem;
  margin-bottom: 1rem;
  font-family: var(--font-serif);
  color: var(--primary-color);
  line-height: 1.3;
}

.modal-meta-detail {
  display: flex;
  gap: 1.5rem;
  font-size: 0.85rem;
  color: var(--text-secondary);
  font-family: var(--font-display);
  align-items: center;
}

.modal-meta-detail .category {
  color: var(--accent-color);
  margin-left: 0;
}

.modal-meta-detail .category::before {
  display: none;
}

.source {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: #f5f5f5;
  padding: 2px 8px;
  border-radius: 4px;
}

.source-label {
  color: #999;
}

.modal-body {
  padding: 2rem 2.5rem;
  overflow-y: auto;
  line-height: 1.8;
  color: var(--text-primary);
}

.modal-image {
  width: 100%;
  max-width: 560px;
  margin: 0 auto 1.5rem;
  aspect-ratio: var(--news-cover-ratio);
  border-radius: 8px;
  overflow: hidden;
  background: #f3f0ec;
}

.modal-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center;
  display: block;
}

.content-text :deep(p) {
  margin-bottom: 1.5rem;
}

.content-text :deep(h3) {
  margin-top: 2rem;
  margin-bottom: 1rem;
  font-family: var(--font-serif);
  color: var(--primary-color);
}

.content-text :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 4px;
  margin: 1rem 0;
  display: block;
}

.read-more:hover {
  color: var(--accent-color);
}

.loading {
  text-align: center;
  padding: 4rem;
  color: var(--text-secondary);
  font-size: 1.2rem;
}

@media (max-width: 640px) {
  .page-container {
    --news-cover-ratio: auto;
  }

  .news-card {
    grid-template-columns: 1fr;
    height: auto;
  }

  .news-image {
    height: 152px;
    aspect-ratio: unset;
  }

  .news-content {
    height: 132px;
  }

  .modal-image {
    max-width: none;
    aspect-ratio: unset;
    height: 152px;
  }

  .news-title {
    font-size: 1rem;
  }
}

@media (max-width: 768px) {
  .page-container {
    padding: 6rem 1.25rem 2rem;
  }

  .page-title {
    font-size: 1.85rem;
  }

  .page-header {
    margin-bottom: 2rem;
  }
}
</style>
