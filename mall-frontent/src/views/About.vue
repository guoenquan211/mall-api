<script setup>
import { useI18n } from 'vue-i18n'
import { useHead } from '@unhead/vue'

const { t } = useI18n()

useHead({
  title: () => `${t('about.title')} | CocoBrite`,
  meta: [
    {
      name: 'description',
      content: () => t('about.metaDescription'),
    },
  ],
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">{{ $t('about.title') }}</h1>
      <p class="page-subtitle">{{ $t('about.subtitle') }}</p>
    </div>

    <div class="content-wrapper">
      <div class="text-content">
        <p class="lead">{{ $t('about.lead') }}</p>
        <h3>{{ $t('about.section1Title') }}</h3>
        <p>{{ $t('about.section1Body') }}</p>
        <h3>{{ $t('about.section2Title') }}</h3>
        <p>{{ $t('about.section2Body') }}</p>
        <h3>{{ $t('about.section3Title') }}</h3>
        <p>{{ $t('about.section3Body') }}</p>
        <p class="contact-hint">
          {{ $t('about.contactHint') }}
          <router-link to="/contact">{{ $t('nav.contact') }}</router-link>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 4rem 2rem;
  max-width: 1000px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 3rem;
}

.page-title {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
  letter-spacing: 0.1em;
  font-family: var(--font-serif);
  font-weight: normal;
}

.page-subtitle {
  color: var(--text-secondary);
  font-family: var(--font-display);
  letter-spacing: 0.2em;
  font-size: 0.9rem;
}

.content-wrapper {
  background-color: var(--surface-color);
  padding: 3rem;
  border: 1px solid var(--border-color);
}

.text-content .lead {
  font-size: 1.05rem;
  color: var(--text-primary);
  line-height: 1.85;
  margin-bottom: 2rem;
}

.text-content h3 {
  font-family: var(--font-serif);
  font-size: 1.2rem;
  margin: 2rem 0 1rem;
  color: var(--text-primary);
  font-weight: normal;
}

.text-content p {
  color: var(--text-secondary);
  line-height: 1.8;
  margin-bottom: 1rem;
  text-align: justify;
}

.contact-hint {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--border-color);
}

.contact-hint a {
  color: var(--primary-color);
  text-decoration: underline;
  text-underline-offset: 3px;
}

@media (max-width: 768px) {
  .page-container {
    padding: 6rem 1.5rem 2rem;
  }

  .content-wrapper {
    padding: 1.5rem 1.25rem;
  }

  .page-title {
    font-size: 2rem;
  }
}
</style>
