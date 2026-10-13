export default defineNuxtRouteMiddleware((to) => {
  // На сервере эта панель не рендерится (ssr: false), но защититься не мешает.
  if (import.meta.server) return

  const auth = useAuthStore()
  auth.hydrate()
  if (to.path === '/shop' || to.path === '/demo' || to.path === '/about') return
  if (to.path === '/' && !auth.isAuthenticated && useRuntimeConfig().public.demoMode) return navigateTo('/demo')

  const isLoginPage = to.path === '/login'

  if (!auth.isAuthenticated) {
    if (!isLoginPage) {
      return navigateTo('/login')
    }
    return
  }

  if (!auth.isPartnerOrAdmin) {
    auth.logout()
    if (!isLoginPage) {
      return navigateTo('/login?error=forbidden')
    }
    return
  }

  if (isLoginPage) {
    return navigateTo('/')
  }
})
