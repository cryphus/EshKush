<script setup lang="ts">
definePageMeta({ layout: false
})
useHead({ title: 'Режим показа'
})
useColorMode().preference = 'light'
interface Service {
  id: string
  name: string
  status: string
  kind: string
}
const config = useRuntimeConfig()
const auth = useAuthStore()
const {
  request
} = useApi()
const services = ref<Service[]>([])
const products = ref(0)
const orders = ref(0)
const busy = ref(false)
const error = ref('')
const message = ref('')
const resetArmed = ref(false)
const roles = [
  {
    id: 'user' as const, name: 'Покупатель', icon: 'i-lucide-shopping-bag', description: 'Каталог, избранное, карта, корзина, оплата и история заказов.', label: 'Открыть приложение', path: '/shop'
  },
  {
    id: 'partner' as const, name: 'Партнёр', icon: 'i-lucide-store', description: 'Предложения, остатки, входящие заказы и аналитика продаж.', label: 'Открыть кабинет', path: '/'
  },
  {
    id: 'admin' as const, name: 'Администратор', icon: 'i-lucide-layout-dashboard', description: 'Общий обзор данных, управление каталогом и контроль заказов.', label: 'Управлять сервисом', path: '/'
  }
]
async function status() {
  const res = await $fetch<{ services: Service[]
    products: number
    orders: number
  }>('/demo/status', {
    baseURL: config.public.apiBase
  })
  services.value = res.services
  products.value = res.products
  orders.value = res.orders
}
onMounted(async () => {
  try {
    await status()
  } catch {
    error.value = 'Демо-сервис недоступен. Запустите docker compose -f compose.demo.yml up --build -d'
  }
})
async function open(role: 'user' | 'partner' | 'admin', path: string) {
  busy.value = true
  error.value = ''
  try {
    await auth.demoLogin(role)
    await navigateTo(path)
  } catch (e) {
    error.value = getErrorMessage(e, 'Не удалось открыть профиль')
  } finally {
    busy.value = false
  }
}
async function reset() {
  if (!resetArmed.value) {
    resetArmed.value = true
    return
  }
  busy.value = true
  message.value = ''
  try {
    await auth.demoLogin('admin')
    await request('/demo/reset', {
      method: 'POST'
    })
    localStorage.removeItem('eshkush_demo_cart')
    localStorage.removeItem('eshkush_demo_checkout')
    await status()
    message.value = 'Исходные данные восстановлены. Можно начинать показ заново.'
  } catch (e) {
    error.value = getErrorMessage(e, 'Сброс не выполнен')
  } finally {
    busy.value = false
    resetArmed.value = false
  }
}
</script>

<template>
  <div class="shop-shell">
    <main class="demo-hub">
      <NuxtLink
        class="brand"
        to="/shop"
      ><span class="brand-mark">е</span><span>ешькуш.</span></NuxtLink>
      <section class="hub-title">
        <span class="eyebrow"><span /> ГОТОВО К ДЕМОНСТРАЦИИ</span><h1>Один продукт.<br>Три стороны истории.</h1><p>Выберите роль и пройдите путь от свежего бокса до довольного гостя. Все внешние интеграции здесь имитируются локально.</p>
      </section>
      <p
        v-if="error"
        class="error-banner"
        role="alert"
      >
        {{ error }}
      </p><p
        v-if="message"
        class="detail-note"
        role="status"
      >
        {{ message }}
      </p>
      <div class="hub-roles">
        <article
          v-for="role in roles"
          :key="role.id"
          class="hub-role"
        >
          <UIcon :name="role.icon" /><h2>{{ role.name }}</h2><p>{{ role.description }}</p><button
            class="primary-btn full"
            :disabled="busy || !services.length"
            @click="open(role.id, role.path)"
          >
            {{ role.label }} <UIcon name="i-lucide-arrow-right" />
          </button>
        </article>
      </div>
      <div class="section-heading">
        <div><span class="eyebrow muted">АВТОНОМНАЯ ДЕМОНСТРАЦИЯ</span><h2>Всё на своих местах</h2></div><span class="offer-count">{{ products }} боксов · {{ orders }} заказов</span>
      </div>
      <div class="hub-services">
        <article
          v-for="s in services"
          :key="s.id"
          class="hub-service"
        >
          <UIcon name="i-lucide-circle-check" /><div><h3>{{ s.name }}</h3><p>{{ s.kind === 'local' ? 'Локальные данные' : 'Демо-имитация' }} · готово</p></div><span class="ready-dot" />
        </article>
      </div>
      <section class="hub-scenario">
        <h2>Хороший сценарий для показа</h2><ol><li>Откройте приложение покупателя и выберите два бокса.</li><li>Добавьте их в корзину, выберите карту или СБП и подтвердите демо-оплату.</li><li>Посмотрите коды получения в «Моих заказах».</li><li>Откройте кабинет партнёра: новые заказы уже появились в списке.</li><li>Переведите заказ в «Готов» и «Выполнен», затем обновите приложение покупателя.</li><li>Покажите возврат, отзывы, избранное и аналитику продаж.</li></ol>
      </section>
      <section class="hub-reset">
        <div><h3>Начать новую демонстрацию</h3><p>Сброс удалит изменения каталога и заказов из этой демонстрации<br>и восстановит исходный набор примеров.</p></div><div>
          <button
            class="secondary-btn"
            :disabled="busy || !services.length"
            @click="reset"
          >
            {{ busy ? 'Восстанавливаем…' : resetArmed ? 'Подтвердить сброс данных' : 'Восстановить демо-данные' }} <UIcon name="i-lucide-rotate-ccw" />
          </button><button
            v-if="resetArmed && !busy"
            class="text-btn"
            @click="resetArmed = false"
          >
            Отмена
          </button>
        </div>
      </section>
      <footer class="shop-footer">
        <span>ЕшьКуш · версия 1.0</span><span>Показ без внешних ключей и реальных списаний</span><NuxtLink to="/shop">Перейти к боксу →</NuxtLink>
      </footer>
    </main>
  </div>
</template>

<style scoped>
@import '~/assets/css/showcase.css';
</style>
