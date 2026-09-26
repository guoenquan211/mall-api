import { createVNode, render } from 'vue'
import ToastComponent from './Toast.vue'

const showToast = (message, type = 'info', duration = 3000) => {
  const container = document.createElement('div')
  document.body.appendChild(container)

  const onClose = () => {
    render(null, container)
    document.body.removeChild(container)
  }

  const vnode = createVNode(ToastComponent, {
    message,
    type,
    duration,
    onClose
  })

  render(vnode, container)
}

export const toast = {
  success: (msg) => showToast(msg, 'success'),
  error: (msg) => showToast(msg, 'error'),
  warning: (msg) => showToast(msg, 'warning'),
  info: (msg) => showToast(msg, 'info')
}

export default toast
