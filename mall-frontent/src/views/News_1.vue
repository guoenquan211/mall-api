<script setup>
import { ref, onMounted } from 'vue';
import { useHead } from '@unhead/vue';
import { useI18n } from 'vue-i18n';
import { api } from '../api';
import { pickLocalized } from '../utils/localeDisplay.js';

const { locale, t } = useI18n();
const newsList = ref([]);
const loading = ref(true);
const selectedNews = ref(null);
const fallbackImg = 'https://images.unsplash.com/photo-1525331282665-08c7bb35f7d0?q=80&w=1200&auto=format&fit=crop';

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

onMounted(async () => {
  try {
    const res = await api.getNews();
    if (res.code === 0) {
      newsList.value = res.data.data || res.data;
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
        <article class="news-card" v-for="news in newsList" :key="news.id">
          <div class="news-image">
            <img :src="news.image" :alt="pickLocalized(locale, news.title, news.title_en)" @error="handleImgError" loading="lazy" />
          </div>
          <div class="news-content">
            <div class="news-meta">
              <span class="date">{{ news.date }}</span>
              <span class="category">{{ news.category }}</span>
            </div>
            <h3 class="news-title">{{ pickLocalized(locale, news.title, news.title_en) }}</h3>
            <p class="news-excerpt">{{ pickLocalized(locale, news.summary || news.excerpt, news.summary_en) }}</p>
            <a href="#" class="read-more" @click.prevent="openModal(news)" :aria-label="$t('news.readMore')">{{ $t('news.readMore') }}</a>
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
            <div class="modal-image" v-if="selectedNews.image">
              <img :src="selectedNews.image" :alt="pickLocalized(locale, selectedNews.title, selectedNews.title_en)" @error="handleImgError" />
            </div>
            <div class="content-text" v-html="pickLocalized(locale, selectedNews.content || selectedNews.excerpt, selectedNews.content_en)"></div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<style scoped>
.page-container {
  padding: 4rem 2rem;
  max-width: 1280px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 5rem;
}

.page-title {
  font-size: 3rem;
  margin-bottom: 1rem;
  letter-spacing: 0.1em;
}

.page-subtitle {
  color: var(--text-secondary);
  font-family: var(--font-display);
  letter-spacing: 0.2em;
  font-size: 0.9rem;
}

.news-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 3rem;
}

.news-card {
  display: flex;
  background-color: var(--surface-color);
  border: none;
  transition: all 0.4s ease;
  border-radius: var(--radius);
  box-shadow: var(--shadow-soft);
  overflow: hidden;
}

.news-card:hover {
  box-shadow: var(--shadow-hover);
  transform: translateY(-5px);
}

.news-image {
  flex: 0 0 38%;
  position: relative;
  overflow: hidden;
}

.news-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.6s ease;
}

.news-card:hover .news-image img {
  transform: scale(1.05);
}

.news-content {
  flex: 1;
  padding: 3.5rem;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: flex-start;
  text-align: left;
}

.news-meta {
  margin-bottom: 1.2rem;
  font-size: 0.8rem;
  color: var(--accent-color);
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-family: var(--font-display);
  display: flex;
  align-items: center;
}

.category {
  margin-left: 1rem;
  position: relative;
}

.category::before {
  content: '';
  display: inline-block;
  width: 1px;
  height: 10px;
  background-color: var(--accent-color);
  position: absolute;
  left: -0.6rem;
  top: 2px;
  opacity: 0.5;
}

.news-title {
  font-size: 1.8rem;
  margin-bottom: 1.5rem;
  line-height: 1.3;
  font-family: var(--font-serif);
  color: var(--primary-color);
  font-weight: 500;
}

.news-excerpt {
  color: var(--text-secondary);
  margin-bottom: 2.5rem;
  line-height: 1.8;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  font-size: 1rem;
}

.read-more {
  color: var(--primary-color);
  text-decoration: none;
  font-family: var(--font-serif);
  font-size: 0.95rem;
  border-bottom: 1px solid var(--border-color);
  padding-bottom: 4px;
  transition: all 0.3s ease;
  letter-spacing: 0.1em;
  margin-top: auto;
  align-self: flex-end;
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
  margin-bottom: 2rem;
  border-radius: 4px;
  overflow: hidden;
}

.modal-image img {
  width: 100%;
  height: auto;
  max-height: 400px;
  object-fit: cover;
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

.read-more:hover {
  color: var(--accent-color);
  border-bottom-color: var(--accent-color);
}

.loading {
  text-align: center;
  padding: 4rem;
  color: var(--text-secondary);
  font-size: 1.2rem;
}

@media (max-width: 900px) {
  .news-card {
    flex-direction: column;
  }
  .news-image {
    flex: 0 0 250px;
  }
}

@media (max-width: 768px) {
  .page-container {
    padding: 6rem 1.5rem 2rem 1.5rem;
  }

  .news-content {
    padding: 1.5rem;
  }

  .page-title {
    font-size: 2rem;
  }
}
</style>
