<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from '../components/Toast'
import { api } from '../api'

const { t } = useI18n()

const form = ref({
  name: '',
  email: '',
  message: '',
})

const submitStatus = ref('')

const handleSubmit = async () => {
  if (!form.value.name?.trim() || !form.value.message?.trim()) {
    toast.warning(t('contact.fillRequired'))
    return
  }

  submitStatus.value = 'submitting'
  try {
    const res = await api.submitContact({
      visitor_name: form.value.name.trim(),
      contact: form.value.email?.trim() || '',
      content: form.value.message.trim(),
    })
    if (res.code === 0) {
      submitStatus.value = 'success'
      toast.success(res.msg || t('contact.successLine'))
      form.value = { name: '', email: '', message: '' }
    } else {
      toast.error(res.msg || t('contact.submitFail'))
      submitStatus.value = ''
    }
  } catch (e) {
    console.error(e)
    toast.error(t('contact.submitFail'))
    submitStatus.value = ''
  } finally {
    if (submitStatus.value === 'submitting') submitStatus.value = ''
  }
}
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">{{ $t('contact.title') }}</h1>
      <div class="header-line"></div>
      <p class="page-subtitle">{{ $t('contact.subtitle') }}</p>
    </div>

    <div class="contact-layout">
      <div class="contact-info">
        <div class="info-card">
          <div class="card-icon-wrapper">
            <i class="ri-map-pin-2-line card-icon"></i>
          </div>
          <div class="card-content">
            <h3>{{ $t('contact.addressTitle') }}</h3>
            <p>{{ $t('contact.addressBody') }}</p>
          </div>
        </div>
        <div class="info-card">
          <div class="card-icon-wrapper">
            <i class="ri-phone-line card-icon"></i>
          </div>
          <div class="card-content">
            <h3>{{ $t('contact.phoneTitle') }}</h3>
            <p>{{ $t('contact.phoneBody') }}</p>
          </div>
        </div>
        <div class="info-card">
          <div class="card-icon-wrapper">
            <i class="ri-mail-line card-icon"></i>
          </div>
          <div class="card-content">
            <h3>{{ $t('contact.emailTitle') }}</h3>
            <p>{{ $t('contact.emailBody') }}</p>
          </div>
        </div>
      </div>

      <div class="message-form-container">
        <div class="form-header">
          <h3>{{ $t('contact.formTitle') }}</h3>
          <p>{{ $t('contact.formHint') }}</p>
        </div>
        <form @submit.prevent="handleSubmit" class="message-form">
          <div class="form-group">
            <input
              v-model="form.name"
              type="text"
              :placeholder="$t('contact.namePh')"
              class="form-input"
            />
          </div>

          <div class="form-group">
            <input
              v-model="form.email"
              type="text"
              :placeholder="$t('contact.contactPh')"
              class="form-input"
            />
          </div>

          <div class="form-group">
            <textarea
              v-model="form.message"
              rows="4"
              :placeholder="$t('contact.messagePh')"
              class="form-textarea"
            ></textarea>
          </div>

          <button type="submit" class="submit-btn" :disabled="submitStatus === 'submitting'">
            {{ submitStatus === 'submitting' ? $t('contact.submitting') : $t('contact.submit') }}
          </button>

          <p v-if="submitStatus === 'success'" class="success-msg">{{ $t('contact.successLine') }}</p>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 6rem 2rem;
  max-width: 1280px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 5rem;
}

.page-title {
  font-family: var(--font-serif);
  font-size: 3rem;
  margin-bottom: 1.5rem;
  color: var(--primary-color);
  letter-spacing: 0.2em;
}

.header-line {
  width: 60px;
  height: 3px;
  background-color: var(--accent-color);
  margin: 0 auto 1.5rem auto;
}

.page-subtitle {
  color: var(--text-secondary);
  font-family: var(--font-display);
  font-size: 1.1rem;
  letter-spacing: 0.3em;
  text-transform: uppercase;
}

.contact-layout {
  display: grid;
  grid-template-columns: 1fr 1.5fr;
  gap: 5rem;
  align-items: flex-start;
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.info-card {
  display: flex;
  align-items: center;
  background: white;
  padding: 2rem;
  border-left: 4px solid var(--accent-color);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
  transition:
    transform 0.3s ease,
    box-shadow 0.3s ease;
}

.info-card:hover {
  transform: translateX(5px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.06);
}

.card-icon-wrapper {
  margin-right: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.card-icon {
  font-size: 2rem;
  color: var(--primary-color);
}

.card-content h3 {
  font-family: var(--font-serif);
  font-size: 1.2rem;
  color: var(--primary-color);
  margin-bottom: 0.3rem;
  letter-spacing: 0.1em;
}

.card-content p {
  font-size: 0.95rem;
  color: var(--text-secondary);
  margin: 0;
}

.message-form-container {
  background: white;
  padding: 3.5rem;
  border: 1px solid var(--border-color);
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.04);
}

.form-header {
  margin-bottom: 2.5rem;
  text-align: center;
}

.form-header h3 {
  font-family: var(--font-serif);
  font-size: 1.8rem;
  color: var(--text-primary);
  margin-bottom: 0.5rem;
}

.form-header p {
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.message-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-input,
.form-textarea {
  width: 100%;
  padding: 1rem 0;
  border: none;
  border-bottom: 1px solid var(--border-color);
  background: transparent;
  font-family: var(--font-sans);
  font-size: 1rem;
  color: var(--text-primary);
  transition: all 0.3s ease;
  box-sizing: border-box;
}

.form-input:focus,
.form-textarea:focus {
  outline: none;
  border-bottom-color: var(--primary-color);
  background: linear-gradient(to bottom, transparent 95%, rgba(62, 78, 56, 0.05) 100%);
}

.form-textarea {
  resize: vertical;
  min-height: 120px;
}

.submit-btn {
  margin-top: 1rem;
  padding: 1.2rem;
  background-color: var(--primary-color);
  color: white;
  border: none;
  font-family: var(--font-serif);
  font-size: 1.1rem;
  letter-spacing: 0.2em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.submit-btn:hover {
  background-color: var(--accent-color);
  transform: translateY(-2px);
}

.submit-btn:disabled {
  background-color: var(--text-secondary);
  cursor: not-allowed;
  transform: none;
}

.success-msg {
  margin-top: 1rem;
  color: var(--primary-color);
  text-align: center;
  font-family: var(--font-serif);
}

@media (max-width: 768px) {
  .page-container {
    padding: 6rem 1.5rem 3rem 1.5rem;
  }

  .contact-layout {
    grid-template-columns: 1fr;
    gap: 3rem;
  }

  .message-form-container {
    padding: 2rem;
  }

  .page-title {
    font-size: 2.2rem;
  }
}
</style>
