import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
    // If we experience CORS issues, we might need this, but for now assuming direct access or allow-origin *
    }
  }
})
