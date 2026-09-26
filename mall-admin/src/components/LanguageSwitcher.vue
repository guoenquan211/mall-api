<script setup>
import { watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { setStoredLocale } from '../i18n/localeStorage.js'

const { locale } = useI18n()

const setLang = (code) => {
  locale.value = code
  setStoredLocale(code)
  try {
    document.documentElement.lang = code === 'en' ? 'en' : 'zh-Hant'
  } catch (_) {}
}

watch(locale, (v) => {
  try {
    document.documentElement.lang = v === 'en' ? 'en' : 'zh-Hant'
  } catch (_) {}
}, { immediate: true })
</script>

<template>
  <div class="lang-switch" role="navigation" aria-label="Language">
    <button type="button" :class="{ active: locale === 'en' }" @click="setLang('en')">EN</button>
    <span class="sep" aria-hidden="true">|</span>
    <button type="button" :class="{ active: locale === 'zh-TW' }" @click="setLang('zh-TW')">繁中</button>
  </div>
</template>

<style scoped>
.lang-switch {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.8rem;
  margin-right: 1rem;
}
.lang-switch button {
  background: none;
  border: none;
  padding: 0.25rem 0.35rem;
  cursor: pointer;
  color: var(--color-text-muted, #666);
  font-weight: 500;
}
.lang-switch button.active {
  color: var(--color-primary-dark, #111);
  text-decoration: underline;
  text-underline-offset: 3px;
}
.sep {
  color: #ccc;
  user-select: none;
}
</style>
