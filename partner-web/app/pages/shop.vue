<script setup lang="ts">
import type {
  Product, Point, Order
} from '~/types/api'

definePageMeta({ layout: false
})
useHead({ title: 'Спасайте вкусную еду'
})
useColorMode().preference = 'light'
interface Offer extends Product {
  quantity: number
  original_price: number | null
  pickup_start: string | null
  pickup_end: string | null
  tags: string[]
  items_count: number
}
interface Place extends Point {
  image_url: string | null
}
interface Snapshot {
  products: Offer[]
  points: Place[]
  orders: Order[]
  favorites: number[]
  cities: {
    id: number
    name: string
  }[]
}
interface Review {
  id: number
  rating: number
  comment: string | null
}
const auth = useAuthStore()
const {
  request
} = useApi()
const config = useRuntimeConfig()
const snapshot = ref<Snapshot>({ products: [], points: [], orders: [], favorites: [], cities: []
})
const loading = ref(true)
const error = ref('')
const view = ref('catalog')
const query = ref('')
const category = ref('Все')
const city = ref(0)
const drawer = ref('')
const detail = ref<Offer | null>(null)
const reviews = ref<Review[]>([])
const reviewText = ref('')
const rating = ref(5)
const busy = ref(false)
const checkoutPhase = ref('cart')
const paymentMethod = ref('card')
const cart = ref<Record<number, number>>({})
const pendingOrders = ref<Record<number, number>>({})
const receipt = ref<number[]>([])
const notice = ref('')
const chatInput = ref('')
const messages = ref([{ text: 'Здравствуйте! Помогу выбрать бокс, найти заказ или оформить возврат. Что вас интересует?', own: false
}])
let poll: ReturnType<typeof setInterval> | undefined
let noticeTimer: ReturnType<typeof setTimeout> | undefined
const categories = ['Все', 'Выпечка', 'Десерты', 'Готовая еда', 'Суши']
const money = (value: number) => new Intl.NumberFormat('ru-RU', {
  maximumFractionDigits: 0
}).format(value) + ' ₽'
const place = (id: number) => snapshot.value.points.find(p => p.id === id)
const asset = (offer: Offer) => `${config.public.apiBase}${offer.image_url || `/demo/media/food-${offer.point_id % 6}.svg`}`
const original = (offer: Offer) => offer.original_price || offer.price * 2
const discount = (offer: Offer) => Math.round((1 - offer.price / original(offer)) * 100)
const pickup = (offer: Offer) => `${offer.pickup_start || '18:00'}–${offer.pickup_end || '21:00'}`
const kind = (offer: Offer) => /суши|ролл|поке/i.test(offer.name) ? 'Суши' : /торт|эклер|десерт|чизкейк/i.test(offer.name) ? 'Десерты' : /бул|хлеб|багет|круассан|выпеч|ватруш/i.test(offer.name) ? 'Выпечка' : 'Готовая еда'
const visible = computed(() => snapshot.value.products.filter(p => p.is_active && p.is_available && p.quantity > 0
  && (!city.value || place(p.point_id)?.city_id === city.value)
  && (category.value === 'Все' || kind(p) === category.value)
  && (view.value !== 'favorites' || snapshot.value.favorites.includes(p.point_id))
  && `${p.name} ${p.description} ${place(p.point_id)?.name}`.toLowerCase().includes(query.value.toLowerCase())))
const items = computed(() => snapshot.value.products.filter(p => (cart.value[p.id] || 0) > 0))
const quantity = computed(() => Object.values(cart.value).reduce((a, b) => a + b, 0))
const total = computed(() => items.value.reduce((a, p) => a + p.price * cart.value[p.id]!, 0))
const saving = computed(() => items.value.reduce((a, p) => a + (original(p) - p.price) * cart.value[p.id]!, 0))
const activeOrders = computed(() => snapshot.value.orders.filter(o => o.status === 'pending' || o.status === 'processing'))
const rescued = computed(() => snapshot.value.orders.filter(o => o.status !== 'cancelled').reduce((n, o) => n + o.products_id.length, 0))
const totalSaved = computed(() => snapshot.value.orders.filter(o => o.status !== 'cancelled').reduce((n, o) => n + o.products_id.reduce((s, id) => {
  const p = snapshot.value.products.find(x => x.id === id)
  return s + (p ? original(p) - p.price : 100)
}, 0), 0))
const statusLabel = (o: Order) => ({ pending: 'Оплачен', processing: 'Готов к выдаче', completed: 'Получен', cancelled: 'Отменён'
})[o.status]
const date = (value: string) => new Date(value).toLocaleDateString('ru-RU', {
  day: 'numeric', month: 'long'
})

