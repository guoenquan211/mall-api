<script setup>
import { watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { setStoredLocale } from '../i18n/localeStorage.js'

const { theme } = defineProps({
  /** 页脚等深色背景上使用，提高文字对比度 */
  theme: {
    type: String,
    default: 'default',
    validator: (v) => ['default', 'dark'].includes(v),
  },
})

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
  <div class="lang-switch" :class="`lang-switch--${theme}`" role="navigation" aria-label="Language">
    <button
      type="button"
      :class="{ active: locale === 'en' }"
      @click="setLang('en')"
    >
      EN
    </button>
    <span class="sep" aria-hidden="true">|</span>
    <button
      type="button"
      :class="{ active: locale === 'zh-TW' }"
      @click="setLang('zh-TW')"
    >
      繁中
    </button>
  </div>
</template>

<style scoped>
.lang-switch {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.8rem;
  font-family: var(--font-sans, system-ui, sans-serif);
}
.lang-switch button {
  background: none;
  border: none;
  padding: 0.25rem 0.35rem;
  cursor: pointer;
  color: var(--text-secondary, #666);
  font-weight: 500;
}
.lang-switch button:hover {
  color: var(--text-primary, #111);
}
.lang-switch button.active {
  color: var(--text-primary, #111);
  text-decoration: underline;
  text-underline-offset: 3px;
}
.sep {
  color: #ccc;
  user-select: none;
}

/* 深色页脚：避免未选中项用 #666 导致看不清 */
.lang-switch--dark button {
  color: rgba(255, 255, 255, 0.78);
  font-size: 0.9rem;
}
.lang-switch--dark button:hover {
  color: #fff;
}
.lang-switch--dark button.active {
  color: #fff;
  font-weight: 600;
  text-decoration: underline;
  text-underline-offset: 4px;
}
.lang-switch--dark .sep {
  color: rgba(255, 255, 255, 0.45);
}

@media (max-width: 960px) {
  .lang-switch {
    margin: 0.5rem 0;
    justify-content: center;
  }
}
</style>
