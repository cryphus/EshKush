<script setup lang="ts">
definePageMeta({ layout: false
})

const route = useRoute()
const auth = useAuthStore()

const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref<string | null>(null)
const config = useRuntimeConfig()
const demoEnabled = ref(false)
onMounted(async () => {
  try {
    await $fetch('/demo/status', {
      baseURL: config.public.apiBase
    })
    demoEnabled.value = true
  } catch {
    /* regular login */
  }
})
async function openDemo() {
  loading.value = true
  try {
    await auth.demoLogin('partner')
    await navigateTo('/')
  } catch (e) {
    error.value = getErrorMessage(e, 'Не удалось открыть кабинет')
  } finally {
    loading.value = false
  }
}

if (route.query.error === 'forbidden') {
  error.value = 'Доступ разрешён только партнёрам и администраторам.'
}

async function onSubmit() {
  if (!username.value.trim() || !password.value) return
  loading.value = true
  error.value = null
  try {
    await auth.login(username.value.trim(), password.value)
    await navigateTo('/')
  } catch (e) {
    error.value = getErrorMessage(e, 'Не удалось войти')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-elevated px-4">
    <UCard class="w-full max-w-sm">
      <template #header>
        <div class="flex flex-col items-center gap-2 py-2">
          <BrandLogo />
          <p class="text-sm text-muted">
            Панель управления для партнёров
          </p>
        </div>
      </template>

      <form
        class="flex flex-col gap-4"
        @submit.prevent="onSubmit"
      >
        <UFormField label="Логин или телефон">
          <UInput
            v-model="username"
            placeholder="partner1"
            autocomplete="username"
            class="w-full"
            :disabled="loading"
          />
        </UFormField>

        <UFormField label="Пароль">
          <UInput
            v-model="password"
            type="password"
            placeholder="••••••••"
            autocomplete="current-password"
            class="w-full"
            :disabled="loading"
          />
        </UFormField>

        <UAlert
          v-if="error"
          color="error"
          variant="soft"
          :title="error"
        />

        <UButton
          type="submit"
          block
          :loading="loading"
          :disabled="!username.trim() || !password"
        >
          Войти
        </UButton>
      </form>
      <div
        v-if="demoEnabled"
        class="mt-5 border-t border-default pt-5 flex flex-col gap-3"
      >
        <UButton
          block
          variant="soft"
          :loading="loading"
          @click="openDemo"
        >
          Открыть кабинет
        </UButton>
        <NuxtLink
          to="/shop"
          class="text-center text-sm text-primary"
        >Приложение покупателя →</NuxtLink>
      </div>
    </UCard>
  </div>
</template>
