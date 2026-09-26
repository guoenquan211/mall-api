import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
// 本地 API：默认 ThinkPHP `php think run`（8000）。可在 frontend/.env.development 设置 API_PROXY_TARGET
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const proxyTarget = env.API_PROXY_TARGET || 'http://127.0.0.1:8000'
  const proxyCommon = {
    target: proxyTarget,
    changeOrigin: true,
    secure: true,
  }
  return {
    plugins: [vue()],
    server: {
      port: 5173,
      proxy: {
        '/api': proxyCommon,
        '/captcha': proxyCommon,
        '/storage': proxyCommon,
        '/uploads': proxyCommon,
      },
    },
  }
})
