<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUser } from '../store'
import { toast } from '../components/Toast'
import { useHead } from '@unhead/vue'
import { api } from '../api'

const router = useRouter()
const { register } = useUser()
const form = ref({ username: '', password: '', confirmPassword: '', captcha: '' })
const captchaUrl = ref('')
const loading = ref(false)

const refreshCaptcha = () => {
  captchaUrl.value = `${api.getCaptchaUrl()}?t=${Date.now()}`
}

onMounted(() => {
  refreshCaptcha()
})

const defaultBrandUI = (import.meta.env?.VITE_BRAND_AUTH_UI === 'true')
const stored = (typeof localStorage !== 'undefined') ? localStorage.getItem('auth_ui_old') : null
const useOldUI = ref(stored ? stored === '1' : !defaultBrandUI)

useHead({
  title: 'Create Account | CocoBrite',
  meta: [
    { name: 'description', content: 'Create a CocoBrite account for faster checkout and order updates.' }
  ]
})

const handleSubmit = async () => {
  if (!form.value.username || !form.value.password) {
    toast.warning('请输入用户名和密码')
    return
  }
  if (!form.value.captcha) {
    toast.warning('请输入验证码')
    return
  }
  if (form.value.password !== form.value.confirmPassword) {
    toast.warning('两次输入的密码不一致')
    return
  }
  loading.value = true
  const ok = await register({ 
    username: form.value.username, 
    password: form.value.password,
    captcha: form.value.captcha
  })
  loading.value = false
  if (ok) {
    toast.success('注册成功')
    router.push('/user')
  } else {
    toast.error('注册失败')
    refreshCaptcha()
  }
}
const toggleUI = () => {
  useOldUI.value = !useOldUI.value
  if (typeof localStorage !== 'undefined') {
    localStorage.setItem('auth_ui_old', useOldUI.value ? '1' : '0')
  }
}
</script>

<template>
  <button class="style-toggle" @click="toggleUI">
    {{ useOldUI ? '切换至新版样式' : '切换至旧版样式' }}
  </button>
  <div v-if="!useOldUI" class="auth-section">
    <div class="auth-inner">
      <div class="auth-hero">
        <div class="brand">
          <img src="/logo.svg?v=6" alt="CocoBrite" class="brand-logo" />
          <div class="brand-texts">
            <h2>CocoBrite</h2>
            <p>身体护理 · 光感美白身体乳</p>
          </div>
        </div>
      </div>
      <div class="auth-card">
        <h1 class="card-title">加入 CocoBrite</h1>
        <p class="card-subtitle">创建账号，选购身体乳与护理系列</p>
        <div class="form">
          <div class="input-group">
            <i class="ri-user-line"></i>
            <input v-model="form.username" type="text" placeholder="用户名" />
          </div>
          <div class="input-group">
            <i class="ri-lock-line"></i>
            <input v-model="form.password" type="password" placeholder="密码" />
          </div>
          <div class="input-group">
            <i class="ri-lock-2-line"></i>
            <input v-model="form.confirmPassword" type="password" placeholder="确认密码" />
          </div>
          <div class="input-group captcha-group">
            <i class="ri-shield-check-line"></i>
            <input v-model="form.captcha" type="text" placeholder="验证码" />
            <img :src="captchaUrl" @click="refreshCaptcha" class="captcha-img" alt="验证码" />
          </div>
          <button class="submit-btn" @click="handleSubmit" :disabled="loading">{{ loading ? '注册中...' : '注册' }}</button>
          <div class="extra">
            <span>已经有账号？</span>
            <router-link to="/login">立即登录</router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="page-container">
    <div class="auth-card simple">
      <h1 class="page-title">注册</h1>
      <p class="page-subtitle">创建账号，开始鉴赏与收藏</p>
      <div class="form">
        <div class="input-group">
          <i class="ri-user-line"></i>
          <input v-model="form.username" type="text" placeholder="用户名" />
        </div>
        <div class="input-group">
          <i class="ri-lock-line"></i>
          <input v-model="form.password" type="password" placeholder="密码" />
        </div>
        <div class="input-group">
          <i class="ri-lock-2-line"></i>
          <input v-model="form.confirmPassword" type="password" placeholder="确认密码" />
        </div>
        <div class="input-group captcha-group">
          <i class="ri-shield-check-line"></i>
          <input v-model="form.captcha" type="text" placeholder="验证码" />
          <img :src="captchaUrl" @click="refreshCaptcha" class="captcha-img" alt="验证码" />
        </div>
        <button class="submit-btn" @click="handleSubmit" :disabled="loading">{{ loading ? '注册中...' : '注册' }}</button>
        <p class="switch">已经有账号？<router-link to="/login">去登录</router-link></p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.style-toggle {
  position: fixed;
  right: 16px;
  top: 80px;
  z-index: 10;
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  padding: 0.4rem 0.8rem;
  border-radius: 16px;
  cursor: pointer;
  font-size: 0.85rem;
}
.auth-section {
  min-height: 70vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  background:
    radial-gradient(1000px 500px at 80% 20%, rgba(193,163,102,0.08), transparent 60%),
    radial-gradient(800px 400px at 20% 80%, rgba(26,38,29,0.06), transparent 60%);
}
.auth-inner {
  width: 100%;
  max-width: 1100px;
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 3rem;
  align-items: center;
}
.auth-hero {
  background: var(--primary-color);
  border-radius: 20px;
  color: #fff;
  padding: 3rem;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}
