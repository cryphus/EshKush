<script setup lang="ts">
import { Line as LineChart, Doughnut as DoughnutChart } from 'vue-chartjs'

definePageMeta({ title: 'Аналитика' })

const {
  loading,
  error,
  refresh,
  soldBoxes,
  netRevenue,
  avgCheck,
  uniqueBuyers,
  avgRating,
  activeProductsCount,
  revenueByDay,
  revenueByPoint,
  completedOrders,
  pointName
} = usePartnerData()

onMounted(refresh)

const period = ref<7 | 30 | 0>(30)
const periodOptions = [
  { label: '7 дней', value: 7 as const },
  { label: '30 дней', value: 30 as const },
  { label: 'Всё время', value: 0 as const }
]

const money = new Intl.NumberFormat('ru-RU', {
  style: 'currency',
  currency: 'RUB',
  maximumFractionDigits: 0
})

const kpis = computed(() => [
  { label: 'Продано боксов', value: String(soldBoxes(period.value)), icon: 'i-lucide-shopping-bag', color: 'text-blue-500' },
  { label: 'Выручка (нетто)', value: money.format(netRevenue(period.value)), hint: 'после комиссии 14%', icon: 'i-lucide-wallet', color: 'text-green-500' },
  { label: 'Средний чек', value: money.format(avgCheck(period.value)), icon: 'i-lucide-receipt', color: 'text-orange-500' },
  { label: 'Покупатели', value: String(uniqueBuyers(period.value)), hint: 'уникальных', icon: 'i-lucide-users', color: 'text-teal-500' },
  { label: 'Средний рейтинг', value: avgRating.value > 0 ? `${avgRating.value.toFixed(1)} ★` : '—', icon: 'i-lucide-star', color: 'text-purple-500' },
  { label: 'Активные боксы', value: String(activeProductsCount.value), icon: 'i-lucide-package-check', color: 'text-amber-700' }
])

const lineData = computed(() => {
  const points = revenueByDay(period.value)
  return {
    labels: points.map(p => p.day.toLocaleDateString('ru-RU', { day: '2-digit', month: '2-digit' })),
    datasets: [{
      label: 'Выручка, ₽',
      data: points.map(p => p.revenue),
      borderColor: '#16a34a',
      backgroundColor: 'rgba(22, 163, 74, 0.12)',
      fill: true,
      tension: 0.3,
      pointRadius: 0
    }]
  }
})

const lineOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.05)' } },
    x: { grid: { display: false } }
  }
}

const palette = ['#16a34a', '#66bb6a', '#ffa726', '#42a5f5', '#ab47bc', '#ef5350', '#26a69a']

const pointRevenue = computed(() => revenueByPoint(period.value))
const doughnutData = computed(() => ({
  labels: pointRevenue.value.map(p => p.pointName),
  datasets: [{
    data: pointRevenue.value.map(p => p.revenue),
    backgroundColor: palette,
    borderWidth: 0
  }]
}))
const doughnutOptions = { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }

const recentOrders = computed(() =>
  [...completedOrders.value]
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
    .slice(0, 6)
)

const orderColumns = [
  { accessorKey: 'id', header: '№' },
  { accessorKey: 'point', header: 'Точка' },
  { accessorKey: 'date', header: 'Дата' },
  { accessorKey: 'total', header: 'Сумма' }
]

const orderRows = computed(() => recentOrders.value.map(o => ({
  id: `#${o.id}`,
  point: pointName(o.point_id),
  date: new Date(o.date).toLocaleString('ru-RU', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }),
  total: money.format(o.total_price)
})))
</script>

<template>
  <div class="p-4 sm:p-6 flex flex-col gap-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <p class="text-muted text-sm">
        Показатели вашего бизнеса
      </p>
      <UTabs
        v-model="period"
        :items="periodOptions"
        size="sm"
      />
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="soft"
      :title="error"
    >
      <template #actions>
        <UButton
          size="xs"
          variant="soft"
          @click="refresh"
        >
          Повторить
        </UButton>
      </template>
    </UAlert>

    <div
      v-if="loading"
      class="flex justify-center py-16"
    >
      <UIcon
        name="i-lucide-loader-2"
        class="animate-spin size-8 text-muted"
      />
    </div>

    <template v-else>
      <div class="grid grid-cols-2 lg:grid-cols-3 gap-4">
        <UCard
          v-for="kpi in kpis"
          :key="kpi.label"
        >
          <div class="flex items-start justify-between">
            <UIcon
              :name="kpi.icon"
              :class="[kpi.color, 'size-6']"
            />
          </div>
          <p class="text-2xl font-bold text-highlighted mt-3">
            {{ kpi.value }}
          </p>
          <p class="text-sm text-muted">
            {{ kpi.label }}
          </p>
          <p
            v-if="kpi.hint"
            class="text-xs text-dimmed"
          >
            {{ kpi.hint }}
          </p>
        </UCard>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <UCard class="lg:col-span-2">
          <template #header>
            <h3 class="font-semibold text-highlighted">
              Динамика выручки
            </h3>
          </template>
          <div class="h-64">
            <LineChart
              :data="lineData"
              :options="lineOptions"
            />
          </div>
        </UCard>

        <UCard>
          <template #header>
            <h3 class="font-semibold text-highlighted">
              По точкам
            </h3>
          </template>
          <div
            v-if="pointRevenue.length === 0"
            class="h-64 flex items-center justify-center text-muted text-sm"
          >
            Нет данных за период
          </div>
          <div
            v-else
            class="flex flex-col gap-4"
          >
            <div class="h-40">
              <DoughnutChart
                :data="doughnutData"
                :options="doughnutOptions"
              />
            </div>
            <div class="flex flex-col gap-1.5">
              <div
                v-for="(p, i) in pointRevenue"
                :key="p.pointId"
                class="flex items-center gap-2 text-sm"
              >
                <span
                  class="size-2.5 rounded-full shrink-0"
                  :style="{ backgroundColor: palette[i % palette.length] }"
                />
                <span class="truncate flex-1">{{ p.pointName }}</span>
                <span class="font-medium text-highlighted">{{ money.format(p.revenue) }}</span>
              </div>
            </div>
          </div>
        </UCard>
      </div>

      <UCard>
        <template #header>
          <h3 class="font-semibold text-highlighted">
            Последние заказы
          </h3>
        </template>
        <UTable
          :data="orderRows"
          :columns="orderColumns"
        />
        <p
          v-if="orderRows.length === 0"
          class="text-center text-muted text-sm py-8"
        >
          Выполненных заказов пока нет
        </p>
      </UCard>
    </template>
  </div>
</template>
