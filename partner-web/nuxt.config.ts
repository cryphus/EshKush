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

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    public: {
      // URL основного Dart-бэкенда EshKush.
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:3000'
    }
  },

  devServer: {
    port: 3010
  },

  compatibilityDate: '2026-06-30',

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})