.auth-hero::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url('/images/story.jpg');
  background-size: cover;
  background-position: center;
  opacity: 0.15;
}
.brand {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  position: relative;
  z-index: 1;
}
.brand-logo {
  width: 84px;
  height: 84px;
  border-radius: 16px;
  background: rgba(255,255,255,0.1);
  padding: 1rem;
}
.brand-texts h2 {
  margin: 0;
  font-family: var(--font-serif);
  font-size: 2rem;
  letter-spacing: 0.15em;
}
.brand-texts p {
  margin: 0.5rem 0 0;
  color: rgba(255,255,255,0.8);
}
.auth-card {
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  border-radius: 16px;
  padding: 2.5rem;
  box-shadow: var(--shadow-soft);
}
.card-title {
  margin: 0;
  font-size: 2rem;
}
.card-subtitle {
  color: var(--text-secondary);
  margin: 0.5rem 0 2rem;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.input-group {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 0.6rem 0.8rem;
  background: #fff;
}
.input-group i {
  color: var(--text-secondary);
}
.input-group input {
  border: none;
  outline: none;
  width: 100%;
  font-size: 1rem;
  padding: 0.6rem 0.2rem;
}
.submit-btn {
  padding: 0.9rem;
  background: var(--primary-color);
  color: #fff;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1rem;
}
.submit-btn[disabled] {
  opacity: 0.6;
  cursor: not-allowed;
}
.extra {
  display: flex;
  gap: 0.5rem;
  justify-content: center;
  margin-top: 0.5rem;
  color: var(--text-secondary);
}
.extra a {
  color: var(--accent-color);
  text-decoration: none;
}
@media (max-width: 1024px) {
  .auth-inner {
    grid-template-columns: 1fr;
  }
  .auth-hero {
    display: none;
  }
}
@media (max-width: 768px) {
  .auth-section {
    padding: 6rem 1.5rem 2rem;
  }
}
.page-container {
  padding: 4rem 2rem;
  max-width: 1280px;
  margin: 0 auto;
}
.auth-card.simple {
  max-width: 420px;
  margin: 0 auto;
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  padding: 2.5rem;
}
.page-title {
  font-size: 2rem;
  margin: 0 0 0.5rem 0;
}
.page-subtitle {
  color: var(--text-secondary);
  margin-bottom: 2rem;
}
.switch {
  text-align: center;
  color: var(--text-secondary);
  margin-top: 0.5rem;
}
.switch a {
  color: var(--primary-color);
  text-decoration: none;
}
.captcha-group {
  padding-right: 0.5rem;
}
.captcha-group input {
  width: auto;
  flex: 1;
  padding: 0.6rem 0.2rem;
  border: none;
}
.captcha-img {
  height: 38px;
  cursor: pointer;
  border-radius: 4px;
}
/* Unified input styles matching Login.vue */
.auth-card.simple .input-group input {
  padding: 0.6rem 0.2rem;
  border: none;
  width: 100%;
  box-sizing: border-box;
  font-size: 1rem;
  outline: none;
}
.captcha-row {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}
.captcha-row input {
  flex: 1;
  width: auto;
}
</style>
