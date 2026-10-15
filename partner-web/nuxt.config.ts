import { readdirSync, readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { resolve } from 'node:path'

// Bundle every app icon locally, including names in lazy components and lists.
const appDirectory = fileURLToPath(new URL('./app', import.meta.url))
const localIcons = [...new Set(readdirSync(appDirectory, { recursive: true })
  .filter(file => /\.(vue|ts)$/.test(String(file)))
  .flatMap(file => [...readFileSync(resolve(appDirectory, String(file)), 'utf8')
    .matchAll(/i-(lucide|simple-icons)-([a-z0-9-]+)/g)]
    .map(match => `${match[1]}:${match[2]}`)))]

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui',
    '@pinia/nuxt'
  ],

  // Панель партнёра — авторизованное SPA, серверный рендеринг не нужен
  // (и не подходит: страницы зависят от JWT в localStorage).
  ssr: false,

  devtools: {
    enabled: true
  },

  css: ['~/assets/css/main.css', '~/assets/css/flows.css'],
  ui: { fonts: false },

  runtimeConfig: {
    public: {
      demoMode: process.env.NUXT_PUBLIC_DEMO_MODE === 'true',
      // URL основного Dart-бэкенда EshKush.
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:3000'
    }
  },

  devServer: {
    port: 3010
  },

  compatibilityDate: '2026-06-30',
  nitro: { prerender: { routes: ['/demo', '/shop', '/login', '/about'] } },

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  },
  icon: { clientBundle: { icons: localIcons, sizeLimitKb: 128 } }
})
