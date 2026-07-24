<script setup lang="ts">
definePageMeta({ layout: false })

const route = useRoute()
const auth = useAuthStore()

const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref<string | null>(null)

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
          <div class="flex size-12 items-center justify-center rounded-xl bg-primary text-inverted text-xl font-bold">
            E
          </div>
          <h1 class="text-lg font-semibold text-highlighted">
            EshKush Partner
          </h1>
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
    </UCard>
  </div>
</template>
