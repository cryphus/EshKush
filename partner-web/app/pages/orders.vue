<script setup lang="ts">
import type { Order, OrderStatus } from '~/types/api'

definePageMeta({ title: 'Заказы' })

const { request } = useApi()
const toast = useToast()
const { orders, loading, error, refresh, pointName, activeOrders, completedOrders, cancelledOrders } = usePartnerData()

onMounted(refresh)

const filter = ref<'all' | 'active' | 'completed' | 'cancelled'>('all')

const filterOptions = computed(() => [
  { label: `Все (${orders.value.length})`, value: 'all' as const },
  { label: `Новые (${activeOrders.value.length})`, value: 'active' as const },
  { label: `Выполнены (${completedOrders.value.length})`, value: 'completed' as const },
  { label: `Отменены (${cancelledOrders.value.length})`, value: 'cancelled' as const }
])

const filteredOrders = computed(() => {
  const base = (() => {
    switch (filter.value) {
      case 'active': return activeOrders.value
      case 'completed': return completedOrders.value
      case 'cancelled': return cancelledOrders.value
      default: return orders.value
    }
  })()
  return [...base].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
})

const money = new Intl.NumberFormat('ru-RU', { style: 'currency', currency: 'RUB', maximumFractionDigits: 0 })

const statusLabel: Record<OrderStatus, string> = {
  pending: 'Новый',
  processing: 'Готов к выдаче',
  completed: 'Выполнен',
  cancelled: 'Отменён'
}
const statusColor: Record<OrderStatus, 'info' | 'warning' | 'success' | 'error'> = {
  pending: 'info',
  processing: 'warning',
  completed: 'success',
  cancelled: 'error'
}

const busyId = ref<number | null>(null)

async function setStatus(order: Order, status: OrderStatus) {
  if (busyId.value !== null) return
  busyId.value = order.id
  try {
    if (status === 'cancelled') {
      await request(`/orders/${order.id}/refund`, { method: 'POST', body: {} })
    } else {
      await request(`/orders/${order.id}/status`, { method: 'PUT', body: { status } })
    }
    await refresh()
    toast.add({ title: `Заказ #${order.id}: ${statusLabel[status]}`, color: 'success' })
  } catch (e) {
    toast.add({ title: 'Не удалось обновить заказ', description: getErrorMessage(e), color: 'error' })
  } finally {
    busyId.value = null
  }
}

const columns = [
  { accessorKey: 'id', header: '№' },
  { accessorKey: 'point', header: 'Точка' },
  { accessorKey: 'date', header: 'Дата' },
  { accessorKey: 'items', header: 'Позиций' },
  { accessorKey: 'total', header: 'Сумма' },
  { accessorKey: 'status', header: 'Статус' },
  { accessorKey: 'actions', header: '' }
]
</script>

<template>
  <div class="p-4 sm:p-6 flex flex-col gap-6">
    <UTabs
      v-model="filter"
      :items="filterOptions"
      size="sm"
    />

    <UAlert
      v-if="error"
      color="error"
      variant="soft"
      :title="error"
    />

    <UCard :ui="{ body: 'p-0 sm:p-0' }">
      <UTable
        :data="filteredOrders"
        :columns="columns"
        :loading="loading"
      >
        <template #id-cell="{ row }">
          <span class="font-medium text-highlighted">#{{ row.original.id }}</span>
        </template>
        <template #point-cell="{ row }">
          {{ pointName(row.original.point_id) }}
        </template>
        <template #date-cell="{ row }">
          {{ new Date(row.original.date).toLocaleString('ru-RU', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }) }}
        </template>
        <template #items-cell="{ row }">
          {{ row.original.products_id.length }}
        </template>
        <template #total-cell="{ row }">
          <span class="font-semibold text-primary">{{ money.format(row.original.total_price) }}</span>
        </template>
        <template #status-cell="{ row }">
          <UBadge
            :color="statusColor[row.original.status]"
            variant="soft"
          >
            {{ statusLabel[row.original.status] }}
          </UBadge>
        </template>
        <template #actions-cell="{ row }">
          <div
            v-if="row.original.status === 'pending' || row.original.status === 'processing'"
            class="flex justify-end gap-1"
          >
            <UButton
              v-if="row.original.status === 'pending'"
              size="xs"
              color="warning"
              variant="soft"
              :loading="busyId === row.original.id"
              @click="setStatus(row.original, 'processing')"
            >
              Готов к выдаче
            </UButton>
            <UButton
              size="xs"
              color="success"
              variant="soft"
              :loading="busyId === row.original.id"
              @click="setStatus(row.original, 'completed')"
            >
              Выдан
            </UButton>
            <UButton
              size="xs"
              color="error"
              variant="soft"
              icon="i-lucide-x"
              :loading="busyId === row.original.id"
              @click="setStatus(row.original, 'cancelled')"
            />
          </div>
        </template>
      </UTable>
      <p
        v-if="!loading && filteredOrders.length === 0"
        class="text-center text-muted text-sm py-10"
      >
        Заказов нет
      </p>
    </UCard>
  </div>
</template>
