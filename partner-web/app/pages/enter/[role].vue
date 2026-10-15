<script setup lang="ts">
import type { UserRole } from '~/types/api'

definePageMeta({ layout: false })
useHead({ title: 'ЕшьКуш — открываем профиль' })
const route = useRoute()
const config = useRuntimeConfig()
const auth = useAuthStore()
const error = ref('')
const busy = ref(false)
const destinations: Record<UserRole, string> = {
  user: '/shop', guest: '/shop', partner: '/', support: '/support', admin: '/'
}
async function enter() {
  if (busy.value) return
  error.value = ''
  const role = String(route.params.role)
  if (!config.public.demoMode || !Object.hasOwn(destinations, role)) {
    error.value = 'Эта ссылка недоступна.'
    return
  }
  busy.value = true
  try {
    await auth.demoLogin(role as UserRole)
    await navigateTo(destinations[role as UserRole], { replace: true })
  } catch (e) {
    error.value = getErrorMessage(e, 'Не удалось открыть профиль. Попробуйте ещё раз.')
  } finally {
    busy.value = false
  }
}
onMounted(enter)
</script>

<template>
  <main class="min-h-screen grid place-items-center bg-elevated p-6">
    <div class="max-w-sm text-center space-y-6">
      <BrandLogo />
      <p
        v-if="!error"
        role="status"
      >
        Открываем ваш профиль…
      </p>
      <template v-else>
        <p role="alert">
          {{ error }}
        </p>
        <UButton
          :loading="busy"
          @click="enter"
        >
          Попробовать снова
        </UButton>
        <NuxtLink
          to="/shop"
          class="block"
        >К предложениям</NuxtLink>
      </template>
    </div>
  </main>
</template>
