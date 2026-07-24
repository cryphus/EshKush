import type { Order, Point, Product, Paginated } from '~/types/api'

/** Комиссия платформы с каждой продажи (см. бизнес-модель B2B2C — 14%). */
export const PLATFORM_COMMISSION = 0.14

export interface DailyRevenue {
  day: Date
  revenue: number
}

export interface PointRevenue {
  pointId: number
  pointName: string
  revenue: number
}

function parseListResponse<T>(data: T[] | Paginated<T>): T[] {
  return Array.isArray(data) ? data : data.data
}

/**
 * Загружает точки, продукты и заказы партнёра одним заходом и возвращает
 * реактивные данные + вычисляемую аналитику (KPI, графики).
 * Данные партнёра не разделены по конкретному partner_id на бэкенде для
 * ролей partner/admin — API возвращает весь список, доступный роли.
 */
export function usePartnerData() {
  const { request } = useApi()

  const points = ref<Point[]>([])
  const products = ref<Product[]>([])
  const orders = ref<Order[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function refresh() {
    loading.value = true
    error.value = null
    try {
      const [pointsRes, productsRes, ordersRes] = await Promise.all([
        request<Point[] | Paginated<Point>>('/points/', { params: { limit: 100 } }),
        request<Product[] | Paginated<Product>>('/products/', { params: { limit: 100 } }),
        request<Order[] | Paginated<Order>>('/orders/', { params: { limit: 200 } }).catch(() => [])
      ])
      points.value = parseListResponse(pointsRes)
      products.value = parseListResponse(productsRes)
      orders.value = parseListResponse(ordersRes as Order[] | Paginated<Order>)
    } catch (e) {
      error.value = getErrorMessage(e, 'Не удалось загрузить данные')
    } finally {
      loading.value = false
    }
  }

  function pointName(pointId: number): string {
    return points.value.find(p => p.id === pointId)?.name ?? `Точка #${pointId}`
  }

  const completedOrders = computed(() => orders.value.filter(o => o.status === 'completed'))
  const activeOrders = computed(() =>
    orders.value.filter(o => o.status === 'pending' || o.status === 'processing'))
  const cancelledOrders = computed(() => orders.value.filter(o => o.status === 'cancelled'))

  function completedInPeriod(days: number): Order[] {
    if (days <= 0) return completedOrders.value
    const since = new Date()
    since.setDate(since.getDate() - days)
    return completedOrders.value.filter(o => new Date(o.date) > since)
  }

  function soldBoxes(days: number) {
    return completedInPeriod(days).length
  }

  function grossRevenue(days: number) {
    return completedInPeriod(days).reduce((s, o) => s + o.total_price, 0)
  }

  function netRevenue(days: number) {
    return grossRevenue(days) * (1 - PLATFORM_COMMISSION)
  }

  function avgCheck(days: number) {
    const list = completedInPeriod(days)
    if (list.length === 0) return 0
    return grossRevenue(days) / list.length
  }

  function uniqueBuyers(days: number) {
    return new Set(completedInPeriod(days).map(o => o.user_id)).size
  }

  const avgRating = computed(() => {
    const withRating = points.value.filter(p => p.rating > 0)
    if (withRating.length === 0) return 0
    return withRating.reduce((s, p) => s + p.rating, 0) / withRating.length
  })

  const activeProductsCount = computed(() =>
    products.value.filter(p => p.is_active && p.is_available).length)

  function revenueByDay(days: number): DailyRevenue[] {
    const span = days <= 0 ? 30 : days
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const start = new Date(today)
    start.setDate(start.getDate() - (span - 1))

    const buckets = new Map<number, number>()
    for (let i = 0; i < span; i++) {
      const d = new Date(start)
      d.setDate(d.getDate() + i)
      buckets.set(d.getTime(), 0)
    }
    for (const o of completedOrders.value) {
      const d = new Date(o.date)
      d.setHours(0, 0, 0, 0)
      const key = d.getTime()
      if (buckets.has(key)) {
        buckets.set(key, buckets.get(key)! + o.total_price)
      }
    }
    return [...buckets.entries()]
      .sort((a, b) => a[0] - b[0])
      .map(([time, revenue]) => ({ day: new Date(time), revenue }))
  }

  function revenueByPoint(days: number): PointRevenue[] {
    const buckets = new Map<number, number>()
    for (const o of completedInPeriod(days)) {
      buckets.set(o.point_id, (buckets.get(o.point_id) ?? 0) + o.total_price)
    }
    return [...buckets.entries()]
      .map(([pointId, revenue]) => ({ pointId, pointName: pointName(pointId), revenue }))
      .sort((a, b) => b.revenue - a.revenue)
  }

  return {
    points,
    products,
    orders,
    loading,
    error,
    refresh,
    pointName,
    completedOrders,
    activeOrders,
    cancelledOrders,
    soldBoxes,
    grossRevenue,
    netRevenue,
    avgCheck,
    uniqueBuyers,
    avgRating,
    activeProductsCount,
    revenueByDay,
    revenueByPoint
  }
}
