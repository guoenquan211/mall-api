<template>
  <transition name="toast-fade" @after-leave="onAfterLeave">
    <div v-if="visible" class="toast-container" :class="type">
      <i :class="iconClass"></i>
      <span class="message">{{ message }}</span>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const props = defineProps({
  message: String,
  type: {
    type: String,
    default: 'info' // success, error, warning, info
  },
  duration: {
    type: Number,
    default: 3000
  },
  onClose: Function
})

const visible = ref(false)

const iconClass = computed(() => {
  switch (props.type) {
    case 'success': return 'ri-checkbox-circle-line'
    case 'error': return 'ri-error-warning-line'
    case 'warning': return 'ri-alert-line'
    default: return 'ri-information-line'
  }
})

onMounted(() => {
  visible.value = true
  setTimeout(() => {
    visible.value = false
  }, props.duration)
})

const onAfterLeave = () => {
  if (props.onClose) props.onClose()
}
</script>

<style scoped>
.toast-container {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  padding: 12px 24px;
  border-radius: 8px;
  background: white;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  display: flex;
  align-items: center;
  gap: 8px;
  z-index: 9999;
  min-width: 300px;
  max-width: 80%;
  pointer-events: none;
}

.toast-container.success {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  color: #15803d;
}

.toast-container.error {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #b91c1c;
}

.toast-container.warning {
  background: #fffbeb;
  border: 1px solid #fde68a;
  color: #b45309;
}

.toast-container.info {
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  color: #0369a1;
}

.message {
  font-size: 14px;
  font-weight: 500;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.3s ease;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translate(-50%, -20px);
}
</style>
