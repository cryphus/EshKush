<script setup lang="ts">
const props = withDefaults(defineProps<{ role?: 'user' | 'partner' }>(), {
  role: 'user'
})
const emit = defineEmits<{ success: [] }>()
const auth = useAuthStore()
const config = useRuntimeConfig()
const phase = ref<'choose' | 'phone' | 'code' | 'provider'>('choose')
const provider = ref('')
const phone = ref('')
const code = ref('')
const challengeId = ref('')
const preview = ref('')
const error = ref('')
const busy = ref(false)
const consent = ref(true)
const expiresAt = ref(0)
const retryAt = ref(0)
const clock = ref(Date.now())
let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  timer = setInterval(() => {
    clock.value = Date.now()
  }, 1000)
})
onBeforeUnmount(() => clearInterval(timer))
const remaining = computed(() =>
  Math.max(0, Math.ceil((expiresAt.value - clock.value) / 1000))
)
const retryIn = computed(() =>
  Math.max(0, Math.ceil((retryAt.value - clock.value) / 1000))
)
async function sendCode() {
  if (busy.value) return
  busy.value = true
  error.value = ''
  try {
    const result = await $fetch<{
      challenge_id: string
      code_preview: string
      phone: string
      expires_at: string
      retry_after: number
    }>('/demo/auth/challenge', {
      baseURL: config.public.apiBase,
      method: 'POST',
      body: { phone: phone.value, role: props.role }
    })
    phone.value = result.phone
    challengeId.value = result.challenge_id
    preview.value = result.code_preview
    expiresAt.value = Date.parse(result.expires_at)
    retryAt.value = Date.now() + result.retry_after * 1000
    clock.value = Date.now()
    code.value = ''
    phase.value = 'code'
  } catch (e) {
    error.value = getErrorMessage(e, 'Не удалось получить код')
  } finally {
    busy.value = false
  }
}
async function confirmCode() {
  if (busy.value) return
  error.value = ''
  busy.value = true
  try {
    await auth.verifyCode(challengeId.value, code.value)
    emit('success')
  } catch (e) {
    error.value = getErrorMessage(e, 'Код не подошёл')
  } finally {
    busy.value = false
  }
}
async function confirmProvider() {
  if (busy.value || !consent.value) return
  busy.value = true
  error.value = ''
  try {
    await auth.demoLogin(props.role)
    emit('success')
  } catch (e) {
    error.value = getErrorMessage(e, 'Не удалось войти')
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="local-signin">
    <p
      v-if="error"
      class="flow-error"
      role="alert"
    >
      {{ error }}
    </p>
    <template v-if="phase === 'choose'">
      <p class="flow-description">
        {{ props.role === 'partner' ? 'Управляйте предложениями, отвечайте гостям и выдавайте заказы.' : 'Сохраняйте любимые места и следите за заказами.' }} Выберите удобный способ входа.
      </p>
      <button
        class="flow-primary"
        @click="phase = 'phone'"
      >
        <UIcon name="i-lucide-smartphone" />По номеру телефона
        <UIcon name="i-lucide-arrow-right" />
      </button>
      <div class="flow-divider">
        <span />или<span />
      </div>
      <button
        v-for="name in ['Яндекс', 'ВКонтакте', 'Telegram']"
        :key="name"
        class="flow-provider"
        @click="
          provider = name;
          phase = 'provider';
          error = '';
        "
      >
        <span class="provider-letter">{{ name[0] }}</span>Продолжить с {{ name }}<UIcon name="i-lucide-arrow-right" />
      </button>
    </template>
    <form
      v-else-if="phase === 'phone'"
      @submit.prevent="sendCode"
    >
      <button
        type="button"
        class="flow-back"
        @click="
          phase = 'choose';
          error = '';
        "
      >
        ← Другой способ
      </button>
      <h3>Ваш номер телефона</h3>
      <p class="flow-description">
        Код подтверждения действует три минуты.
      </p>
      <label class="flow-label">Номер телефона<input
        v-model="phone"
        type="tel"
        autocomplete="tel"
        placeholder="+7 999 123-45-67"
        required
        :disabled="busy"
      ></label>
      <button
        class="flow-primary"
        :disabled="busy"
      >
        {{ busy ? "Отправляем код…" : "Получить код"
        }}<UIcon name="i-lucide-arrow-right" />
      </button>
    </form>
    <form
      v-else-if="phase === 'code'"
      @submit.prevent="confirmCode"
    >
      <button
        type="button"
        class="flow-back"
        @click="
          phase = 'phone';
          error = '';
        "
      >
        ← Изменить номер
      </button>
      <h3>Введите код</h3>
      <p class="flow-description">
        Для номера {{ phone }}. Осталось {{ Math.floor(remaining / 60) }}:{{
          String(remaining % 60).padStart(2, "0")
        }}.
      </p>
      <div
        class="sms-preview"
        role="status"
      >
        <UIcon name="i-lucide-message-square" />
        <div>
          <span>Сообщения · ЕшьКуш</span>
          <p>
            Код входа: <strong>{{ preview }}</strong>
          </p>
        </div>
      </div>
      <label class="flow-label">Код подтверждения<input
        v-model="code"
        class="otp-input"
        inputmode="numeric"
        autocomplete="one-time-code"
        pattern="[0-9]{6}"
        maxlength="6"
        placeholder="000000"
        required
        :disabled="busy"
      ></label>
      <button
        class="flow-primary"
        :disabled="busy || code.length !== 6 || !remaining"
      >
        {{ busy ? "Проверяем…" : "Подтвердить вход"
        }}<UIcon name="i-lucide-check" />
      </button>
      <button
        type="button"
        class="flow-back"
        :disabled="busy || retryIn > 0"
        @click="sendCode"
      >
        {{ retryIn ? `Новый код через ${retryIn} с` : "Получить новый код" }}
      </button>
    </form>
    <template v-else>
      <button
        class="flow-back"
        @click="
          phase = 'choose';
          error = '';
        "
      >
        ← Другой способ
      </button>
      <span class="identity-badge">{{ provider[0] }}</span>
      <h3>Вход через {{ provider }}</h3>
      <div class="identity-card">
        <span>А</span>
        <div>
          <strong>Александр</strong><small>Профиль ЕшьКуш ·
            {{ props.role === "partner" ? "партнёр" : "покупатель" }}</small>
        </div>
      </div>
      <label class="consent-line"><input
        v-model="consent"
        type="checkbox"
      >Разрешить ЕшьКуш
        использовать имя и аватар профиля</label>
      <button
        class="flow-primary"
        :disabled="busy || !consent"
        @click="confirmProvider"
      >
        {{ busy ? "Входим…" : "Продолжить как Александр"
        }}<UIcon name="i-lucide-arrow-right" />
      </button>
    </template>
  </div>
</template>