function toast(text: string) {
  notice.value = text
  clearTimeout(noticeTimer)
  noticeTimer = setTimeout(() => {
    notice.value = ''
  }, 4000)
}
function scrollOffers() {
  document.getElementById('offers')?.scrollIntoView({ behavior: 'smooth'
  })
}
async function refresh() {
  snapshot.value = await request<Snapshot>('/demo/state')
}
async function boot() {
  loading.value = true
  error.value = ''
  try {
    auth.hydrate()
    if (!auth.isAuthenticated || auth.user?.role !== 'user') await auth.demoLogin()
    await refresh()
    try {
      cart.value = JSON.parse(localStorage.getItem('eshkush_demo_cart') || '{}')
      pendingOrders.value = JSON.parse(localStorage.getItem('eshkush_demo_checkout') || '{}')
    } catch {
      cart.value = {}
      pendingOrders.value = {}
    }
  } catch (e) {
    error.value = getErrorMessage(e, 'Приложение ещё запускается. Попробуйте ещё раз через несколько секунд.')
  } finally {
    loading.value = false
  }
}
onMounted(() => {
  void boot()
  poll = setInterval(() => {
    if (!busy.value && auth.user?.role === 'user') void refresh().catch(() => {})
  }, 8000)
})
onUnmounted(() => {
  clearInterval(poll)
  clearTimeout(noticeTimer)
})
watch(cart, value => localStorage.setItem('eshkush_demo_cart', JSON.stringify(value)), {
  deep: true
})
function add(offer: Offer, delta = 1) {
  if (Object.keys(pendingOrders.value).length) {
    toast('Сначала завершите начатую оплату')
    drawer.value = 'cart'
    return
  }
  const next = (cart.value[offer.id] || 0) + delta
  if (next > offer.quantity) {
    toast('Вы выбрали весь доступный остаток')
    return
  }
  cart.value = {
    ...cart.value, [offer.id]: Math.max(0, next)
  }
  if (delta > 0) toast('Бокс добавлен в корзину')
}
async function favorite(offer: Offer) {
  const active = !snapshot.value.favorites.includes(offer.point_id)
  try {
    await request('/demo/favorite', {
      method: 'POST', body: {
        point_id: offer.point_id, active
      }
    })
    await refresh()
    toast(active ? 'Заведение сохранено в избранном' : 'Удалено из избранного')
  } catch (e) {
    toast(getErrorMessage(e, 'Не удалось сохранить'))
  }
}
async function openDetail(offer: Offer) {
  detail.value = offer
  reviews.value = []
  reviewText.value = ''
  try {
    reviews.value = await request<Review[]>(`/reviews/point/${offer.point_id}`)
  } catch {
    /* details still available */
  }
}
async function review() {
  if (!detail.value || !reviewText.value.trim()) return
  busy.value = true
  try {
    await request('/reviews/', {
      method: 'POST', body: {
        point_id: detail.value.point_id, rating: rating.value, comment: reviewText.value
      }
    })
    await openDetail(detail.value)
    await refresh()
    toast('Спасибо! Ваш отзыв опубликован')
  } catch (e) {
    toast(getErrorMessage(e, 'Не удалось отправить отзыв'))
  } finally {
    busy.value = false
  }
}
async function pay() {
  if (!items.value.length || busy.value) return
  busy.value = true
  error.value = ''
  checkoutPhase.value = 'paying'
  try {
    const groups = new Map<number, Offer[]>()
    for (const p of items.value) groups.set(p.point_id, [...(groups.get(p.point_id) || []), p])
    for (const [pointId, offers] of groups) {
      if (!pendingOrders.value[pointId]) {
        const ids = offers.flatMap(p => Array.from({ length: cart.value[p.id] || 0
        }, () => p.id))
        const order = await request<Order>('/orders/', {
          method: 'POST', body: {
            user_id: auth.user!.id, point_id: pointId, products_id: ids,
            total_price: offers.reduce((s, p) => s + p.price * cart.value[p.id]!, 0)

          }
        })
        pendingOrders.value[pointId] = order.id
        localStorage.setItem('eshkush_demo_checkout', JSON.stringify(pendingOrders.value))
      }
      await request('/payments/create', {
        method: 'POST', body: {
          order_id: pendingOrders.value[pointId], payment_method: paymentMethod.value
        }
      })
    }
    receipt.value = Object.values(pendingOrders.value)
    await new Promise(resolve => setTimeout(resolve, 900))
    cart.value = {}
    pendingOrders.value = {}
    localStorage.removeItem('eshkush_demo_checkout')
    await refresh()
    checkoutPhase.value = 'success'
  } catch (e) {
    error.value = getErrorMessage(e, 'Оплата не завершена. Повторите попытку — созданные заказы сохранены.')
    checkoutPhase.value = 'payment'
  } finally {
    busy.value = false
  }
}
async function cancel(order: Order) {
  busy.value = true
  try {
    await request(`/orders/${order.id}/refund`, {
      method: 'POST', body: {}
    })
    await refresh()
    toast('Заказ отменён. Возврат оформлен')
  } catch (e) {
    toast(getErrorMessage(e, 'Не удалось отменить заказ'))
  } finally {
    busy.value = false
  }
}
async function social(provider: string) {
  busy.value = true
  try {
    await auth.demoLogin()
    await refresh()
    toast(`Вход через ${provider} выполнен в демо-режиме`)
    drawer.value = ''
  } catch (e) {
    toast(getErrorMessage(e, 'Вход не выполнен'))
  } finally {
    busy.value = false
  }
}
function chat() {
  const text = chatInput.value.trim()
  if (!text) return
  messages.value.push({ text, own: true
  })
  chatInput.value = ''
  setTimeout(() => {
    const reply = /отмен|возврат/i.test(text)
      ? 'Откройте «Мои заказы» и нажмите «Отменить и вернуть». Оплаченный бокс отменится, сумма вернётся, а остаток в заведении восстановится.'
      : /заказ|код|забрат/i.test(text)
        ? 'Код получения находится в «Моих заказах». Приходите в указанное окно выдачи и покажите код сотруднику. Партнёр отметит заказ как полученный.'
        : /оплат|карт|сбп/i.test(text)
          ? 'В корзине можно выбрать карту или СБП. В этой демонстрации оплата подтверждается локально, без списания денег.'
          : 'Выбирайте заведение рядом, добавляйте бокс в корзину и забирайте его в указанное время. Содержимое бокса зависит от того, что осталось свежим сегодня. Хотите узнать об оплате или заказах?'
    messages.value.push({ text: reply, own: false
    })
  }, 650)
}
function mapPosition(point: Place, index: number) {
  const points = snapshot.value.points.filter(p => !city.value || p.city_id === city.value)
  const minX = Math.min(...points.map(p => p.longitude)), maxX = Math.max(...points.map(p => p.longitude))
  const minY = Math.min(...points.map(p => p.latitude)), maxY = Math.max(...points.map(p => p.latitude))
  return {
    left: `${12 + 73 * (point.longitude - minX) / (maxX - minX || 1)}%`, top: `${14 + 64 * (maxY - point.latitude) / (maxY - minY || 1) + index % 2 * 3}%`
  }
}
</script>

