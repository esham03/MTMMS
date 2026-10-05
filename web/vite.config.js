import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

const apiPort = process.env.MTMMS_API_PORT || '8000'
const webPort = process.env.MTMMS_WEB_PORT ? parseInt(process.env.MTMMS_WEB_PORT) : 5174

// https://vite.dev/config/
export default defineConfig({
  base: './',
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: webPort,
    cors: true,
    proxy: {
      '/api': {
        target: `http://127.0.0.1:${apiPort}`,
        changeOrigin: true,
        secure: false,
      },
      '/sanctum': {
        target: `http://127.0.0.1:${apiPort}`,
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
