<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useHead } from '@unhead/vue';
import { useI18n } from 'vue-i18n';
import { api } from '../api';
import { pickLocalized } from '../utils/localeDisplay.js';
import { resolveRichHtml } from '../utils/resolveRichHtml.js';
import { resolveContentIcon } from '../utils/contentIcon.js';

const itemIcon = (item) => resolveContentIcon(item?.icon);

const { locale, t } = useI18n();
const route = useRoute();
const knowledgeList = ref([]);
const loading = ref(true);
const selectedKnowledge = ref(null);

useHead({
  title: 'Care Guide | CocoBrite',
  meta: [
    {
      name: 'description',
      content: 'Practical body-care tips from CocoBrite — lotions, layering scents, and seasonal routines.'
    }
  ]
})

const openModal = (item) => {
  selectedKnowledge.value = item;
  document.body.style.overflow = 'hidden';
};

const closeModal = () => {
  selectedKnowledge.value = null;
  document.body.style.overflow = '';
};

const displayKnowledgeContent = computed(() => {
  if (!selectedKnowledge.value) return '';
  const raw = pickLocalized(
    locale.value,
    selectedKnowledge.value.content,
    selectedKnowledge.value.content_en
  );
  return resolveRichHtml(raw);
});

onMounted(async () => {
  try {
    const res = await api.getKnowledge();
    if (res.code === 0) {
      knowledgeList.value = res.data.data || res.data;
      const id = Number(route.query.id);
      if (id > 0) {
        const item = knowledgeList.value.find((n) => Number(n.id) === id);
        if (item) openModal(item);
      }
    }
  } catch (error) {
    console.error('Failed to fetch knowledge:', error);
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div class="page-container">
    <header class="page-header">
      <h1 class="page-title">{{ $t('knowledge.title') }}</h1>
      <p class="page-subtitle">{{ $t('knowledge.subtitle') }}</p>
    </header>

    <div v-if="loading" class="loading">{{ $t('knowledge.loading') }}</div>
    <div v-else class="knowledge-grid">
      <article class="knowledge-card" v-for="item in knowledgeList" :key="item.id">
        <div class="card-content">
          <div class="card-icon">
            <img v-if="itemIcon(item).type === 'image'" :src="itemIcon(item).src" alt="" class="icon-img" />
            <i v-else :class="itemIcon(item).class" aria-hidden="true"></i>
          </div>
          <h3 class="card-title">{{ pickLocalized(locale, item.title, item.title_en) }}</h3>
          <p class="card-desc">{{ pickLocalized(locale, item.summary || item.desc, item.summary_en) }}</p>
          <a href="#" class="learn-more" @click.prevent="openModal(item)" :aria-label="$t('knowledge.readMore')">{{ $t('knowledge.readMore') }}</a>
        </div>
      </article>
    </div>

    <transition name="modal">
      <div v-if="selectedKnowledge" class="modal-overlay" @click="closeModal" role="dialog" aria-modal="true">
        <div class="modal-content" @click.stop>
          <button class="close-btn" @click="closeModal" :aria-label="$t('knowledge.close')">&times;</button>
          <div class="modal-header">
            <div class="modal-icon">
              <img v-if="itemIcon(selectedKnowledge).type === 'image'" :src="itemIcon(selectedKnowledge).src" alt="" class="icon-img" />
              <i v-else :class="itemIcon(selectedKnowledge).class" aria-hidden="true"></i>
            </div>
            <h2 class="modal-title">{{ pickLocalized(locale, selectedKnowledge.title, selectedKnowledge.title_en) }}</h2>
          </div>
          <div class="modal-body" v-html="displayKnowledgeContent"></div>
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

.knowledge-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 2rem;
}

.knowledge-card {
  background-color: var(--surface-color);
  border: 1px solid var(--border-color);
  padding: 3rem 2rem;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.knowledge-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 0;
  background-color: #c1a366;
  transition: height 0.4s ease;
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
  display: flex;
  align-items: flex-start;
  gap: 1rem;
}

.header-text {
  flex: 1;
}

.modal-meta {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.source-tag {
  background: #f0f0f0;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.8rem;
  color: #666;
}

.modal-icon {
  font-size: 1.8rem;
  color: #c1a366;
}

.modal-title {
  font-size: 1.5rem;
  color: var(--primary-color);
  margin: 0;
}

.modal-body {
  padding: 2rem 2.5rem;
  overflow-y: auto;
  line-height: 1.8;
  color: var(--text-secondary);
}

.modal-body :deep(h3) {
  color: var(--primary-color);
  margin-top: 1.5rem;
  margin-bottom: 0.8rem;
  font-size: 1.2rem;
  font-weight: 600;
}

.modal-body :deep(p) {
  margin-bottom: 1rem;
  text-align: justify;
}

.modal-body :deep(strong) {
  color: var(--primary-color);
}

.modal-body :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 4px;
  margin: 1rem 0;
  display: block;
}

.knowledge-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 30px rgba(0,0,0,0.05);
}

.knowledge-card:hover::before {
  height: 100%;
}

.card-icon {
  font-size: 2rem;
  margin-bottom: 1.5rem;
  opacity: 0.8;
}

.card-icon .icon-img,
.modal-icon .icon-img {
  width: 2.5rem;
  height: 2.5rem;
  object-fit: contain;
  display: block;
}

.card-title {
  font-size: 1.4rem;
  margin-bottom: 1rem;
  font-family: var(--font-serif);
  line-height: 1.4;
}

.card-desc {
  color: var(--text-secondary);
  margin-bottom: 2rem;
  line-height: 1.8;
  font-size: 0.95rem;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.learn-more {
  color: var(--primary-color);
  text-decoration: none;
  font-weight: 600;
  font-size: 0.9rem;
  letter-spacing: 0.05em;
  position: relative;
  display: inline-block;
  margin-top: auto;
  align-self: flex-end;
}

.learn-more::after {
  content: '→';
  margin-left: 5px;
  transition: transform 0.3s;
  display: inline-block;
}

.learn-more:hover::after {
  transform: translateX(5px);
}

.loading {
  text-align: center;
  padding: 4rem;
  color: var(--text-secondary);
  font-size: 1.2rem;
}

@media (max-width: 640px) {
  .page-container {
    padding: 3rem 1rem 2rem 1rem;
  }
  .page-header {
    margin-bottom: 2.5rem;
  }
  .page-title {
    font-size: 2rem;
  }
  .page-subtitle {
    font-size: 0.8rem;
    letter-spacing: 0.15em;
  }
  .knowledge-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  .knowledge-card {
    padding: 1.5rem 1.25rem;
  }
  .card-icon {
    font-size: 1.6rem;
    margin-bottom: 1rem;
  }
  .card-title {
    font-size: 1.2rem;
    line-height: 1.35;
  }
  .card-desc {
    font-size: 0.95rem;
    line-height: 1.7;
    margin-bottom: 1.5rem;
  }
  .learn-more {
    font-size: 0.9rem;
  }
  .modal-content {
    max-width: 100%;
    max-height: 85vh;
    border-radius: 12px;
  }
  .modal-header {
    padding: 1.25rem 1.25rem 0.75rem;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
    text-align: center;
  }
  .modal-icon {
    font-size: 1.6rem;
  }
  .modal-title {
    font-size: 1.25rem;
  }
  .modal-body {
    padding: 1rem 1.25rem 1.25rem;
  }
  .modal-body :deep(h3) {
    font-size: 1.05rem;
    margin-top: 1rem;
  }
  .modal-body :deep(p) {
    font-size: 0.95rem;
    line-height: 1.8;
  }
  .close-btn {
    font-size: 1.6rem;
    top: 10px;
    right: 12px;
  }
}
</style>