<template>
  <div class="shop-shell">
    <header class="shop-header">
      <button
        class="brand"
        @click="view = 'catalog'; query = ''; category = 'Все'"
      >
        <span class="brand-mark">е</span><span>ешькуш<span class="brand-dot">.</span></span>
      </button>
      <label class="location"><UIcon name="i-lucide-map-pin" /><select
        v-model="city"
        aria-label="Город"
      ><option :value="0">Все города</option><option
        v-for="c in snapshot.cities"
        :key="c.id"
        :value="c.id"
      >{{ c.name }}</option></select></label>
      <nav class="desktop-nav">
        <button
          :class="{ selected: view === 'catalog' }"
          @click="view = 'catalog'"
        >
          Предложения
        </button><button
          :class="{ selected: view === 'map' }"
          @click="view = 'map'"
        >
          На карте
        </button><button
          :class="{ selected: view === 'orders' }"
          @click="view = 'orders'"
        >
          Мои заказы <span
            v-if="activeOrders.length"
            class="tiny-dot"
          />
        </button>
      </nav>
      <div class="header-actions">
        <NuxtLink
          to="/demo"
          class="demo-tag"
        >Демо</NuxtLink><button
          class="icon-btn"
          aria-label="Уведомления"
          @click="drawer = 'notifications'"
        >
          <UIcon name="i-lucide-bell" />
        </button><button
          class="avatar"
          aria-label="Профиль"
          @click="view = 'profile'"
        >
          А
        </button><button
          class="cart-btn"
          aria-label="Корзина"
          @click="drawer = 'cart'; checkoutPhase = 'cart'"
        >
          <UIcon name="i-lucide-shopping-bag" /><span class="cart-label">Корзина</span><b v-if="quantity">{{ quantity }}</b>
        </button>
      </div>
    </header>
    <main class="shop-main">
      <div
        v-if="error && drawer !== 'cart'"
        class="error-banner"
        role="alert"
      >
        {{ error }} <button @click="boot">
          Повторить
        </button>
      </div>
      <div
        v-if="loading"
        class="loading-grid"
        aria-label="Загрузка предложений"
      >
        <div
          v-for="n in 6"
          :key="n"
          class="skeleton-card"
        />
      </div>
      <template v-else-if="!error || snapshot.products.length">
        <template v-if="view === 'catalog' || view === 'favorites'">
          <section
            v-if="view === 'catalog'"
            class="hero"
          >
            <div class="hero-copy">
              <span class="eyebrow"><span /> Вкусная еда. Разумный выбор.</span><h1>Хорошая еда<br>заслуживает <em>шанса.</em></h1><p>Забирайте свежие боксы из любимых заведений<br class="desktop-only"> со скидкой до 70%. Вкусно вам — легче планете.</p><button
                class="primary-btn"
                @click="scrollOffers()"
              >
                Выбрать свой бокс <UIcon name="i-lucide-arrow-down-right" />
              </button><div class="hero-proof">
                <span class="mini-avatars">А М Д</span><span><b>1 240 боксов</b> нашли свой дом</span>
              </div>
            </div>
            <div class="hero-art">
              <div class="hero-orbit" /><img
                src="/demo/bag.png"
                alt="Зелёный пакет ЕшьКуш со свежими продуктами"
              ><span class="float-label float-top"><UIcon name="i-lucide-leaf" /> меньше отходов</span><span class="float-label float-bottom">больше вкуса <span>↗</span></span><span class="art-star">✳</span>
            </div>
          </section>
          <section
            id="offers"
            class="offer-section"
          >
            <div class="section-heading">
              <div><span class="eyebrow muted">СВЕЖЕЕ К ВЕЧЕРУ</span><h2>{{ view === 'favorites' ? 'Ваши любимые места' : 'Сегодня можно спасти' }}</h2></div><span class="offer-count">{{ visible.length }} предложений рядом</span>
            </div>
            <div class="catalog-tools">
              <div class="category-tabs">
                <button
                  v-for="c in categories"
                  :key="c"
                  :class="{ active: category === c }"
                  @click="category = c"
                >
                  {{ c }}
                </button>
              </div><label class="search"><UIcon name="i-lucide-search" /><input
                v-model="query"
                placeholder="Найти бокс или заведение"
                aria-label="Поиск предложений"
              ></label><button
                class="icon-btn favorite-filter"
                :class="{ active: view === 'favorites' }"
                aria-label="Избранное"
                @click="view = view === 'favorites' ? 'catalog' : 'favorites'"
              >
                <UIcon name="i-lucide-heart" />
              </button>
            </div>
            <div
              v-if="!visible.length"
              class="empty-state"
            >
              <UIcon name="i-lucide-search" /><h3>Пока ничего не нашлось</h3><p>Попробуйте другой город, категорию или сохраните любимое заведение.</p><button
                class="secondary-btn"
                @click="query = ''; category = 'Все'; city = 0; view = 'catalog'"
              >
                Все предложения
              </button>
            </div>
            <div class="offers-grid">
              <article
                v-for="p in visible"
                :key="p.id"
                class="offer-card"
              >
                <div
                  class="offer-image"
                  @click="openDetail(p)"
                >
                  <img
                    :src="asset(p)"
                    :alt="p.name"
                  ><span class="discount">−{{ discount(p) }}%</span><button
                    class="heart-btn"
                    :class="{ loved: snapshot.favorites.includes(p.point_id) }"
                    :aria-label="snapshot.favorites.includes(p.point_id) ? 'Убрать из избранного' : 'В избранное'"
                    @click.stop="favorite(p)"
                  >
                    <UIcon name="i-lucide-heart" />
                  </button><span class="stock-label">{{ p.quantity <= 3 ? `Осталось ${p.quantity}` : `${p.items_count || 1} шт. в боксе` }}</span>
                </div><div class="offer-body">
                  <div class="place-line">
                    <span>{{ place(p.point_id)?.name }}</span><span class="rating"><UIcon name="i-lucide-star" />{{ place(p.point_id)?.rating || '4.8' }}</span>
                  </div><button
                    class="offer-title"
                    @click="openDetail(p)"
                  >
                    {{ p.name }}
                  </button><p class="pickup-line">
                    <UIcon name="i-lucide-clock-3" /> Сегодня, {{ pickup(p) }}
                  </p><div class="price-line">
                    <div><strong>{{ money(p.price) }}</strong><del>{{ money(original(p)) }}</del></div><button
                      class="add-btn"
                      :aria-label="`Добавить ${p.name}`"
                      @click="add(p)"
                    >
                      <UIcon name="i-lucide-plus" />
                    </button>
                  </div>
                </div>
              </article>
            </div>
          </section>
          <section class="how-it-works">
            <div><span>01</span><h3>Найдите свой вкус</h3><p>Выберите бокс из пекарни, кафе или магазина рядом.</p></div><div><span>02</span><h3>Забронируйте бокс</h3><p>Оплатите выгодную находку — мы сохраним её для вас.</p></div><div><span>03</span><h3>Заберите и наслаждайтесь</h3><p>Покажите код в заведении в указанное время выдачи.</p></div>
          </section>
        </template>
        <section
          v-else-if="view === 'orders'"
          class="inner-page"
        >
          <span class="eyebrow muted">ВСЁ ПОД РУКОЙ</span><h1>Мои заказы</h1><p class="page-subtitle">
            Свежие находки и маленькие хорошие дела.
          </p><div
            v-if="!snapshot.orders.length"
            class="empty-state"
          >
            <UIcon name="i-lucide-shopping-bag" /><h3>Ваш первый бокс ждёт вас</h3><button
              class="primary-btn"
              @click="view = 'catalog'"
            >
              Найти вкусное
            </button>
          </div><div class="orders-grid">
            <article
              v-for="o in snapshot.orders"
              :key="o.id"
              class="order-card"
            >
              <div class="order-top">
                <span
                  class="order-status"
                  :class="o.status"
                ><span />{{ statusLabel(o) }}</span><span>№ {{ String(o.id).padStart(5, '0') }}</span>
              </div><h3>{{ place(o.point_id)?.name }}</h3><p>{{ place(o.point_id)?.address }}</p><div class="order-products">
                <span
                  v-for="(id, n) in o.products_id"
                  :key="`${id}-${n}`"
                >{{ snapshot.products.find(p => p.id === id)?.name || 'Сюрприз-бокс' }}</span>
              </div><div class="order-bottom">
                <strong>{{ money(o.total_price) }}</strong><span>{{ date(o.date) }}</span>
              </div><div
                v-if="o.status === 'pending' || o.status === 'processing'"
                class="pickup-ticket"
              >
                <UIcon name="i-lucide-qr-code" /><div><span>Ваш код получения</span><strong>ЕК-{{ String(o.id).padStart(5, '0') }}</strong></div><UIcon name="i-lucide-check-check" />
              </div><button
                v-if="o.status === 'pending' || o.status === 'processing'"
                class="text-btn"
                :disabled="busy"
                @click="cancel(o)"
              >
                Отменить и вернуть
              </button>
            </article>
          </div>
        </section>
        <section
          v-else-if="view === 'map'"
          class="inner-page"
        >
          <span class="eyebrow muted">ХОРОШАЯ ЕДА РЯДОМ</span><h1>Найдите любимое место</h1><p class="page-subtitle">
            Схематичная карта заведений. Нажмите на отметку, чтобы посмотреть боксы.
          </p><div class="demo-map">
            <svg
              viewBox="0 0 1000 550"
              preserveAspectRatio="none"
              aria-hidden="true"
            ><rect
              width="1000"
              height="550"
              fill="#edf0e6"
            /><path
              d="M0 190Q280 310 590 220T1000 290"
              fill="none"
              stroke="#c2dbe0"
              stroke-width="65"
            /><path
              d="M0 100L1000 100M0 420L1000 420M220 0L220 550M550 0L550 550M820 0L820 550M0 0L1000 550"
              stroke="#fffdf7"
              stroke-width="20"
            /><path
              d="M0 100L1000 100M0 420L1000 420M220 0L220 550M550 0L550 550M820 0L820 550"
              stroke="#d8d8c9"
              stroke-width="2"
            /><g fill="#d9e3c9"><rect
              x="280"
              y="30"
              width="160"
              height="45"
              rx="15"
            /><rect
              x="600"
              y="330"
              width="150"
              height="60"
              rx="15"
            /><rect
              x="40"
              y="450"
              width="140"
              height="65"
              rx="15"
            /></g><text
              x="60"
              y="240"
              fill="#749da2"
              font-size="22"
            >Тура</text></svg><button
              v-for="(p, n) in snapshot.points.filter(p => !city || p.city_id === city)"
              :key="p.id"
              class="map-pin"
              :style="mapPosition(p, n)"
              @click="query = p.name; category = 'Все'; view = 'catalog'"
            >
              <UIcon name="i-lucide-store" /><span>{{ p.name }}</span>
            </button><span class="map-legend"><span />{{ snapshot.points.filter(p => !city || p.city_id === city).length }} заведений</span>
          </div>
        </section>
        <section
          v-else-if="view === 'profile'"
          class="inner-page"
        >
          <span class="eyebrow muted">ВАШИ МАЛЕНЬКИЕ ПОБЕДЫ</span><h1>Привет, Александр!</h1><p class="page-subtitle">
            Каждый спасённый бокс — вклад в более разумный мир.
          </p><div class="impact-grid">
            <article><UIcon name="i-lucide-shopping-bag" /><strong>{{ rescued }}</strong><span>спасённых боксов</span></article><article><UIcon name="i-lucide-wallet" /><strong>{{ money(totalSaved) }}</strong><span>сэкономлено на любимой еде</span></article><article><UIcon name="i-lucide-leaf" /><strong>{{ (rescued * 1.8).toFixed(1) }} кг</strong><span>оценка предотвращённых выбросов CO₂</span></article>
          </div><div class="profile-row">
            <div class="profile-card">
              <span class="avatar big">А</span><div><h3>Александр</h3><p>{{ auth.user?.email || 'demo@eshkush.test' }}</p><span class="demo-tag">Демонстрационный профиль</span></div>
            </div><div class="profile-card">
              <UIcon
                name="i-lucide-sprout"
                class="profile-leaf"
              /><div><h3>Друг планеты</h3><p>Продолжайте спасать вкусную еду.<br>Ваш следующий бокс уже рядом.</p></div>
            </div>
          </div><div class="profile-buttons">
            <button
              class="secondary-btn"
              @click="view = 'orders'"
            >
              История заказов <UIcon name="i-lucide-arrow-right" />
            </button><button
              class="secondary-btn"
              @click="view = 'favorites'"
            >
              Избранные места <UIcon name="i-lucide-heart" />
            </button><button
              class="secondary-btn"
              @click="drawer = 'login'"
            >
              Способы входа <UIcon name="i-lucide-user-round" />
            </button><button
              class="secondary-btn"
              @click="drawer = 'support'"
            >
              Поддержка <UIcon name="i-lucide-message-circle" />
            </button>
          </div>
        </section>
      </template>
      <footer class="shop-footer">
        <span class="brand small">ешькуш.</span><span>Вкусно вам. Хорошо планете.</span><NuxtLink to="/login">Для партнёров ↗</NuxtLink><NuxtLink to="/demo">О демонстрации</NuxtLink>
      </footer>
    </main>
    <nav class="mobile-nav">
      <button
        :class="{ active: view === 'catalog' }"
        @click="view = 'catalog'"
      >
        <UIcon name="i-lucide-house" />Главная
      </button><button
        :class="{ active: view === 'map' }"
        @click="view = 'map'"
      >
        <UIcon name="i-lucide-map-pin" />Карта
      </button><button
        :class="{ active: view === 'favorites' }"
        @click="view = 'favorites'"
      >
        <UIcon name="i-lucide-heart" />Избранное
      </button><button
        :class="{ active: view === 'orders' }"
        @click="view = 'orders'"
      >
        <UIcon name="i-lucide-receipt" />Заказы
      </button><button
        :class="{ active: view === 'profile' }"
        @click="view = 'profile'"
      >
        <UIcon name="i-lucide-user-round" />Профиль
      </button>
    </nav>
    <button
      class="support-fab"
      aria-label="Помощник"
      @click="drawer = 'support'"
    >
      <UIcon name="i-lucide-message-circle" />
    </button>
    <Transition name="toast">
      <div
        v-if="notice"
        class="shop-toast"
        role="status"
      >
        <UIcon name="i-lucide-circle-check" />{{ notice }}
      </div>
    </Transition>
    <div
      v-if="detail"
      class="modal-backdrop"
      @click.self="detail = null"
    >
      <section
        class="detail-modal"
        role="dialog"
        aria-modal="true"
        :aria-label="detail.name"
      >
        <button
          class="modal-close"
          aria-label="Закрыть"
          @click="detail = null"
        >
          <UIcon name="i-lucide-x" />
        </button><img
          :src="asset(detail)"
          :alt="detail.name"
          class="detail-image"
        ><div class="detail-copy">
          <span class="eyebrow muted">{{ place(detail.point_id)?.name }} · ★ {{ place(detail.point_id)?.rating || '4.8' }}</span><h2>{{ detail.name }}</h2><p>{{ detail.description }}</p><div class="detail-facts">
            <span><UIcon name="i-lucide-clock-3" />Сегодня {{ pickup(detail) }}</span><span><UIcon name="i-lucide-package" />{{ detail.items_count || 1 }} шт. · {{ detail.weight }} кг</span><span><UIcon name="i-lucide-map-pin" />{{ place(detail.point_id)?.address }}</span>
          </div><div class="detail-note">
            <UIcon name="i-lucide-sparkles" /><p>Бокс собирают из свежих продуктов, которые не успели продать сегодня. Отличный вкус — приятная неожиданность.</p>
          </div><button
            class="primary-btn full"
            @click="add(detail); detail = null"
          >
            Добавить за {{ money(detail.price) }} <span>−{{ discount(detail) }}%</span>
          </button><div class="reviews">
            <h3>Впечатления гостей</h3><p
              v-if="!reviews.length"
              class="muted"
            >
              Станьте первым, кто поделится впечатлением.
            </p><div
              v-for="r in reviews"
              :key="r.id"
              class="review"
            >
              <b>{{ '★'.repeat(Math.round(r.rating)) }}</b><p>{{ r.comment }}</p>
            </div><label class="review-rating">Ваша оценка <select v-model="rating"><option
              v-for="n in 5"
              :key="n"
              :value="n"
            >{{ n }} ★</option></select></label><textarea
              v-model="reviewText"
              placeholder="Что вам понравилось?"
              aria-label="Ваш отзыв"
            /><button
              class="secondary-btn full"
              :disabled="busy || !reviewText.trim()"
              @click="review"
            >
              Оставить отзыв
            </button>
          </div>
        </div>
      </section>
    </div>
    <div
      v-if="drawer"
      class="modal-backdrop"
      @click.self="!busy && (drawer = '')"
    >
      <aside
        class="shop-drawer"
        role="dialog"
        aria-modal="true"
        :aria-label="drawer === 'cart' ? 'Корзина' : 'Помощь и профиль'"
      >
        <div class="drawer-heading">
          <h2>{{ drawer === 'cart' ? 'Ваши находки' : drawer === 'support' ? 'Помощник ЕшьКуш' : drawer === 'login' ? 'Вход в приложение' : 'Уведомления' }}</h2><button
            class="icon-btn"
            aria-label="Закрыть"
            :disabled="busy"
            @click="drawer = ''"
          >
            <UIcon name="i-lucide-x" />
          </button>
        </div>
        <template v-if="drawer === 'cart'">
          <p
            v-if="error"
            class="error-banner"
            role="alert"
          >
            {{ error }}
          </p><template v-if="checkoutPhase === 'success'">
            <div class="checkout-success">
              <span class="success-circle"><UIcon name="i-lucide-check" /></span><h2>Боксы ваши!</h2><p>Всё готово. Заберите заказ в выбранном заведении и покажите код получения.</p><div
                v-for="id in receipt"
                :key="id"
                class="pickup-ticket"
              >
                <UIcon name="i-lucide-qr-code" /><div><span>Код получения</span><strong>ЕК-{{ String(id).padStart(5, '0') }}</strong></div>
              </div><button
                class="primary-btn full"
                @click="drawer = ''; view = 'orders'"
              >
                Перейти к заказам
              </button><span class="muted text-sm">Демо-оплата: деньги не списывались</span>
            </div>
          </template><div
            v-else-if="checkoutPhase === 'paying'"
            class="checkout-success"
          >
            <div class="payment-spinner" /><h2>Подтверждаем оплату</h2><p>Сохраняем ваши боксы и готовим код получения…</p>
          </div><template v-else>
            <div
              v-if="!items.length"
              class="empty-state"
            >
              <UIcon name="i-lucide-shopping-bag" /><h3>Здесь будут ваши находки</h3><p>Добавьте первый бокс из каталога.</p><button
                class="primary-btn"
                @click="drawer = ''; view = 'catalog'"
              >
                Выбрать бокс
              </button>
            </div><template v-else>
              <div class="cart-items">
                <article
                  v-for="p in items"
                  :key="p.id"
                  class="cart-item"
                >
                  <img
                    :src="asset(p)"
                    :alt="p.name"
                  ><div>
                    <h3>{{ p.name }}</h3><p>{{ place(p.point_id)?.name }}</p><span>Сегодня {{ pickup(p) }}</span><div class="cart-item-bottom">
                      <strong>{{ money(p.price) }}</strong><div class="quantity-control">
                        <button
                          :aria-label="`Уменьшить ${p.name}`"
                          @click="add(p, -1)"
                        >
                          −
                        </button><b>{{ cart[p.id] }}</b><button
                          :aria-label="`Увеличить ${p.name}`"
                          @click="add(p)"
                        >
                          +
                        </button>
                      </div>
                    </div>
                  </div>
                </article>
              </div><div class="cart-summary">
                <div><span>Боксов</span><b>{{ quantity }}</b></div><div class="saved-line">
                  <span>Ваша экономия</span><b>{{ money(saving) }}</b>
                </div><div class="cart-total">
                  <span>Итого</span><strong>{{ money(total) }}</strong>
                </div>
              </div><template v-if="checkoutPhase === 'payment'">
                <h3 class="payment-heading">
                  Как вам удобнее?
                </h3><div class="payment-choices">
                  <button
                    :class="{ selected: paymentMethod === 'card' }"
                    @click="paymentMethod = 'card'"
                  >
                    <UIcon name="i-lucide-credit-card" />Банковская карта<span>•••• 4242</span>
                  </button><button
                    :class="{ selected: paymentMethod === 'mobilePayment' }"
                    @click="paymentMethod = 'mobilePayment'"
                  >
                    <UIcon name="i-lucide-qr-code" />СБП<span>Быстрая оплата</span>
                  </button>
                </div><div class="detail-note">
                  <UIcon name="i-lucide-shield-check" /><p>Демонстрационная оплата без ввода реквизитов и списания денег.</p>
                </div><button
                  class="primary-btn full"
                  :disabled="busy"
                  @click="pay"
                >
                  Оплатить {{ money(total) }} <UIcon name="i-lucide-arrow-right" />
                </button>
              </template><template v-else>
                <button
                  class="primary-btn full"
                  @click="checkoutPhase = 'payment'"
                >
                  К оформлению <UIcon name="i-lucide-arrow-right" />
                </button><p class="cart-hint">
                  <UIcon name="i-lucide-leaf" />Хороший выбор. Вместе спасаем свежую еду.
                </p>
              </template>
            </template>
          </template>
        </template>
        <template v-else-if="drawer === 'support'">
          <p class="assistant-subtitle">
            <span />Локальный демо-помощник · отвечает сразу
          </p><div class="chat-messages">
            <div
              v-for="(m, n) in messages"
              :key="n"
              class="chat-message"
              :class="{ own: m.own }"
            >
              {{ m.text }}
            </div>
          </div><form
            class="chat-form"
            @submit.prevent="chat"
          >
            <input
              v-model="chatInput"
              placeholder="Напишите ваш вопрос"
              aria-label="Сообщение помощнику"
            ><button aria-label="Отправить">
              <UIcon name="i-lucide-arrow-up" />
            </button>
          </form>
        </template>
        <template v-else-if="drawer === 'login'">
          <p class="page-subtitle">
            Выберите привычный способ. Все входы в этой демонстрации открывают один тестовый профиль.
          </p><button
            v-for="provider in ['Яндекс', 'ВКонтакте', 'Telegram', 'Номер телефона']"
            :key="provider"
            class="social-login secondary-btn full"
            :disabled="busy"
            @click="social(provider)"
          >
            {{ provider }} <UIcon name="i-lucide-arrow-right" />
          </button>
        </template>
        <template v-else>
          <div class="notification">
            <UIcon name="i-lucide-sparkles" /><div><h3>Сегодня снова вкусно</h3><p>В любимых заведениях появились свежие боксы. Самое время выбрать свой.</p></div>
          </div><div
            v-for="o in activeOrders"
            :key="o.id"
            class="notification"
          >
            <UIcon name="i-lucide-package-check" /><div>
              <h3>{{ statusLabel(o) }} · № {{ o.id }}</h3><p>{{ place(o.point_id)?.name }} ждёт вас. Код: ЕК-{{ String(o.id).padStart(5, '0') }}.</p><button
                class="text-btn"
                @click="drawer = ''; view = 'orders'"
              >
                Посмотреть заказ →
              </button>
            </div>
          </div>
        </template>
      </aside>
    </div>
  </div>
</template>

<style scoped>
@import '~/assets/css/showcase.css';
</style>
