<script setup lang="ts">
import type { Order, Point } from '~/types/api'

interface Ticket {
  id: number
  topic: string
  message: string
  status: string
  response: string | null
  order_id: number | null
}
interface Message {
  text: string
  own: boolean
  time: string
}
const props = defineProps<{ orders: Order[], points: Point[] }>()
const emit = defineEmits<{ orders: [] }>()
const auth = useAuthStore()
const { request } = useApi()
const input = ref('')
const composing = ref(false)
const showTicket = ref(false)
const topic = ref('Проблема с заказом')
const orderId = ref<number | null>(
  props.orders.find(o => o.status === 'pending' || o.status === 'processing')
    ?.id
    ?? props.orders[0]?.id
    ?? null
)
const description = ref('')
const error = ref('')
const busy = ref(false)
const tickets = ref<Ticket[]>([])
const chatEnd = ref<HTMLElement>()
const messages = ref<Message[]>([])
const seen = new Set<number>()
const storageKey = `eshkush_support_${auth.user?.id}`
let poll: ReturnType<typeof setInterval> | undefined
let replyTimer: ReturnType<typeof setTimeout> | undefined
function add(text: string, own = false) {
  messages.value.push({
    text,
    own,
    time: new Date().toLocaleTimeString('ru-RU', {
      hour: '2-digit',
      minute: '2-digit'
    })
  })
  messages.value = messages.value.slice(-80)
  localStorage.setItem(
    storageKey,
    JSON.stringify({ messages: messages.value, seen: [...seen] })
  )
  void nextTick(() =>
    chatEnd.value?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  )
}
async function loadTickets() {
  try {
    tickets.value = await request<Ticket[]>('/demo/support')
    for (const ticket of tickets.value) {
      if (ticket.response && !seen.has(ticket.id)) {
        seen.add(ticket.id)
        add(
          `Ответ по обращению ЕК-${String(ticket.id).padStart(5, '0')}: ${ticket.response}`
        )
      }
    }
  } catch {
    /* Keep the conversation usable while reconnecting. */
  }
}
onMounted(async () => {
  try {
    const saved = JSON.parse(localStorage.getItem(storageKey) || 'null')
    if (Array.isArray(saved?.messages))
      messages.value = saved.messages.slice(-80)
    for (const id of saved?.seen || []) seen.add(Number(id))
  } catch {
    /* Start a new conversation if browser storage was cleared. */
  }
  if (!messages.value.length)
    add(
      'Здравствуйте! Я помощник ЕшьКуш. Найду код получения, помогу с возвратом или передам вопрос заведению.'
    )
  await loadTickets()
  poll = setInterval(loadTickets, 5000)
})
onBeforeUnmount(() => {
  clearInterval(poll)
  clearTimeout(replyTimer)
})
function send(text = input.value) {
  text = text.trim()
  if (!text || composing.value) return
  add(text, true)
  input.value = ''
  composing.value = true
  replyTimer = setTimeout(() => {
    const order
      = props.orders.find(
        o => o.status === 'pending' || o.status === 'processing'
      ) ?? props.orders[0]
    const place = props.points.find(p => p.id === order?.point_id)
    let reply: string
    if (/возврат|отмен/i.test(text)) {
      reply
        = order && ['pending', 'processing'].includes(order.status)
          ? `Заказ №${order.id} в «${place?.name}» можно отменить в «Моих заказах». Нажмите «Отменить и вернуть» — статус и остаток обновятся сразу.`
          : 'Откройте «Мои заказы» и выберите заказ. Если бокс уже получен, создайте обращение — заведение рассмотрит ваш вопрос.'
    } else if (/заказ|код|забрат|выдач/i.test(text)) {
      reply = order
        ? `Ваш заказ №${order.id}: ${order.status === 'processing' ? 'готов к выдаче' : order.status === 'cancelled' ? 'отменён' : order.status === 'completed' ? 'получен' : 'оплачен'}. ${['pending', 'processing'].includes(order.status) ? `Код получения ЕК-${String(order.id).padStart(5, '0')}. Адрес: ${place?.address}. Заведение открыто до ${place?.closing_hours}.` : 'Подробности сохранены в истории.'}`
        : 'У вас пока нет заказов. Выберите бокс в каталоге, оформите его и получите код выдачи.'
    } else if (/состав|аллерг|бокс|свеж/i.test(text)) {
      reply
        = 'В карточке бокса указаны состав набора, вес и время выдачи. Сюрприз-боксы собирают из сегодняшней витрины; точный состав уточняйте в заведении. Если есть аллергия, обязательно сообщите сотруднику до получения.'
    } else if (/оплат|сбп|карт/i.test(text)) {
      reply
        = 'При оформлении выберите карту или СБП, проверьте сумму и подтвердите платёж. Если окно закрылось, корзина сохранится: повторное подтверждение продолжит оплату созданных заказов.'
    } else {
      reply
        = 'Могу найти код получения, объяснить возврат или рассказать о боксе. Если нужен ответ сотрудника заведения, нажмите «Создать обращение» и выберите заказ.'
    }
    add(reply)
    composing.value = false
  }, 700)
}
async function createTicket() {
  if (busy.value) return
  busy.value = true
  error.value = ''
  try {
    const ticket = await request<Ticket>('/demo/support', {
      method: 'POST',
      body: {
        topic: topic.value,
        message: description.value.trim(),
        order_id: orderId.value
      }
    })
    add(
      `Обращение ЕК-${String(ticket.id).padStart(5, '0')} создано${ticket.order_id ? ` по заказу №${ticket.order_id}` : ''}. ${ticket.order_id ? 'Вопрос передан заведению.' : 'Вопрос передан команде ЕшьКуш.'} Ответ появится в этом чате.`
    )
    showTicket.value = false
    description.value = ''
    await loadTickets()
  } catch (e) {
    error.value = getErrorMessage(e, 'Не удалось создать обращение')
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="support-chat">
    <p class="assistant-subtitle">
      <span />Помощник ЕшьКуш · на связи
    </p>
    <div class="support-quick">
      <button
        v-for="text in ['Где мой заказ?', 'Как вернуть?', 'Что внутри бокса?']"
        :key="text"
        :disabled="composing"
        @click="send(text)"
      >
        {{ text }}
      </button>
    </div>
    <div
      class="support-conversation"
      aria-live="polite"
    >
      <div
        v-for="(m, i) in messages"
        :key="i"
        class="chat-message"
        :class="{ own: m.own }"
      >
        {{ m.text }}<small>{{ m.time }}</small>
      </div>
      <div
        v-if="composing"
        class="support-typing"
      >
        Помощник печатает<span>…</span>
      </div>
      <span ref="chatEnd" />
    </div>
    <form
      class="chat-form"
      @submit.prevent="send()"
    >
      <input
        v-model="input"
        aria-label="Сообщение помощнику"
        placeholder="Напишите ваш вопрос"
        maxlength="2000"
      ><button
        :disabled="composing || !input.trim()"
        aria-label="Отправить"
      >
        <UIcon name="i-lucide-arrow-up" />
      </button>
    </form>
    <div class="support-actions">
      <button @click="emit('orders')">
        Мои заказы <UIcon name="i-lucide-arrow-up-right" />
      </button><button @click="showTicket = !showTicket">
        {{ showTicket ? "Закрыть форму" : "Создать обращение"
        }}<UIcon name="i-lucide-message-square-plus" />
      </button>
    </div>
    <form
      v-if="showTicket"
      class="support-ticket-form"
      @submit.prevent="createTicket"
    >
      <h3>Напишите нам</h3>
      <p
        v-if="error"
        class="flow-error"
        role="alert"
      >
        {{ error }}
      </p>
      <label class="flow-label">Тема<select v-model="topic">
        <option>Проблема с заказом</option>
        <option>Вопрос об оплате</option>
        <option>Качество бокса</option>
        <option>Другой вопрос</option>
      </select></label>
      <label class="flow-label">Заказ<select v-model="orderId">
        <option :value="null">Общий вопрос</option>
        <option
          v-for="o in props.orders"
          :key="o.id"
          :value="o.id"
        >
          №{{ o.id }} ·
          {{ props.points.find((p) => p.id === o.point_id)?.name }}
        </option>
      </select></label>
      <label class="flow-label">Что произошло?<textarea
        v-model="description"
        minlength="5"
        maxlength="2000"
        rows="3"
        required
        placeholder="Расскажите подробнее — так мы быстрее поможем"
      />
      </label>
      <button
        class="flow-primary"
        :disabled="busy || description.trim().length < 5"
      >
        {{ busy ? "Отправляем…" : "Отправить обращение"
        }}<UIcon name="i-lucide-send" />
      </button>
    </form>
    <div
      v-if="tickets.length"
      class="support-ticket-list"
    >
      <h3>Ваши обращения</h3>
      <article
        v-for="t in tickets"
        :key="t.id"
      >
        <span>ЕК-{{ String(t.id).padStart(5, "0") }}</span><strong>{{ t.topic }}</strong><small>{{
          t.status === "answered" ? "Ответ получен" : "В работе"
        }}</small>
      </article>
    </div>
  </div>
</template>

<style>
.support-quick {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin: 14px 0;
}
.support-quick button {
  background: #edf3e5;
  border: 1px solid #dbe6ce;
  border-radius: 10px;
  padding: 8px;
  font:
    9px Stolzl,
    sans-serif;
  color: #6d8b5c;
}
.support-conversation {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-height: 360px;
  overflow: auto;
  padding: 10px 0 18px;
}
.support-conversation .chat-message {
  white-space: pre-line;
  line-height: 1.8;
}
.chat-message small {
  display: block;
  text-align: right;
  font-size: 8px;
  opacity: 0.5;
  margin-top: 7px;
}
.support-typing {
  font-size: 10px;
  color: #90a47f;
  padding: 12px;
}
.support-typing span {
  animation: pulse 1s infinite;
}
.support-actions {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  margin: 15px 0;
}
.support-actions button {
  display: flex;
  gap: 5px;
  align-items: center;
  border: 0;
  background: none;
  color: #6d8b5c;
  font:
    10px Stolzl,
    sans-serif;
}
.support-ticket-form {
  padding: 20px;
  background: #f1f4e9;
  border-radius: 17px;
  margin-top: 20px;
}
.support-ticket-form h3,
.support-ticket-list h3 {
  font-size: 14px;
  font-weight: 500;
}
.flow-label select,
.flow-label textarea {
  min-width: 0;
  width: 100%;
  border: 1px solid #d9e1ce;
  border-radius: 11px;
  background: #fffdf8;
  color: #34472e;
  font:
    11px Stolzl,
    sans-serif;
  padding: 12px;
  resize: vertical;
}
.support-ticket-list {
  margin-top: 25px;
}
.support-ticket-list article {
  display: grid;
  gap: 6px;
  padding: 14px 0;
  border-bottom: 1px solid #e2e7d8;
}
.support-ticket-list article span {
  font-size: 9px;
  color: #95a484;
}
.support-ticket-list strong {
  font-size: 11px;
  font-weight: 400;
}
.support-ticket-list small {
  font-size: 9px;
  color: #6d9c65;
}
</style>
