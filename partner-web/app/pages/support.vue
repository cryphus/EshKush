<script setup lang="ts">
interface Ticket {
  id: number
  topic: string
  message: string
  status: string
  response: string | null
  order_id: number | null
  created_at: string
}
definePageMeta({ title: 'Обращения' })
const { request } = useApi()
const tickets = ref<Ticket[]>([])
const loading = ref(true)
const error = ref('')
const busy = ref<number | null>(null)
const responses = ref<Record<number, string>>({})
const onlyOpen = ref(false)
const visible = computed(() =>
  tickets.value.filter(t => !onlyOpen.value || t.status === 'open')
)
let poll: ReturnType<typeof setInterval> | undefined
async function refresh() {
  try {
    tickets.value = await request<Ticket[]>('/demo/support')
    error.value = ''
  } catch (e) {
    error.value = getErrorMessage(e, 'Обращения недоступны')
  } finally {
    loading.value = false
  }
}
onMounted(() => {
  void refresh()
  poll = setInterval(refresh, 8000)
})
onBeforeUnmount(() => clearInterval(poll))
async function reply(ticket: Ticket) {
  busy.value = ticket.id
  try {
    await request(`/demo/support/${ticket.id}/reply`, {
      method: 'POST',
      body: { response: responses.value[ticket.id]?.trim() }
    })
    responses.value[ticket.id] = ''
    await refresh()
  } catch (e) {
    error.value = getErrorMessage(e, 'Ответ не отправлен')
  } finally {
    busy.value = null
  }
}
</script>

<template>
  <div class="p-6 space-y-5">
    <div class="flex items-center justify-between gap-3">
      <div>
        <h1 class="text-xl font-semibold">
          Помогаем гостям
        </h1>
        <p class="text-sm text-muted mt-2">
          Ответы появятся в чате покупателя.
        </p>
      </div>
      <USwitch
        v-model="onlyOpen"
        label="Только в работе"
      />
    </div>
    <UAlert
      v-if="error"
      color="error"
      :title="error"
    />
    <div
      v-if="loading"
      class="text-muted"
    >
      Загружаем обращения…
    </div>
    <UCard v-else-if="!visible.length">
      <div class="py-8 text-center text-muted">
        <UIcon
          name="i-lucide-messages-square"
          class="size-10 mb-3"
        />
        <p>Все вопросы решены</p>
        <p class="text-sm mt-2">
          Новые обращения по вашим заказам появятся здесь.
        </p>
      </div>
    </UCard>
    <UCard
      v-for="ticket in visible"
      :key="ticket.id"
    >
      <template #header>
        <div class="flex justify-between gap-3">
          <div>
            <span class="text-xs text-muted">ЕК-{{ String(ticket.id).padStart(5, "0") }} · заказ №{{
              ticket.order_id
            }}</span>
            <h2 class="font-medium mt-1">
              {{ ticket.topic }}
            </h2>
          </div>
          <UBadge
            :color="ticket.status === 'answered' ? 'success' : 'warning'"
            variant="soft"
          >
            {{ ticket.status === "answered" ? "Ответ отправлен" : "В работе" }}
          </UBadge>
        </div>
      </template>
      <p class="text-sm whitespace-pre-line">
        {{ ticket.message }}
      </p>
      <div
        v-if="ticket.response"
        class="mt-4 rounded-lg bg-elevated p-4"
      >
        <p class="text-xs text-muted mb-2">
          Ваш ответ
        </p>
        <p class="text-sm whitespace-pre-line">
          {{ ticket.response }}
        </p>
      </div>
      <form
        v-else
        class="mt-4 space-y-3"
        @submit.prevent="reply(ticket)"
      >
        <UTextarea
          v-model="responses[ticket.id]"
          placeholder="Ответьте гостю — сообщение появится у него в приложении"
          :rows="3"
          class="w-full"
          :maxlength="2000"
        /><UButton
          type="submit"
          icon="i-lucide-send"
          :loading="busy === ticket.id"
          :disabled="!!busy || (responses[ticket.id]?.trim().length || 0) < 5"
        >
          Отправить ответ
        </UButton>
      </form>
    </UCard>
  </div>
</template>
