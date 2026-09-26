<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <div class="logo">
          <i class="ri-store-2-line"></i>
        </div>
        <h1>{{ $t('admin.login.title') }}</h1>
        <p>{{ $t('admin.login.subtitle') }}</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label>{{ $t('admin.login.username') }}</label>
          <div class="input-wrapper">
            <i class="ri-user-line"></i>
            <input 
              type="text" 
              v-model="form.username" 
              :placeholder="$t('admin.login.usernamePh')"
              required
            >
          </div>
        </div>

        <div class="form-group">
          <label>{{ $t('admin.login.password') }}</label>
          <div class="input-wrapper">
            <i class="ri-lock-line"></i>
            <input 
              type="password" 
              v-model="form.password" 
              :placeholder="$t('admin.login.passwordPh')"
              required
            >
          </div>
        </div>

        <button type="submit" class="login-btn" :disabled="loading">
          <span v-if="loading">{{ $t('admin.login.submitting') }}</span>
          <span v-else>{{ $t('admin.login.submit') }}</span>
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { api } from '../api'
import { toast } from '../components/Toast'
import { IMG_ADMIN_LOGIN } from '../assets/stock-images.js'

const loginBgImage = `linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.4)), url("${IMG_ADMIN_LOGIN}")`

const { t } = useI18n()

const router = useRouter()
const loading = ref(false)
const form = reactive({
  username: '',
  password: ''
})

const handleLogin = async () => {
  loading.value = true
  try {
    const res = await api.login(form.username, form.password)
    if (res.code === 0) {
      toast.success(t('admin.login.success'))
      router.push('/')
    } else {
      toast.error(res.msg)
    }
  } catch (e) {
    console.error(e)
    toast.error(t('admin.login.fail'))
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-image: v-bind(loginBgImage);
  background-size: cover;
  background-position: center;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  z-index: 100;
}

.login-card {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  width: 100%;
  max-width: 420px;
  padding: 3rem;
  border-radius: 24px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  border: 1px solid rgba(255, 255, 255, 0.5);
}

.login-header {
  text-align: center;
  margin-bottom: 2.5rem;
}

.logo {
  width: 70px;
  height: 70px;
  background: var(--color-primary);
  color: white;
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2.5rem;
  margin: 0 auto 1.5rem;
  box-shadow: 0 10px 15px -3px rgba(var(--color-primary-rgb, 16, 185, 129), 0.3);
}

.login-header h1 {
  font-size: 1.75rem;
  color: #111827;
  margin-bottom: 0.5rem;
  font-weight: 600;
  font-family: "Songti SC", "SimSun", serif; /* Serif font for elegance */
  letter-spacing: 0.05em;
}

.login-header p {
  color: #6b7280;
  font-size: 0.95rem;
  letter-spacing: 0.02em;
}

.form-group {
  margin-bottom: 1.75rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.75rem;
  color: #374151;
  font-size: 0.95rem;
  font-weight: 500;
}

.input-wrapper {
  position: relative;
}

.input-wrapper i {
  position: absolute;
  left: 1.25rem;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
  font-size: 1.2rem;
  transition: color 0.2s;
}

.input-wrapper input {
  width: 100%;
  box-sizing: border-box; /* Fix overflow issue */
  padding: 1rem 1rem 1rem 3.25rem;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  font-size: 1rem;
  transition: all 0.3s ease;
  background: #f9fafb;
}

.input-wrapper input:focus {
  outline: none;
  border-color: var(--color-primary);
  background: white;
  box-shadow: 0 0 0 4px rgba(var(--color-primary-rgb, 16, 185, 129), 0.15);
}

.input-wrapper:focus-within i {
  color: var(--color-primary);
}

/* Adjust icon selector since it's before input in HTML */
.input-wrapper i {
  z-index: 1; 
  pointer-events: none;
}

.login-btn {
  width: 100%;
  padding: 1rem;
  background: var(--color-primary);
  background-image: linear-gradient(135deg, var(--color-primary) 0%, #059669 100%); /* Gradient button */
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  margin-top: 1.5rem;
  box-shadow: 0 4px 6px -1px rgba(var(--color-primary-rgb, 16, 185, 129), 0.2);
  letter-spacing: 0.05em;
}

.login-btn:hover:not(:disabled) {
  filter: brightness(110%);
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(var(--color-primary-rgb, 16, 185, 129), 0.3);
}

.login-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}
</style>